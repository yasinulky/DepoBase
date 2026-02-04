import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'auth_service.dart';
import 'store_service.dart';

/// Firebase Service - Firestore CRUD işlemleri
class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dükkan bazlı collection references
  static Future<CollectionReference<Map<String, dynamic>>> _getProductsRef() async {
    final storeId = await StoreService.getCurrentStoreId();
    if (storeId == null) throw Exception('Store not found');
    return _firestore.collection('stores').doc(storeId).collection('products');
  }

  static Future<CollectionReference<Map<String, dynamic>>> _getMovementsRef() async {
    final storeId = await StoreService.getCurrentStoreId();
    if (storeId == null) throw Exception('Store not found');
    return _firestore.collection('stores').doc(storeId).collection('stockMovements');
  }

  // ==================== PRODUCTS ====================

  /// Tüm ürünleri gerçek zamanlı stream olarak al
  static Stream<List<Product>> getProductsStream() {
    debugPrint('FirebaseService.getProductsStream() called');
    
    // StoreId'yi önce alıp stream döndür
    return Stream.fromFuture(_getProductsRef()).asyncExpand((ref) {
      return ref.snapshots().map((snapshot) {
        debugPrint('Products snapshot received: ${snapshot.docs.length} docs');
        final products = snapshot.docs.map((doc) {
          return Product.fromMap({...doc.data(), 'id': doc.id});
        }).toList();
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return products;
      });
    });
  }

  /// Tüm ürünleri bir kez al
  static Future<List<Product>> getAllProducts() async {
    try {
      debugPrint('FirebaseService.getAllProducts() called');
      final productsRef = await _getProductsRef();
      final snapshot = await productsRef.get();
      debugPrint('Got ${snapshot.docs.length} products from Firestore');
      
      final products = snapshot.docs.map((doc) {
        return Product.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
      products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return products;
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  /// Ürün ekle
  static Future<String?> addProduct(Product product) async {
    debugPrint('FirebaseService.addProduct called for: ${product.name}');
    
    final productsRef = await _getProductsRef();
    
    final data = product.toMap();
    data['createdBy'] = AuthService.currentUser?.uid;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    
    data.remove('id');
    data.remove('created_at');
    data.remove('updated_at');
    
    debugPrint('Data to save: $data');
    
    final docRef = await productsRef.add(data);
    debugPrint('Product saved with id: ${docRef.id}');
    return docRef.id;
  }

  /// Ürün güncelle
  static Future<bool> updateProduct(Product product) async {
    if (product.id == null) return false;
    
    final productsRef = await _getProductsRef();
    
    final data = product.toMap();
    data['updatedAt'] = FieldValue.serverTimestamp();
    data.remove('id');
    
    await productsRef.doc(product.id).update(data);
    return true;
  }

  /// Ürün sil
  static Future<bool> deleteProduct(String productId) async {
    try {
      final productsRef = await _getProductsRef();
      final movementsRef = await _getMovementsRef();
      
      await productsRef.doc(productId).delete();
      
      final movements = await movementsRef
          .where('productId', isEqualTo: productId)
          .get();
      
      for (final doc in movements.docs) {
        await doc.reference.delete();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  /// Düşük stoklu ürünleri al
  static Future<List<Product>> getLowStockProducts() async {
    try {
      final products = await getAllProducts();
      return products.where((p) => p.isLowStock).toList();
    } catch (e) {
      debugPrint('Error getting low stock products: $e');
      return [];
    }
  }

  /// Stok miktarını güncelle
  static Future<bool> updateStock(String productId, int newQuantity) async {
    try {
      final productsRef = await _getProductsRef();
      
      await productsRef.doc(productId).update({
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Error updating stock: $e');
      return false;
    }
  }

  // ==================== STOCK MOVEMENTS ====================

  /// Stok hareketi ekle
  static Future<String?> addStockMovement(StockMovement movement) async {
    try {
      debugPrint('FirebaseService.addStockMovement called');
      debugPrint('ProductId: ${movement.productId}, Type: ${movement.type}, Qty: ${movement.quantity}');
      
      final productsRef = await _getProductsRef();
      final movementsRef = await _getMovementsRef();
      
      final productIdStr = movement.productId.toString();
      
      final data = movement.toMap();
      data['createdBy'] = AuthService.currentUser?.uid;
      data['createdAt'] = FieldValue.serverTimestamp();
      data['productId'] = productIdStr;
      data.remove('id');
      data.remove('created_at');
      
      final docRef = await movementsRef.add(data);
      debugPrint('Stock movement saved with id: ${docRef.id}');
      
      final productDoc = await productsRef.doc(productIdStr).get();
      debugPrint('Product exists: ${productDoc.exists}');
      
      if (productDoc.exists) {
        final currentQty = productDoc.data()?['quantity'] ?? 0;
        final newQty = movement.type == MovementType.stockIn
            ? currentQty + movement.quantity
            : currentQty - movement.quantity;
        
        debugPrint('Updating stock: $currentQty -> $newQty');
        await updateStock(productIdStr, newQty.clamp(0, 999999));
      }
      
      return docRef.id;
    } catch (e, stackTrace) {
      debugPrint('Error adding stock movement: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Ürüne ait stok hareketlerini al
  static Future<List<StockMovement>> getProductMovements(String productId) async {
    try {
      debugPrint('getProductMovements called for productId: $productId');
      final movementsRef = await _getMovementsRef();
      
      final snapshot = await movementsRef
          .where('productId', isEqualTo: productId)
          .get();
      
      debugPrint('Got ${snapshot.docs.length} movements');
      
      final movements = snapshot.docs.map((doc) {
        return StockMovement.fromMap({...doc.data(), 'id': doc.id});
      }).toList();
      
      movements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return movements;
    } catch (e) {
      debugPrint('Error getting movements: $e');
      return [];
    }
  }

  // ==================== STATISTICS ====================

  /// İstatistikleri hesapla
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      final products = await getAllProducts();
      
      final totalProducts = products.length;
      final totalStock = products.fold<int>(0, (total, p) => total + p.quantity);
      final lowStockCount = products.where((p) => p.isLowStock).length;
      final categories = products.map((p) => p.category).toSet().length;

      return {
        'totalProducts': totalProducts,
        'totalStock': totalStock,
        'lowStockCount': lowStockCount,
        'categoryCount': categories,
      };
    } catch (e) {
      debugPrint('Error getting statistics: $e');
      return {
        'totalProducts': 0,
        'totalStock': 0,
        'lowStockCount': 0,
        'categoryCount': 0,
      };
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Toplu ürün ekleme (Excel import için)
  static Future<int> addProductsBatch(List<Product> products) async {
    int successCount = 0;
    
    for (final product in products) {
      final result = await addProduct(product);
      if (result != null) successCount++;
    }
    
    return successCount;
  }

  /// Tüm verileri sil
  static Future<bool> clearAllData() async {
    try {
      final productsRef = await _getProductsRef();
      final movementsRef = await _getMovementsRef();
      
      final products = await productsRef.get();
      for (final doc in products.docs) {
        await doc.reference.delete();
      }
      
      final movements = await movementsRef.get();
      for (final doc in movements.docs) {
        await doc.reference.delete();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error clearing data: $e');
      return false;
    }
  }
}
