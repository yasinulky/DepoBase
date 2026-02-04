import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'store_service.dart';

/// Authentication Service - Firebase Authentication işlemleri
class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mevcut kullanıcı
  static User? get currentUser => _auth.currentUser;

  /// Kullanıcı oturum durumu stream'i
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Kullanıcı giriş yapmış mı?
  static bool get isLoggedIn => currentUser != null;

  /// Email/Şifre ile Kayıt
  static Future<User?> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Kullanıcı adını güncelle
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      return credential.user;
    } on FirebaseException catch (e) {
      debugPrint('Register error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Email/Şifre ile Giriş
  static Future<User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseException catch (e) {
      debugPrint('Login error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Çıkış Yap
  static Future<void> logout() async {
    StoreService.clearCache(); // Dükkan cache'ini temizle
    await _auth.signOut();
  }

  /// Şifre Sıfırlama
  static Future<void> resetPassword(String email) async {
    try {
      debugPrint('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent successfully');
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
      rethrow;
    }
  }

  /// Firebase Auth hata mesajlarını Türkçe'ye çevir
  static String getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Bu email adresi ile kayıtlı kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Şifre hatalı';
      case 'email-already-in-use':
        return 'Bu email adresi zaten kullanımda';
      case 'weak-password':
        return 'Şifre çok zayıf (en az 6 karakter)';
      case 'invalid-email':
        return 'Geçersiz email adresi';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin';
      case 'network-request-failed':
        return 'İnternet bağlantısı bulunamadı';
      default:
        return 'Bir hata oluştu: $code';
    }
  }
}
