import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import 'login_screen.dart';


/// Settings Screen - Ayarlar Ekranı
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _lowStockNotifications = true;
  int _defaultMinStock = 10;
  bool _isExporting = false;
  bool _isBackingUp = false;
  
  // Dükkan bilgileri
  Map<String, dynamic>? _storeInfo;

  @override
  void initState() {
    super.initState();
    _loadStoreInfo();
  }

  Future<void> _loadStoreInfo() async {
    final storeInfo = await StoreService.getStoreInfo();
    if (mounted) {
      setState(() {
        _storeInfo = storeInfo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppTheme.darkCard : Colors.white;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final mutedColor = isDark ? AppTheme.darkTextSecondary : AppTheme.textMuted;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profil / Uygulama Bilgisi
          _buildProfileSection(),
          const SizedBox(height: 24),
          
          // Bildirim Ayarları
          _buildSectionTitle('Bildirimler', mutedColor),
          _buildSettingsCard(cardColor, borderColor, [
            _buildSwitchTile(
              icon: Icons.notifications_active_outlined,
              title: 'Düşük Stok Uyarıları',
              subtitle: 'Stok minimum seviyeye düştüğünde bildir',
              value: _lowStockNotifications,
              onChanged: (value) => setState(() => _lowStockNotifications = value),
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ]),
          const SizedBox(height: 24),
          
          // Genel Ayarlar
          _buildSectionTitle('Genel Ayarlar', mutedColor),
          _buildSettingsCard(cardColor, borderColor, [
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, _) {
                return _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Karanlık Mod',
                  subtitle: 'Koyu tema kullan',
                  value: themeProvider.isDarkMode,
                  onChanged: (value) => themeProvider.setDarkMode(value),
                  textColor: textColor,
                  mutedColor: mutedColor,
                );
              },
            ),
            Divider(height: 1, color: borderColor),
            _buildSliderTile(
              icon: Icons.inventory_outlined,
              title: 'Varsayılan Min. Stok',
              subtitle: 'Yeni ürünler için: $_defaultMinStock',
              value: _defaultMinStock.toDouble(),
              min: 1,
              max: 100,
              onChanged: (value) => setState(() => _defaultMinStock = value.round()),
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ]),
          const SizedBox(height: 24),
          
          // Veri Yönetimi
          _buildSectionTitle('Veri Yönetimi', mutedColor),
          _buildSettingsCard(cardColor, borderColor, [
            _buildActionTile(
              icon: Icons.file_download_outlined,
              title: 'Verileri Dışa Aktar',
              subtitle: 'Tüm ürünleri Excel olarak indir',
              onTap: _exportData,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            Divider(height: 1, color: borderColor),
            _buildActionTile(
              icon: Icons.file_upload_outlined,
              title: 'Excel İçe Aktar',
              subtitle: 'Excel dosyasından ürün ekle',
              onTap: _importData,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            Divider(height: 1, color: borderColor),
            _buildActionTile(
              icon: Icons.backup_outlined,
              title: 'Veritabanı Yedeği',
              subtitle: 'Son yedekleme: Bugün',
              onTap: _backupDatabase,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            Divider(height: 1, color: borderColor),
            _buildActionTile(
              icon: Icons.delete_sweep_outlined,
              title: 'Tüm Verileri Sil',
              subtitle: 'Dikkat: Bu işlem geri alınamaz!',
              onTap: _clearAllData,
              isDestructive: true,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ]),
          const SizedBox(height: 24),
          
          // Hakkında
          _buildSectionTitle('Hakkında', mutedColor),
          _buildSettingsCard(cardColor, borderColor, [
            _buildInfoTile(
              icon: Icons.info_outline,
              title: 'Uygulama Versiyonu',
              value: '1.0.0',
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            Divider(height: 1, color: borderColor),
            _buildActionTile(
              icon: Icons.help_outline,
              title: 'Yardım & Destek',
              subtitle: 'SSS ve iletişim',
              onTap: _showHelp,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
            Divider(height: 1, color: borderColor),
            _buildActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Gizlilik Politikası',
              subtitle: null,
              onTap: _showPrivacy,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ]),
          const SizedBox(height: 24),
          
          // Çıkış Yap
          _buildSectionTitle('Hesap', mutedColor),
          _buildSettingsCard(cardColor, borderColor, [
            _buildActionTile(
              icon: Icons.logout_rounded,
              title: 'Çıkış Yap',
              subtitle: AuthService.currentUser?.email ?? '',
              onTap: _logout,
              isDestructive: true,
              textColor: textColor,
              mutedColor: mutedColor,
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final storeName = _storeInfo?['name'] ?? 'DepoBase';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.warehouse_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  storeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Consumer<ProductProvider>(
                  builder: (context, provider, _) {
                    return Text(
                      '${provider.statistics['totalProducts'] ?? 0} ürün kayıtlı',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(Color cardColor, Color borderColor, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildIconBox(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: mutedColor)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.primaryColor;
              }
              return Colors.grey;
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              _buildIconBox(icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: mutedColor)),
                  ],
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
    required Color textColor,
    required Color mutedColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _buildIconBox(icon, isDestructive: isDestructive),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? AppTheme.dangerColor : textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDestructive ? AppTheme.dangerColor.withValues(alpha: 0.7) : mutedColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDestructive ? AppTheme.dangerColor : mutedColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color textColor,
    required Color mutedColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _buildIconBox(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: textColor)),
          ),
          Text(value, style: TextStyle(color: mutedColor)),
        ],
      ),
    );
  }

  Widget _buildIconBox(IconData icon, {bool isDestructive = false}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDestructive
            ? AppTheme.dangerColor.withValues(alpha: 0.1)
            : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 20,
        color: isDestructive ? AppTheme.dangerColor : AppTheme.primaryColor,
      ),
    );
  }

  // Action Methods
  Future<void> _exportData() async {
    if (_isExporting) return;
    
    setState(() => _isExporting = true);

    try {
      final products = context.read<ProductProvider>().products;
      
      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dışa aktarılacak ürün bulunamadı'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final filePath = await ExportService.exportProductsToExcel(products);
      
      if (filePath != null && mounted) {
        final shouldShare = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.secondaryColor),
                SizedBox(width: 12),
                Text('Dışa Aktarıldı'),
              ],
            ),
            content: Text('${products.length} ürün Excel dosyasına aktarıldı.\n\nDosyayı paylaşmak ister misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Hayır'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Paylaş'),
              ),
            ],
          ),
        );

        if (shouldShare == true) {
          await ExportService.shareExportedFile(filePath);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dışa aktarma başarısız'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    final products = await ExcelImportService.pickAndParseExcel();
    if (products == null || !mounted) return;

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dosyada ürün bulunamadı'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final provider = context.read<ProductProvider>();
    int count = 0;
    for (final p in products) {
      final result = await provider.addProduct(p);
      if (result != null) count++;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count ürün başarıyla eklendi!'),
          backgroundColor: AppTheme.secondaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _backupDatabase() async {
    if (_isBackingUp) return;
    
    setState(() => _isBackingUp = true);

    try {
      final backupPath = await ExportService.backupDatabase();
      
      if (backupPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Veritabanı yedeği oluşturuldu!'),
            backgroundColor: AppTheme.secondaryColor,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Paylaş',
              textColor: Colors.white,
              onPressed: () => ExportService.shareExportedFile(backupPath),
            ),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yedekleme başarısız'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: AppTheme.dangerColor),
            SizedBox(width: 12),
            Text('Tüm Verileri Sil'),
          ],
        ),
        content: const Text(
          'Bu işlem tüm ürünleri ve stok hareketlerini kalıcı olarak silecek.\n\nBu işlem geri alınamaz!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet, Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ProductProvider>().clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm veriler silindi'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Yardım & Destek'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📦 Ürün Ekleme:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('+ butonuna tıklayarak yeni ürün ekleyin'),
            SizedBox(height: 12),
            Text('📊 Stok Takibi:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Ürün detayından giriş/çıkış yapın'),
            SizedBox(height: 12),
            Text('⚠️ Uyarılar:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Düşük stok ürünleri otomatik izlenir'),
            SizedBox(height: 12),
            Text('📱 İletişim:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('destek@depotakip.com'),
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

  void _showPrivacy() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Gizlilik Politikası'),
        content: const SingleChildScrollView(
          child: Text(
            'Bu uygulama verilerinizi yalnızca cihazınızda saklar. '
            'Herhangi bir veri sunuculara gönderilmez.\n\n'
            'Tüm ürün bilgileri, stok hareketleri ve ayarlar '
            'yerel SQLite veritabanında tutulur.\n\n'
            'Kamera izni yalnızca barkod tarama ve OCR için kullanılır.',
          ),
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

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.dangerColor),
            SizedBox(width: 12),
            Text('Çıkış Yap'),
          ],
        ),
        content: const Text('Hesabınızdan çıkış yapmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await AuthService.logout();
        // AuthWrapper'ın çalışmaması durumunda manuel yönlendirme
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Çıkış yapılırken hata: $e'),
              backgroundColor: AppTheme.dangerColor,
            ),
          );
        }
      }
    }
  }




}
