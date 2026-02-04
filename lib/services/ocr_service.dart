import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR Service - Fotoğraftan Metin Okuma
class OcrService {
  static final TextRecognizer _textRecognizer = TextRecognizer();
  static final ImagePicker _imagePicker = ImagePicker();

  /// Kamera ile fotoğraf çek ve metin oku
  static Future<OcrResult?> captureAndRecognize() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _processImage(image.path);
    } catch (e) {
      debugPrint('OCR capture error: $e');
      return null;
    }
  }

  /// Galeriden fotoğraf seç ve metin oku
  static Future<OcrResult?> pickAndRecognize() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) return null;

      return await _processImage(image.path);
    } catch (e) {
      debugPrint('OCR pick error: $e');
      return null;
    }
  }

  /// Görüntüyü işle ve metin çıkar
  static Future<OcrResult?> _processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return OcrResult(
          rawText: '',
          productName: null,
          sku: null,
          success: false,
          message: 'Metin bulunamadı',
        );
      }

      // Metni parse et ve ürün bilgilerini çıkarmaya çalış
      return _parseRecognizedText(recognizedText.text);
    } catch (e) {
      debugPrint('OCR process error: $e');
      return null;
    }
  }

  /// Tanınan metinden ürün bilgilerini çıkar
  static OcrResult _parseRecognizedText(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    String? productName;
    String? sku;

    // Barkod/SKU için regex pattern'leri
    final skuPatterns = [
      RegExp(r'\b[A-Z]{2,4}[-]?\d{3,}[-]?\d*\b', caseSensitive: false), // ABC-123 format
      RegExp(r'\b\d{8,14}\b'), // EAN/UPC barkod
      RegExp(r'\bSKU[:\s]*([A-Z0-9-]+)\b', caseSensitive: false),
    ];

    for (final line in lines) {
      // SKU/Barkod ara
      for (final pattern in skuPatterns) {
        final match = pattern.firstMatch(line);
        if (match != null && sku == null) {
          sku = match.group(0)?.replaceAll(RegExp(r'^SKU[:\s]*', caseSensitive: false), '').trim();
          break;
        }
      }

      // Ürün adı için: uzun metin, sayı içermeyen veya az sayı içeren
      if (productName == null && 
          line.length > 3 && 
          line.length < 100 &&
          !RegExp(r'^\d+$').hasMatch(line)) {
        // Fiyat veya ölçü değilse
        if (!RegExp(r'[\$€₺]\s*\d|^\d+[.,]\d{2}$|\d+\s*(ml|mg|kg|gr|cm|mm)\b', caseSensitive: false).hasMatch(line)) {
          productName = line.trim();
        }
      }
    }

    return OcrResult(
      rawText: text,
      productName: productName,
      sku: sku,
      success: true,
      message: 'Metin başarıyla okundu',
    );
  }

  /// Servisi temizle
  static void dispose() {
    _textRecognizer.close();
  }
}

/// OCR Sonucu
class OcrResult {
  final String rawText;
  final String? productName;
  final String? sku;
  final bool success;
  final String message;

  OcrResult({
    required this.rawText,
    this.productName,
    this.sku,
    required this.success,
    required this.message,
  });
}
