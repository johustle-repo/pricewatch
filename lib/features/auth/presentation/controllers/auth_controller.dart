import 'package:flutter/foundation.dart';

import '../../../../shared/models/user_model.dart';
import '../../data/auth_repository.dart';

enum AuthStatus { initializing, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController({required AuthRepository authRepository})
    : _authRepository = authRepository;

  final AuthRepository _authRepository;

  AuthStatus _status = AuthStatus.initializing;
  UserModel? _currentUser;
  bool _isBusy = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _status = AuthStatus.initializing;
    notifyListeners();

    try {
      _currentUser = await _authRepository.getActiveUser();
      _status = _currentUser == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
    } catch (error) {
      _errorMessage = error.toString();
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _setBusy(true);
    _errorMessage = null;
    try {
      _currentUser = await _authRepository.login(
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    String role = 'user',
    int? storeId,
  }) async {
    _setBusy(true);
    _errorMessage = null;
    try {
      _currentUser = await _authRepository.register(
        fullName: fullName,
        email: email,
        password: password,
        role: role,
        storeId: storeId,
      );
      _status = AuthStatus.authenticated;
      return true;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> refreshUser() async {
    final userId = _currentUser?.id;
    if (userId == null) {
      return;
    }
    _currentUser = await _authRepository.getUserById(userId);
    notifyListeners();
  }

  Future<void> logout() async {
    final user = _currentUser;
    final userId = user?.id;
    if (userId == null) {
      return;
    }

    _setBusy(true);
    _errorMessage = null;
    try {
      await _authRepository.logout(userId);
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _setBusy(false);
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}
