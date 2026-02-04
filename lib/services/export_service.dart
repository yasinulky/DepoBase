import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import 'database_service.dart';

/// Export Service - Dışa Aktarma Servisi
class ExportService {
  /// Ürünleri Excel dosyasına dışa aktar
  static Future<String?> exportProductsToExcel(List<Product> products) async {
    try {
      final excel = Excel.createExcel();
      final sheet = excel['Ürünler'];

      // Başlık satırı
      sheet.appendRow([
        TextCellValue('Ürün Adı'),
        TextCellValue('SKU/Barkod'),
        TextCellValue('Kategori'),
        TextCellValue('Konum'),
        TextCellValue('Miktar'),
        TextCellValue('Min. Stok'),
        TextCellValue('Açıklama'),
        TextCellValue('Eklenme Tarihi'),
      ]);

      // Ürün verileri
      for (final product in products) {
        sheet.appendRow([
          TextCellValue(product.name),
          TextCellValue(product.sku),
          TextCellValue(product.category),
          TextCellValue(product.location),
          IntCellValue(product.quantity),
          IntCellValue(product.minStock),
          TextCellValue(product.description ?? ''),
          TextCellValue(product.createdAt.toString().substring(0, 10)),
        ]);
      }

      // Varsayılan sheet'i kaldır
      excel.delete('Sheet1');

      // Dosyayı kaydet
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/depo_urunler_$timestamp.xlsx';
      
      final fileBytes = excel.save();
      if (fileBytes == null) return null;

      final file = File(filePath);
      await file.writeAsBytes(fileBytes);

      return filePath;
    } catch (e) {
      debugPrint('Export error: $e');
      return null;
    }
  }

  /// Dışa aktarılan dosyayı paylaş
  static Future<void> shareExportedFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Depo Ürün Listesi');
  }

  /// Veritabanı yedeği oluştur
  static Future<String?> backupDatabase() async {
    try {
      final dbPath = await DatabaseService.instance.getDatabasePath();
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${directory.path}/depo_yedek_$timestamp.db';

      await dbFile.copy(backupPath);

      return backupPath;
    } catch (e) {
      debugPrint('Backup error: $e');
      return null;
    }
  }

  /// Yedekten geri yükle
  static Future<bool> restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) return false;

      final dbPath = await DatabaseService.instance.getDatabasePath();
      await backupFile.copy(dbPath);

      return true;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }
}
