import 'package:cloud_firestore/cloud_firestore.dart';

/// Stock Movement Model - Stok Hareket Modeli
enum MovementType { stockIn, stockOut }

class StockMovement {
  final dynamic id; // SQLite için int, Firestore için String
  final dynamic productId; // SQLite için int, Firestore için String
  final MovementType type;
  final int quantity;
  final String? note;
  final DateTime createdAt;

  StockMovement({
    this.id,
    required this.productId,
    required this.type,
    required this.quantity,
    this.note,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Türkçe hareket tipi
  String get typeText => type == MovementType.stockIn ? 'Giriş' : 'Çıkış';

  /// JSON'dan StockMovement oluştur (SQLite ve Firestore uyumlu)
  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      productId: map['product_id'] ?? map['productId'],
      type: (map['type'] == 'in' || map['type'] == 'stockIn') 
          ? MovementType.stockIn 
          : MovementType.stockOut,
      quantity: map['quantity'] as int,
      note: map['note'] as String?,
      createdAt: _parseDateTime(map['created_at'] ?? map['createdAt']),
    );
  }

  /// DateTime parse helper
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// StockMovement'ı Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'productId': productId.toString(), // Firestore için
      'type': type == MovementType.stockIn ? 'stockIn' : 'stockOut',
      'quantity': quantity,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(), // Firestore için
    };
  }
}
