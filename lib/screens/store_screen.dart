import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme.dart';
import '../services/services.dart';
import 'join_store_screen.dart';

/// Store Screen - Dükkan Yönetimi Ekranı
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  Map<String, dynamic>? _storeInfo;
  String? _userRole;
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    
    final storeInfo = await StoreService.getStoreInfo();
    final userRole = await StoreService.getUserRole();
    final members = await StoreService.getMembersWithDetails();
    
    if (mounted) {
      setState(() {
        _storeInfo = storeInfo;
        _userRole = userRole;
        _members = members;
        _isLoading = false;
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
        title: const Text('Dükkan'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _loadStoreData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _storeInfo == null
              ? _buildNoStoreView(cardColor, borderColor, textColor, mutedColor, isDark)
              : RefreshIndicator(
                  onRefresh: _loadStoreData,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Dükkan Bilgisi Kartı
                      _buildStoreInfoCard(cardColor, borderColor, textColor, mutedColor),
                      const SizedBox(height: 24),

                      // Üyeler Bölümü
                      _buildSectionTitle('Dükkan Üyeleri (${_members.length})', mutedColor),
                      const SizedBox(height: 12),
                      _buildMembersList(cardColor, borderColor, textColor, mutedColor),
                      const SizedBox(height: 24),

                      // Eylemler
                      _buildSectionTitle('İşlemler', mutedColor),
                      const SizedBox(height: 12),
                      if (_userRole == 'owner') 
                        _buildDeleteStoreButton(cardColor, borderColor)
                      else
                        _buildLeaveButton(cardColor, borderColor),
                    ],
                  ),
                ),
    );
  }

  /// Dükkan yoksa gösterilecek ekran
  Widget _buildNoStoreView(Color cardColor, Color borderColor, Color textColor, Color mutedColor, bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // İkon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.store_mall_directory_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            
            Text(
              'Henüz bir dükkana katılmadınız',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Yeni bir dükkan oluşturabilir veya mevcut bir dükkana kod ile katılabilirsiniz.',
              style: TextStyle(
                fontSize: 14,
                color: mutedColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Yeni Dükkan Oluştur butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _showCreateStoreDialog(isDark, textColor),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Yeni Dükkan Oluştur'),
              ),
            ),
            const SizedBox(height: 16),
            
            // Dükkana Katıl butonu
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton.icon(
                onPressed: () => _showJoinStoreDialog(isDark, textColor),
                icon: const Icon(Icons.login_rounded),
                label: const Text('Kodla Dükkana Katıl'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreateStoreDialog(bool isDark, Color textColor) async {
    final controller = TextEditingController();
    
    final storeName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_business_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Yeni Dükkan'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: TextStyle(color: textColor),
          decoration: const InputDecoration(
            labelText: 'Dükkan Adı',
            hintText: 'Örn: Yasin Market',
            prefixIcon: Icon(Icons.store_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(ctx, controller.text.trim());
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
    
    if (storeName != null && storeName.isNotEmpty && mounted) {
      final userId = AuthService.currentUser?.uid;
      if (userId != null) {
        final storeId = await StoreService.createStore(
          storeName: storeName,
          ownerId: userId,
        );
        if (storeId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dükkan oluşturuldu!'),
              backgroundColor: AppTheme.secondaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadStoreData();
        }
      }
    }
  }

  Future<void> _showJoinStoreDialog(bool isDark, Color textColor) async {
    final controller = TextEditingController();
    
    final storeCode = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.login_rounded, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text('Dükkana Katıl'),
          ],
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          style: TextStyle(
            color: textColor,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
          decoration: const InputDecoration(
            labelText: 'Dükkan Kodu',
            hintText: 'Örn: ABC123',
            prefixIcon: Icon(Icons.vpn_key_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().length >= 6) {
                Navigator.pop(ctx, controller.text.trim().toUpperCase());
              }
            },
            child: const Text('Katıl'),
          ),
        ],
      ),
    );
    
    if (storeCode != null && storeCode.isNotEmpty && mounted) {
      final success = await StoreService.joinStore(storeCode);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dükkana katıldınız!'),
              backgroundColor: AppTheme.secondaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadStoreData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dükkan kodu bulunamadı'),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildStoreInfoCard(Color cardColor, Color borderColor, Color textColor, Color mutedColor) {
    final storeName = _storeInfo?['name'] ?? 'Dükkan';
    final storeCode = _storeInfo?['code'] ?? '------';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.store_rounded, color: Colors.white, size: 32),
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
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _userRole == 'owner' ? '👑 Sahip' : '👤 Üye',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Dükkan Kodu
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code, color: Colors.white, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dükkan Kodu',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        storeCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: storeCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dükkan kodu kopyalandı!'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, color: Colors.white),
                  tooltip: 'Kodu Kopyala',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bu kodu çalışanlarınıza verin, dükkana katılabilsinler',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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

  Widget _buildMembersList(Color cardColor, Color borderColor, Color textColor, Color mutedColor) {
    if (_members.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text('Henüz üye yok', style: TextStyle(color: mutedColor)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: _members.asMap().entries.map((entry) {
          final index = entry.key;
          final member = entry.value;
          final isCurrentUser = member['userId'] == AuthService.currentUser?.uid;
          final isOwner = member['role'] == 'owner';

          return Column(
            children: [
              if (index > 0) Divider(height: 1, color: borderColor),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isOwner
                            ? AppTheme.warningColor.withValues(alpha: 0.1)
                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isOwner ? Icons.star_rounded : Icons.person_rounded,
                        size: 22,
                        color: isOwner ? AppTheme.warningColor : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // İsim ve Email
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  member['displayName'] ?? 'İsimsiz',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: textColor,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isOwner) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    '👑 Sahip',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ),
                              ],
                              if (isCurrentUser && !isOwner) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Ben',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member['email'] ?? '',
                            style: TextStyle(fontSize: 12, color: mutedColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Çıkarma butonu (sadece sahip için, kendisi ve sahip hariç)
                    if (_userRole == 'owner' && !isOwner && !isCurrentUser)
                      IconButton(
                        onPressed: () => _removeMember(member['userId'], member['displayName'] ?? 'Bu üye'),
                        icon: const Icon(Icons.person_remove_rounded),
                        color: AppTheme.dangerColor,
                        tooltip: 'Üyeyi Çıkar',
                      ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeaveButton(Color cardColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        onTap: _leaveStore,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.dangerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.exit_to_app_rounded, color: AppTheme.dangerColor),
        ),
        title: const Text(
          'Dükkandan Ayrıl',
          style: TextStyle(
            color: AppTheme.dangerColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: const Text('Bu dükkandan çıkış yap'),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.dangerColor),
      ),
    );
  }

  Future<void> _removeMember(String userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.person_remove_rounded, color: AppTheme.dangerColor),
            SizedBox(width: 12),
            Text('Üyeyi Çıkar'),
          ],
        ),
        content: Text(
          '"$displayName" adlı kullanıcıyı dükkandan çıkarmak istediğinize emin misiniz?\n\nBu kullanıcı artık dükkanın ürünlerini göremeyecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await StoreService.removeMember(userId);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$displayName dükkandan çıkarıldı'),
              backgroundColor: AppTheme.secondaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadStoreData(); // Listeyi yenile
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Üye çıkarılamadı'),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _leaveStore() async {
    final storeName = _storeInfo?['name'] ?? 'bu dükkan';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.exit_to_app_rounded, color: AppTheme.dangerColor),
            SizedBox(width: 12),
            Text('Dükkandan Ayrıl'),
          ],
        ),
        content: Text(
          '"$storeName" dükkanından ayrılmak istediğinize emin misiniz?\n\nAyrıldıktan sonra başka bir dükkana katılabilir veya yeni dükkan oluşturabilirsiniz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ayrıl'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await StoreService.leaveStore();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dükkandan ayrıldınız'),
              backgroundColor: AppTheme.secondaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // JoinStoreScreen'e yönlendir
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const JoinStoreScreen()),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dükkandan ayrılırken hata oluştu'),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Widget _buildDeleteStoreButton(Color cardColor, Color borderColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        onTap: _deleteStore,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.dangerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.delete_forever_rounded, color: AppTheme.dangerColor),
        ),
        title: const Text(
          'Dükkanı Sil',
          style: TextStyle(
            color: AppTheme.dangerColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: const Text('Dükkanı ve tüm verileri kalıcı olarak sil'),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.dangerColor),
      ),
    );
  }

  Future<void> _deleteStore() async {
    final storeName = _storeInfo?['name'] ?? 'bu dükkan';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppTheme.dangerColor),
            SizedBox(width: 12),
            Expanded(child: Text('Dükkanı Sil')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"$storeName" dükkanını kalıcı olarak silmek istediğinize emin misiniz?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_rounded, color: AppTheme.dangerColor, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem geri alınamaz! Tüm üyeler dükkandan çıkarılacak.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.dangerColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      final success = await StoreService.deleteStore();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dükkan silindi'),
              backgroundColor: AppTheme.secondaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Verileri yenile - dükkansız ekran gösterilecek
          _loadStoreData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dükkan silinirken hata oluştu'),
              backgroundColor: AppTheme.dangerColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
