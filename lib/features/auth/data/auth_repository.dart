import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/models/user_model.dart';

class AuthRepository {
  AuthRepository({
    required CloudDataService cloudDataService,
    required firebase.FirebaseAuth firebaseAuth,
  }) : _cloudDataService = cloudDataService,
       _firebaseAuth = firebaseAuth;

  final CloudDataService _cloudDataService;
  final firebase.FirebaseAuth _firebaseAuth;

  Future<UserModel?> getActiveUser() async {
    final authUser = _firebaseAuth.currentUser;
    if (authUser == null) return null;
    final access = await _cloudDataService.getDocumentByKey(
      'access_control',
      authUser.uid,
    );
    var userId = access?['user_id'];
    if (userId is! int && authUser.email != null) {
      userId = await _cloudDataService.claimLegacyProfile(
        authUid: authUser.uid,
        email: authUser.email!,
      );
    }
    if (access?['active'] == false || userId is! int) {
      await _firebaseAuth.signOut();
      return null;
    }
    await _cloudDataService.setActiveUserId(userId);
    return getUserById(userId);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    try {
      await _firebaseAuth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
    } on firebase.FirebaseAuthException catch (error) {
      if ({'user-not-found', 'invalid-credential'}.contains(error.code)) {
        throw Exception(
          'This account is not registered in Firebase Authentication. '
          'Select Create account once using this email, then sign in normally.',
        );
      } else {
        throw Exception(_authMessage(error));
      }
    }
    final user = await getActiveUser();
    if (user == null) throw Exception('Your account profile is unavailable.');
    return user;
  }

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'user',
    int? storeId,
  }) async {
    if (role != 'user') {
      throw Exception(
        'Vendor and admin accounts can only be created from the admin workspace.',
      );
    }
    final normalizedEmail = email.trim().toLowerCase();
    firebase.UserCredential credential;
    try {
      credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      await credential.user?.updateDisplayName(fullName.trim());
    } on firebase.FirebaseAuthException catch (error) {
      throw Exception(_authMessage(error));
    }
    final authUid = credential.user?.uid;
    if (authUid == null) throw Exception('Firebase account creation failed.');
    final userId = _cloudDataService.generateId();
    final now = DateTimeUtils.nowIso();
    try {
      await _cloudDataService.createAuthenticatedUserProfile(
        authUid: authUid,
        userId: userId,
        userData: {
          'id': userId,
          'auth_uid': authUid,
          'full_name': fullName.trim(),
          'email': normalizedEmail,
          'role': 'user',
          'store_id': null,
          'created_at': now,
        },
      );
    } catch (_) {
      await credential.user?.delete();
      rethrow;
    }

    final notificationId = _cloudDataService.generateId();
    await _cloudDataService.setDocument('notifications', notificationId, {
      'id': notificationId,
      'user_id': userId,
      'title': 'Welcome to PriceWatch',
      'body':
          'Your cloud account is ready. Start tracking prices and watchlists.',
      'type': 'system',
      'is_read': 0,
      'created_at': now,
    });

    await _cloudDataService.setActiveUserId(userId);
    final created = await getUserById(userId);
    if (created == null) {
      throw Exception('Account was created but could not be loaded.');
    }
    return created;
  }

  Future<void> logout(int userId) async {
    await _firebaseAuth.signOut();
    await _cloudDataService.clearActiveUserId();
  }

  Future<UserModel?> getUserById(int id) async {
    final row = await _cloudDataService.getDocument('users', id);
    if (row == null) {
      return null;
    }
    return UserModel.fromMap(row);
  }

  String _authMessage(firebase.FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Use a stronger password with at least six characters.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Could not connect to Firebase Authentication.';
      default:
        return error.message ?? 'Authentication failed.';
    }
  }
}
