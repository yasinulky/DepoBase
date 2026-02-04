import 'package:cloud_firestore/cloud_firestore.dart';

/// Product Model - Ürün Modeli
class Product {
  final dynamic id; // SQLite için int, Firestore için String
  final String name;
  final String sku;
  final String category;
  final String location;
  final int quantity;
  final int minStock;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    this.id,
    required this.name,
    required this.sku,
    this.category = 'Genel',
    this.location = 'Ana Depo',
    this.quantity = 0,
    this.minStock = 10,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Düşük stok kontrolü
  bool get isLowStock => quantity <= minStock;

  /// JSON'dan Product oluştur (SQLite ve Firestore uyumlu)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'], // dynamic - int veya String olabilir
      name: map['name'] as String,
      sku: map['sku'] as String,
      category: map['category'] as String? ?? 'Genel',
      location: map['location'] as String? ?? 'Ana Depo',
      quantity: map['quantity'] as int? ?? 0,
      minStock: (map['min_stock'] ?? map['minStock']) as int? ?? 10,
      description: map['description'] as String?,
      createdAt: _parseDateTime(map['created_at'] ?? map['createdAt']),
      updatedAt: _parseDateTime(map['updated_at'] ?? map['updatedAt']),
    );
  }

  /// DateTime parse helper (String veya Timestamp olabilir)
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Product'ı Map'e çevir
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'category': category,
      'location': location,
      'quantity': quantity,
      'min_stock': minStock,
      'minStock': minStock, // Firestore için
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(), // Firestore için
      'updated_at': updatedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(), // Firestore için
    };
  }

  /// Kopyalama ile güncelleme
  Product copyWith({
    dynamic id,
    String? name,
    String? sku,
    String? category,
    String? location,
    int? quantity,
    int? minStock,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      location: location ?? this.location,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
