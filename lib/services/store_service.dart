import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// Store Service - Dükkan yönetimi
class StoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Kullanıcının mevcut dükkan ID'si (cache)
  static String? _currentStoreId;
  
  /// Mevcut dükkan ID'sini al
  static Future<String?> getCurrentStoreId() async {
    if (_currentStoreId != null) return _currentStoreId;
    
    final userId = AuthService.currentUser?.uid;
    if (userId == null) return null;
    
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      _currentStoreId = userDoc.data()?['storeId'] as String?;
      return _currentStoreId;
    } catch (e) {
      debugPrint('Error getting current store: $e');
      return null;
    }
  }
  
  /// Cache'i temizle (logout'ta çağrılmalı)
  static void clearCache() {
    _currentStoreId = null;
  }
  
  /// Yeni dükkan oluştur (kayıt sırasında)
  static Future<String?> createStore({
    required String storeName,
    required String ownerId,
  }) async {
    try {
      // 6 haneli benzersiz kod oluştur
      final storeCode = await _generateUniqueCode();
      
      // Dükkan dökümanı oluştur
      final storeRef = _firestore.collection('stores').doc();
      await storeRef.set({
        'name': storeName,
        'code': storeCode,
        'ownerId': ownerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      final storeId = storeRef.id;
      
      // Sahibi üye olarak ekle
      await storeRef.collection('members').doc(ownerId).set({
        'role': 'owner',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      // Kullanıcı dökümanına storeId ve kullanıcı bilgilerini ekle
      final user = AuthService.currentUser;
      await _firestore.collection('users').doc(ownerId).set({
        'storeId': storeId,
        'storeCode': storeCode,
        'email': user?.email ?? '',
        'displayName': user?.displayName ?? '',
      }, SetOptions(merge: true));
      
      _currentStoreId = storeId;
      debugPrint('Store created: $storeId with code: $storeCode');
      return storeId;
    } catch (e) {
      debugPrint('Error creating store: $e');
      return null;
    }
  }
  
  /// Dükkan koduna göre dükkana katıl
  static Future<bool> joinStore(String code) async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) return false;
      
      // Kodu ile dükkanı bul
      final storeQuery = await _firestore
          .collection('stores')
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();
      
      if (storeQuery.docs.isEmpty) {
        debugPrint('Store not found with code: $code');
        return false;
      }
      
      final storeDoc = storeQuery.docs.first;
      final storeId = storeDoc.id;
      
      // Üye olarak ekle
      await storeDoc.reference.collection('members').doc(userId).set({
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
      });
      
      // Kullanıcı dökümanına storeId ve kullanıcı bilgilerini ekle
      final user = AuthService.currentUser;
      await _firestore.collection('users').doc(userId).set({
        'storeId': storeId,
        'storeCode': code.toUpperCase(),
        'email': user?.email ?? '',
        'displayName': user?.displayName ?? '',
      }, SetOptions(merge: true));
      
      _currentStoreId = storeId;
      debugPrint('Joined store: $storeId');
      return true;
    } catch (e) {
      debugPrint('Error joining store: $e');
      return false;
    }
  }
  
  /// Dükkan bilgilerini al
  static Future<Map<String, dynamic>?> getStoreInfo() async {
    try {
      final storeId = await getCurrentStoreId();
      if (storeId == null) return null;
      
      final storeDoc = await _firestore.collection('stores').doc(storeId).get();
      if (!storeDoc.exists) return null;
      
      return {
        'id': storeId,
        ...storeDoc.data()!,
      };
    } catch (e) {
      debugPrint('Error getting store info: $e');
      return null;
    }
  }
  
  /// Kullanıcının rolünü al
  static Future<String?> getUserRole() async {
    try {
      final storeId = await getCurrentStoreId();
      final userId = AuthService.currentUser?.uid;
      if (storeId == null || userId == null) return null;
      
      final memberDoc = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('members')
          .doc(userId)
          .get();
      
      return memberDoc.data()?['role'] as String?;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }
  
  /// Kullanıcı dükkan sahibi mi?
  static Future<bool> isOwner() async {
    final role = await getUserRole();
    return role == 'owner';
  }
  
  /// Dükkan üyelerini detaylı bilgilerle al (sadece owner için)
  static Future<List<Map<String, dynamic>>> getMembersWithDetails() async {
    try {
      final storeId = await getCurrentStoreId();
      if (storeId == null) return [];
      
      final membersSnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('members')
          .get();
      
      List<Map<String, dynamic>> membersList = [];
      
      for (final doc in membersSnapshot.docs) {
        final userId = doc.id;
        final memberData = doc.data();
        
        // Kullanıcı bilgilerini al
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data() ?? {};
        
        membersList.add({
          'userId': userId,
          'role': memberData['role'] ?? 'member',
          'joinedAt': memberData['joinedAt'],
          'email': userData['email'] ?? '',
          'displayName': userData['displayName'] ?? 'İsimsiz Kullanıcı',
        });
      }
      
      return membersList;
    } catch (e) {
      debugPrint('Error getting members with details: $e');
      return [];
    }
  }
  
  /// Dükkan üyelerini al (sadece owner için)
  static Future<List<Map<String, dynamic>>> getMembers() async {
    try {
      final storeId = await getCurrentStoreId();
      if (storeId == null) return [];
      
      final membersSnapshot = await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('members')
          .get();
      
      return membersSnapshot.docs.map((doc) => {
        'userId': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error getting members: $e');
      return [];
    }
  }
  
  /// Üyeyi dükkan dan çıkar (sadece owner için)
  static Future<bool> removeMember(String userId) async {
    try {
      if (!await isOwner()) return false;
      
      final storeId = await getCurrentStoreId();
      if (storeId == null) return false;
      
      // Üyelikten çıkar
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('members')
          .doc(userId)
          .delete();
      
      // Kullanıcının storeId'sini temizle
      await _firestore.collection('users').doc(userId).update({
        'storeId': FieldValue.delete(),
        'storeCode': FieldValue.delete(),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error removing member: $e');
      return false;
    }
  }
  
  /// Kullanıcının kendi isteğiyle dükkandan ayrılması
  /// Not: Sahip ayrılamaz
  static Future<bool> leaveStore() async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) return false;
      
      // Sahip ayrılamaz
      if (await isOwner()) {
        debugPrint('Owner cannot leave store');
        return false;
      }
      
      final storeId = await getCurrentStoreId();
      if (storeId == null) return false;
      
      // Üyelikten çık
      await _firestore
          .collection('stores')
          .doc(storeId)
          .collection('members')
          .doc(userId)
          .delete();
      
      // Kullanıcının storeId'sini temizle
      await _firestore.collection('users').doc(userId).update({
        'storeId': FieldValue.delete(),
        'storeCode': FieldValue.delete(),
      });
      
      // Cache'i temizle
      clearCache();
      
      return true;
    } catch (e) {
      debugPrint('Error leaving store: $e');
      return false;
    }
  }
  
  /// Dükkanı sil (sadece sahip için)
  static Future<bool> deleteStore() async {
    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) return false;
      
      final storeId = await getCurrentStoreId();
      if (storeId == null) return false;
      
      // Sahip mi kontrol et
      final role = await getUserRole();
      if (role != 'owner') {
        debugPrint('Only owner can delete store');
        return false;
      }
      
      final storeRef = _firestore.collection('stores').doc(storeId);
      
      // Tüm üyeleri al
      final membersSnapshot = await storeRef.collection('members').get();
      
      // Her üye için storeId'yi temizle ve members'dan sil
      for (final memberDoc in membersSnapshot.docs) {
        final memberId = memberDoc.id;
        
        // Kullanıcının storeId'sini temizle
        await _firestore.collection('users').doc(memberId).update({
          'storeId': FieldValue.delete(),
          'storeCode': FieldValue.delete(),
        });
        
        // Members'dan sil
        await memberDoc.reference.delete();
      }
      
      // Dükkan dökümanını sil
      await storeRef.delete();
      
      // Cache'i temizle
      clearCache();
      
      debugPrint('Store deleted: $storeId');
      return true;
    } catch (e) {
      debugPrint('Error deleting store: $e');
      return false;
    }
  }
  
  /// Benzersiz 6 haneli kod oluştur
  static Future<String> _generateUniqueCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    
    while (true) {
      final code = List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
      
      // Kodun benzersiz olup olmadığını kontrol et
      final existing = await _firestore
          .collection('stores')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      
      if (existing.docs.isEmpty) {
        return code;
      }
    }
  }
}
