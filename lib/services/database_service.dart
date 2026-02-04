import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

/// Database Service - Veritabanı Servisi
class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('warehouse.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  /// Veritabanı dosya yolunu al
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'warehouse.db');
  }

  Future<void> _createDB(Database db, int version) async {
    // Products tablosu
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        sku TEXT NOT NULL UNIQUE,
        category TEXT DEFAULT 'Genel',
        location TEXT DEFAULT 'Ana Depo',
        quantity INTEGER DEFAULT 0,
        min_stock INTEGER DEFAULT 10,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Stock movements tablosu
    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE CASCADE
      )
    ''');

    // Demo veriler ekle
    await _insertDemoData(db);
  }

  Future<void> _insertDemoData(Database db) async {
    final now = DateTime.now().toIso8601String();
    
    await db.insert('products', {
      'name': 'Samsung Galaxy S24',
      'sku': 'SGS24-001',
      'category': 'Elektronik',
      'location': 'Raf A1',
      'quantity': 25,
      'min_stock': 10,
      'description': 'Samsung Galaxy S24 Akıllı Telefon',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'name': 'Apple MacBook Pro 14"',
      'sku': 'MBP14-002',
      'category': 'Elektronik',
      'location': 'Raf B2',
      'quantity': 8,
      'min_stock': 5,
      'description': 'Apple MacBook Pro 14 inç M3 Pro',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'name': 'Nike Air Max 270',
      'sku': 'NAM270-003',
      'category': 'Giyim',
      'location': 'Raf C3',
      'quantity': 3,
      'min_stock': 15,
      'description': 'Nike Air Max 270 Spor Ayakkabı',
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('products', {
      'name': 'Sony WH-1000XM5',
      'sku': 'SWH5-004',
      'category': 'Elektronik',
      'location': 'Raf A2',
      'quantity': 12,
      'min_stock': 8,
      'description': 'Sony Kablosuz Kulaklık',
      'created_at': now,
      'updated_at': now,
    });
  }

  // ==================== PRODUCT OPERATIONS ====================

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final result = await db.query('products', orderBy: 'updated_at DESC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getLowStockProducts() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT * FROM products WHERE quantity <= min_stock ORDER BY quantity ASC'
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'name LIKE ? OR sku LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final result = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isEmpty) return null;
    return Product.fromMap(result.first);
  }

  Future<Product> insertProduct(Product product) async {
    final db = await database;
    final id = await db.insert('products', product.toMap()..remove('id'));
    return product.copyWith(id: id);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== STOCK MOVEMENT OPERATIONS ====================

  Future<StockMovement> insertMovement(StockMovement movement) async {
    final db = await database;
    final id = await db.insert('stock_movements', movement.toMap()..remove('id'));
    
    // Stok miktarını güncelle
    final product = await getProductById(movement.productId);
    if (product != null) {
      final newQuantity = movement.type == MovementType.stockIn
          ? product.quantity + movement.quantity
          : product.quantity - movement.quantity;
      
      await updateProduct(product.copyWith(quantity: newQuantity));
    }
    
    return StockMovement(
      id: id,
      productId: movement.productId,
      type: movement.type,
      quantity: movement.quantity,
      note: movement.note,
      createdAt: movement.createdAt,
    );
  }

  Future<List<StockMovement>> getMovementsByProductId(int productId) async {
    final db = await database;
    final result = await db.query(
      'stock_movements',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => StockMovement.fromMap(map)).toList();
  }

  Future<List<StockMovement>> getRecentMovements({int limit = 10}) async {
    final db = await database;
    final result = await db.query(
      'stock_movements',
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return result.map((map) => StockMovement.fromMap(map)).toList();
  }

  // ==================== STATISTICS ====================

  Future<Map<String, dynamic>> getStatistics() async {
    final db = await database;
    
    final totalProducts = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products')
    ) ?? 0;
    
    final totalStock = Sqflite.firstIntValue(
      await db.rawQuery('SELECT SUM(quantity) FROM products')
    ) ?? 0;
    
    final lowStockCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM products WHERE quantity <= min_stock')
    ) ?? 0;
    
    final categories = await db.rawQuery(
      'SELECT DISTINCT category FROM products'
    );

    return {
      'totalProducts': totalProducts,
      'totalStock': totalStock,
      'lowStockCount': lowStockCount,
      'categoryCount': categories.length,
    };
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  /// Tüm verileri sil
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('stock_movements');
    await db.delete('products');
  }
}
