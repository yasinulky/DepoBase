import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';

/// Excel Import Service - Excel'den Ürün İçe Aktarma
class ExcelImportService {
  /// Excel dosyası seç ve ürünleri parse et
  static Future<List<Product>?> pickAndParseExcel() async {
    try {
      // Dosya seç
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return null;
      }

      final file = result.files.first;
      if (file.path == null) return null;

      // Excel dosyasını oku
      final bytes = File(file.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      return _parseExcelToProducts(excel);
    } catch (e) {
      debugPrint('Excel import error: $e');
      return null;
    }
  }

  /// Excel verilerini Product listesine çevir
  static List<Product> _parseExcelToProducts(Excel excel) {
    final products = <Product>[];
    
    // İlk sheet'i al
    final sheet = excel.tables.keys.first;
    final table = excel.tables[sheet];
    
    if (table == null || table.rows.isEmpty) return products;

    // Header satırını atla, 1. satırdan başla
    for (var i = 1; i < table.rows.length; i++) {
      final row = table.rows[i];
      
      // Minimum 2 sütun gerekli: Ad ve SKU
      if (row.length >= 2 && row[0]?.value != null && row[1]?.value != null) {
        final product = Product(
          name: _getCellValue(row, 0),
          sku: _getCellValue(row, 1),
          category: row.length > 2 ? _getCellValue(row, 2, 'Genel') : 'Genel',
          location: row.length > 3 ? _getCellValue(row, 3, 'Ana Depo') : 'Ana Depo',
          quantity: row.length > 4 ? _getCellInt(row, 4) : 0,
          minStock: row.length > 5 ? _getCellInt(row, 5, 10) : 10,
          description: row.length > 6 ? _getCellValue(row, 6) : null,
        );
        products.add(product);
      }
    }

    return products;
  }

  static String _getCellValue(List<Data?> row, int index, [String defaultValue = '']) {
    final cell = row[index];
    if (cell == null || cell.value == null) return defaultValue;
    return cell.value.toString().trim();
  }

  static int _getCellInt(List<Data?> row, int index, [int defaultValue = 0]) {
    final value = _getCellValue(row, index);
    return int.tryParse(value) ?? defaultValue;
  }

  /// Örnek Excel şablonu bilgisi
  static String get templateInfo => '''
Excel dosyanız şu sütunları içermeli:
─────────────────────────────────
A: Ürün Adı (zorunlu)
B: SKU/Barkod (zorunlu)
C: Kategori (opsiyonel)
D: Konum (opsiyonel)
E: Miktar (opsiyonel)
F: Min. Stok (opsiyonel)
G: Açıklama (opsiyonel)
─────────────────────────────────
İlk satır başlık olarak kabul edilir.
''';
}
