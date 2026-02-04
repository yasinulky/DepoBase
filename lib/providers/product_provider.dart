import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// Product Provider - Ürün State Yönetimi (Firebase + SQLite Hybrid)
class ProductProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  List<Product> _products = [];
  List<Product> _lowStockProducts = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = false;
  String _searchQuery = '';
  bool _useFirebase = false;
  
  StreamSubscription? _productsSubscription;

  // Getters
  List<Product> get products => _products;
  List<Product> get lowStockProducts => _lowStockProducts;
  Map<String, dynamic> get statistics => _statistics;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  bool get useFirebase => _useFirebase;

  /// Firebase modunda başlat
  void initializeWithFirebase() {
    if (_useFirebase) return;
    
    _useFirebase = true;
    _isLoading = true;
    notifyListeners();
    
    // Firebase stream'ini dinle
    _productsSubscription = FirebaseService.getProductsStream().listen(
      (products) {
        _products = products;
        _lowStockProducts = products.where((p) => p.isLowStock).toList();
        _updateStatistics();
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Firebase stream error: $error');
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  /// SQLite modunda başlat (offline)
  Future<void> loadInitialData() async {
    if (_useFirebase) {
      await _loadFromFirebase();
      return;
    }
    
    _isLoading = true;
    notifyListeners();

    try {
      _products = await _db.getAllProducts();
      _lowStockProducts = await _db.getLowStockProducts();
      _statistics = await _db.getStatistics();
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Firebase'den yükle
  Future<void> _loadFromFirebase() async {
    _isLoading = true;
    notifyListeners();

    try {
      _products = await FirebaseService.getAllProducts();
      _lowStockProducts = _products.where((p) => p.isLowStock).toList();
      _statistics = await FirebaseService.getStatistics();
    } catch (e) {
      debugPrint('Error loading from Firebase: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// İstatistikleri güncelle
  void _updateStatistics() {
    final totalProducts = _products.length;
    final totalStock = _products.fold<int>(0, (sum, p) => sum + p.quantity);
    final lowStockCount = _lowStockProducts.length;
    final categories = _products.map((p) => p.category).toSet().length;

    _statistics = {
      'totalProducts': totalProducts,
      'totalStock': totalStock,
      'lowStockCount': lowStockCount,
      'categoryCount': categories,
    };
  }

  /// Ürün ara
  Future<void> searchProducts(String query) async {
    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      if (_useFirebase) {
        final allProducts = await FirebaseService.getAllProducts();
        if (query.isEmpty) {
          _products = allProducts;
        } else {
          _products = allProducts.where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.sku.toLowerCase().contains(query.toLowerCase()) ||
              p.category.toLowerCase().contains(query.toLowerCase())
          ).toList();
        }
      } else {
        if (query.isEmpty) {
          _products = await _db.getAllProducts();
        } else {
          _products = await _db.searchProducts(query);
        }
      }
    } catch (e) {
      debugPrint('Error searching: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Yeni ürün ekle
  Future<Product?> addProduct(Product product) async {
    if (_useFirebase) {
      // Firebase exceptions will propagate to the UI
      final id = await FirebaseService.addProduct(product);
      if (id != null) {
        return product.copyWith(id: id);
      }
      return null;
    } else {
      try {
        final newProduct = await _db.insertProduct(product);
        await loadInitialData();
        return newProduct;
      } catch (e) {
        debugPrint('Error adding product: $e');
        return null;
      }
    }
  }

  /// Ürün güncelle
  Future<bool> updateProduct(Product product) async {
    if (_useFirebase) {
      // Firebase exceptions will propagate to the UI
      return await FirebaseService.updateProduct(product);
    } else {
      try {
        await _db.updateProduct(product);
        await loadInitialData();
        return true;
      } catch (e) {
        debugPrint('Error updating product: $e');
        return false;
      }
    }
  }

  /// Ürün sil
  Future<bool> deleteProduct(dynamic id) async {
    try {
      if (_useFirebase) {
        return await FirebaseService.deleteProduct(id.toString());
      } else {
        await _db.deleteProduct(id as int);
        await loadInitialData();
        return true;
      }
    } catch (e) {
      debugPrint('Error deleting product: $e');
      return false;
    }
  }

  /// Stok hareketi ekle
  Future<bool> addStockMovement(StockMovement movement) async {
    try {
      if (_useFirebase) {
        final result = await FirebaseService.addStockMovement(movement);
        return result != null;
      } else {
        await _db.insertMovement(movement);
        await loadInitialData();
        return true;
      }
    } catch (e) {
      debugPrint('Error adding movement: $e');
      return false;
    }
  }

  /// Ürüne ait hareketleri getir
  Future<List<StockMovement>> getProductMovements(dynamic productId) async {
    try {
      if (_useFirebase) {
        return await FirebaseService.getProductMovements(productId.toString());
      } else {
        return await _db.getMovementsByProductId(productId as int);
      }
    } catch (e) {
      debugPrint('Error getting movements: $e');
      return [];
    }
  }

  /// Tüm verileri sil
  Future<bool> clearAllData() async {
    try {
      if (_useFirebase) {
        return await FirebaseService.clearAllData();
      } else {
        await _db.clearAllData();
        await loadInitialData();
        return true;
      }
    } catch (e) {
      debugPrint('Error clearing data: $e');
      return false;
    }
  }

  /// Toplu ürün ekleme
  Future<int> addProductsBatch(List<Product> products) async {
    if (_useFirebase) {
      return await FirebaseService.addProductsBatch(products);
    } else {
      int count = 0;
      for (final product in products) {
        final result = await addProduct(product);
        if (result != null) count++;
      }
      return count;
    }
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }
}
