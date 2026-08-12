import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../../core/database/cloud_data_service.dart';
import '../../../shared/models/user_model.dart';

class ProfileRepository {
  ProfileRepository({
    required CloudDataService cloudDataService,
    required firebase.FirebaseAuth firebaseAuth,
  }) : _cloudDataService = cloudDataService,
       _firebaseAuth = firebaseAuth;

  final CloudDataService _cloudDataService;
  final firebase.FirebaseAuth _firebaseAuth;

  Future<UserModel> getUser(int userId) async {
    final row = await _cloudDataService.getDocument('users', userId);
    if (row == null) {
      throw Exception('User not found.');
    }
    return UserModel.fromMap(row);
  }

  Future<UserModel> updateProfile({
    required int userId,
    required String fullName,
    required String email,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = await getUser(userId);
    final authUser = _firebaseAuth.currentUser;
    if (authUser == null) throw Exception('Please sign in again.');
    if (normalizedEmail != user.email) {
      await authUser.verifyBeforeUpdateEmail(normalizedEmail);
    }
    await authUser.updateDisplayName(fullName.trim());
    await _cloudDataService.setDocument('users', userId, {
      ...user.toMap(),
      'full_name': fullName.trim(),
      // Firebase keeps the old address active until verification completes.
      'email': authUser.email ?? user.email,
    });
    return getUser(userId);
  }

  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final authUser = _firebaseAuth.currentUser;
    final email = authUser?.email;
    if (authUser == null || email == null) {
      throw Exception('Please sign in again.');
    }
    try {
      final credential = firebase.EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await authUser.reauthenticateWithCredential(credential);
      await authUser.updatePassword(newPassword);
    } on firebase.FirebaseAuthException catch (error) {
      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        throw Exception('Current password is incorrect.');
      }
      throw Exception(error.message ?? 'Password could not be changed.');
    }
  }

  Future<void> sendPasswordReset() async {
    final email = _firebaseAuth.currentUser?.email;
    if (email == null) throw Exception('No email is linked to this account.');
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> deactivateAccount({required int userId}) async {
    final authUser = _firebaseAuth.currentUser;
    if (authUser == null) throw Exception('Please sign in again.');
    final user = await getUser(userId);
    await _cloudDataService.deactivateOwnAccount(
      userId: userId,
      authUid: authUser.uid,
      userData: {
        ...user.toMap(),
        'active': false,
        'deactivated_at': DateTime.now().toIso8601String(),
      },
    );
    await _firebaseAuth.signOut();
  }
}
