import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../providers/providers.dart';
import '../theme/theme.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'barcode_scanner_screen.dart';

/// Add Product Screen - Ürün Ekleme Ekranı
class AddProductScreen extends StatefulWidget {
  final Product? editProduct;

  const AddProductScreen({super.key, this.editProduct});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _quantityController = TextEditingController();
  final _minStockController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Genel';
  bool _isLoading = false;

  final List<String> _categories = ['Elektronik', 'Giyim', 'Gıda', 'Mobilya', 'Genel'];

  bool get isEditing => widget.editProduct != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      final p = widget.editProduct!;
      _nameController.text = p.name;
      _skuController.text = p.sku;
      _quantityController.text = p.quantity.toString();
      _minStockController.text = p.minStock.toString();
      _locationController.text = p.location;
      _descriptionController.text = p.description ?? '';
      _selectedCategory = p.category;
    } else {
      _quantityController.text = '0';
      _minStockController.text = '10';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _quantityController.dispose();
    _minStockController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Ürün Düzenle' : 'Yeni Ürün Ekle'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerColor),
              onPressed: _deleteProduct,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Quick Actions
            if (!isEditing) _buildQuickActions(),
            
            const SizedBox(height: 20),
            
            // Ürün Adı
            _buildSectionTitle('Temel Bilgiler'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameController,
              label: 'Ürün Adı',
              hint: 'Samsung Galaxy S24',
              icon: Icons.inventory_2_outlined,
              validator: (v) => v?.isEmpty ?? true ? 'Ürün adı gerekli' : null,
            ),
            const SizedBox(height: 16),
            
            // SKU
            _buildTextField(
              controller: _skuController,
              label: 'SKU / Barkod',
              hint: 'SGS24-001',
              icon: Icons.qr_code_rounded,
              validator: (v) => v?.isEmpty ?? true ? 'SKU gerekli' : null,
            ),
            const SizedBox(height: 16),
            
            // Kategori
            _buildDropdown(),
            const SizedBox(height: 16),
            
            // Konum
            _buildTextField(
              controller: _locationController,
              label: 'Depo Konumu',
              hint: 'Raf A1',
              icon: Icons.location_on_outlined,
            ),
            
            const SizedBox(height: 24),
            
            // Stok Bilgileri
            _buildSectionTitle('Stok Bilgileri'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _quantityController,
                    label: 'Miktar',
                    hint: '0',
                    icon: Icons.layers_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _minStockController,
                    label: 'Min. Stok',
                    hint: '10',
                    icon: Icons.warning_amber_outlined,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Açıklama
            _buildSectionTitle('Ek Bilgiler'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _descriptionController,
              label: 'Açıklama (Opsiyonel)',
              hint: 'Ürün hakkında notlar...',
              icon: Icons.notes_outlined,
              maxLines: 3,
            ),
            
            const SizedBox(height: 32),
            
            // Kaydet Butonu
            _buildSaveButton(),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hızlı Ekleme',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? AppTheme.darkTextPrimary 
                  : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Barkod Tara',
                  onTap: _scanBarcode,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.file_upload_outlined,
                  label: 'Excel Yükle',
                  onTap: _importExcel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Fotoğraf',
                  onTap: _capturePhoto,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Kategori',
        prefixIcon: Icon(Icons.category_outlined, color: AppTheme.textMuted),
      ),
      items: _categories.map((cat) {
        return DropdownMenuItem(value: cat, child: Text(cat));
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedCategory = value);
      },
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveProduct,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isEditing ? Icons.save_rounded : Icons.add_rounded),
                  const SizedBox(width: 8),
                  Text(isEditing ? 'Değişiklikleri Kaydet' : 'Ürün Ekle'),
                ],
              ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final product = Product(
      id: widget.editProduct?.id,
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      category: _selectedCategory,
      location: _locationController.text.trim().isEmpty 
          ? 'Ana Depo' 
          : _locationController.text.trim(),
      quantity: int.tryParse(_quantityController.text) ?? 0,
      minStock: int.tryParse(_minStockController.text) ?? 10,
      description: _descriptionController.text.trim().isEmpty 
          ? null 
          : _descriptionController.text.trim(),
      createdAt: widget.editProduct?.createdAt,
    );

    final provider = context.read<ProductProvider>();
    String? errorMessage;

    try {
      if (isEditing) {
        await provider.updateProduct(product);
      } else {
        await provider.addProduct(product);
      }
    } catch (e) {
      debugPrint('Error in _saveProduct: $e');
      final errorStr = e.toString();
      
      if (errorStr.contains('Store not found')) {
        errorMessage = 'Hata: Bir mağazaya/dükkana bağlı değilsiniz. Lütfen ayarlardan çıkış yapıp tekrar giriş yapın veya yeni bir mağaza oluşturun.';
      } else if (errorStr.contains('permission-denied')) {
        errorMessage = 'Yetki Hatası: Bu işlemi yapmaya yetkiniz yok. Ürün ekleme yetkiniz olmayabilir.';
      } else if (errorStr.contains('unavailable')) {
        errorMessage = 'Bağlantı Hatası: İnternet bağlantınızı kontrol edin.';
      } else {
        errorMessage = 'İşlem başarısız: Firestore izinlerini veya bağlantınızı kontrol edin. Detay: $e';
      }
    }

    setState(() => _isLoading = false);

    if (errorMessage == null && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? 'Ürün güncellendi' : 'Ürün eklendi'),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _deleteProduct() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: const Text('Bu ürün kalıcı olarak silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ProductProvider>().deleteProduct(widget.editProduct!.id!);
      if (mounted) Navigator.pop(context);
    }
  }

  /// Barkod Tarama
  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (barcode != null && mounted) {
      setState(() {
        _skuController.text = barcode;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barkod okundu: $barcode'),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Excel'den İçe Aktarma
  Future<void> _importExcel() async {
    // Önce bilgi dialog'u göster
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Excel İçe Aktar'),
          ],
        ),
        content: Text(ExcelImportService.templateInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Dosya Seç'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    final products = await ExcelImportService.pickAndParseExcel();

    setState(() => _isLoading = false);

    if (products == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dosya seçilmedi veya okunamadı'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (products.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Excel dosyasında ürün bulunamadı'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Ürünleri ekle
    if (mounted) {
      final provider = context.read<ProductProvider>();
      int addedCount = 0;

      for (final product in products) {
        final result = await provider.addProduct(product);
        if (result != null) addedCount++;
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$addedCount ürün başarıyla eklendi!'),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Fotoğraftan OCR
  Future<void> _capturePhoto() async {
    // Kaynak seçimi
    final source = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Fotoğraf Kaynağı',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: AppTheme.primaryColor),
              ),
              title: const Text('Kamera'),
              subtitle: const Text('Fotoğraf çek'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: AppTheme.secondaryColor),
              ),
              title: const Text('Galeri'),
              subtitle: const Text('Mevcut fotoğraftan seç'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() => _isLoading = true);

    OcrResult? result;
    if (source == 'camera') {
      result = await OcrService.captureAndRecognize();
    } else {
      result = await OcrService.pickAndRecognize();
    }

    setState(() => _isLoading = false);

    if (result == null || !result.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result?.message ?? 'OCR işlemi başarısız'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Sonuçları form alanlarına doldur
    if (mounted) {
      setState(() {
        if (result!.productName != null) {
          _nameController.text = result.productName!;
        }
        if (result.sku != null) {
          _skuController.text = result.sku!;
        }
      });

      // OCR sonuçlarını göster
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.secondaryColor),
              SizedBox(width: 12),
              Text('OCR Sonucu'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (result!.productName != null) ...[
                const Text('Ürün Adı:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(result.productName!),
                const SizedBox(height: 12),
              ],
              if (result.sku != null) ...[
                const Text('SKU/Barkod:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(result.sku!),
                const SizedBox(height: 12),
              ],
              const Divider(),
              const Text('Ham Metin:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Text(
                    result.rawText,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tamam'),
            ),
          ],
        ),
      );
    }
  }
}

/// Hızlı Aksiyon Butonu
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
