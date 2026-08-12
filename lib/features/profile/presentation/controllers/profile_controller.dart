import 'package:flutter/foundation.dart';

import '../../../../shared/models/user_model.dart';
import '../../data/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({required ProfileRepository profileRepository})
    : _profileRepository = profileRepository;

  final ProfileRepository _profileRepository;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<UserModel?> updateProfile({
    required int userId,
    required String fullName,
    required String email,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      return await _profileRepository.updateProfile(
        userId: userId,
        fullName: fullName,
        email: email,
      );
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _profileRepository.changePassword(
        userId: userId,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendPasswordReset() async {
    try {
      await _profileRepository.sendPasswordReset();
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> deactivateAccount(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _profileRepository.deactivateAccount(userId: userId);
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
