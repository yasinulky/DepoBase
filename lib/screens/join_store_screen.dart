import 'package:flutter/material.dart';
import '../theme/theme.dart';
import '../services/services.dart';
import 'main_screen.dart';

/// Join Store Screen - Dükkana Katılma / Yeni Dükkan Oluşturma Ekranı
/// Dükkansız kullanıcılar (atılmış veya ayrılmış) için
class JoinStoreScreen extends StatefulWidget {
  const JoinStoreScreen({super.key});

  @override
  State<JoinStoreScreen> createState() => _JoinStoreScreenState();
}

class _JoinStoreScreenState extends State<JoinStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeCodeController = TextEditingController();
  bool _isLoading = false;
  bool _createNew = true; // true: yeni dükkan, false: mevcut dükkana katıl

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.surfaceColor,
      appBar: AppBar(
        title: const Text('Dükkana Katıl'),
        actions: [
          // Çıkış Yap butonu
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.store_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    'Merhaba, ${AuthService.currentUser?.displayName ?? "Kullanıcı"}!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bir dükkana katılın veya yeni dükkan oluşturun',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Seçenek kartları
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkCard : AppTheme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.darkBorder : AppTheme.borderColor,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Toggle
                        Row(
                          children: [
                            Expanded(
                              child: _buildOptionButton(
                                title: 'Yeni Dükkan',
                                icon: Icons.add_business_rounded,
                                isSelected: _createNew,
                                onTap: () => setState(() => _createNew = true),
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildOptionButton(
                                title: 'Kodum Var',
                                icon: Icons.qr_code_rounded,
                                isSelected: !_createNew,
                                onTap: () => setState(() => _createNew = false),
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Koşullu alan
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _createNew
                              ? TextFormField(
                                  key: const ValueKey('store_name'),
                                  controller: _storeNameController,
                                  style: TextStyle(
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Dükkan Adı',
                                    hintText: 'Örn: Yasin Market',
                                    prefixIcon: Icon(Icons.store_outlined),
                                  ),
                                  validator: (value) {
                                    if (_createNew && (value == null || value.isEmpty)) {
                                      return 'Dükkan adı gerekli';
                                    }
                                    return null;
                                  },
                                )
                              : TextFormField(
                                  key: const ValueKey('store_code'),
                                  controller: _storeCodeController,
                                  textCapitalization: TextCapitalization.characters,
                                  style: TextStyle(
                                    color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Dükkan Kodu',
                                    hintText: 'Örn: ABC123',
                                    prefixIcon: Icon(Icons.vpn_key_outlined),
                                  ),
                                  validator: (value) {
                                    if (!_createNew && (value == null || value.isEmpty)) {
                                      return 'Dükkan kodu gerekli';
                                    }
                                    if (!_createNew && value!.length < 6) {
                                      return 'Dükkan kodu 6 karakter olmalı';
                                    }
                                    return null;
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Devam butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_createNew ? 'Dükkan Oluştur' : 'Dükkana Katıl'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.darkBorder : AppTheme.borderColor),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected
                  ? AppTheme.primaryColor
                  : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AppTheme.primaryColor
                    : (isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) throw Exception('Kullanıcı bulunamadı');
      
      bool success = false;
      
      if (_createNew) {
        // Yeni dükkan oluştur
        final storeId = await StoreService.createStore(
          storeName: _storeNameController.text.trim(),
          ownerId: userId,
        );
        success = storeId != null;
      } else {
        // Mevcut dükkana katıl
        success = await StoreService.joinStore(_storeCodeController.text.trim());
      }
      
      if (success && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_createNew 
                ? 'Dükkan oluşturulamadı' 
                : 'Dükkan kodu bulunamadı'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppTheme.dangerColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    // AuthWrapper login ekranına yönlendirecek
  }
}
