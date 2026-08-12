import 'package:flutter/foundation.dart';

import '../../../../shared/models/ui_models.dart';
import '../../data/home_repository.dart';

class HomeController extends ChangeNotifier {
  HomeController({required HomeRepository homeRepository})
    : _homeRepository = homeRepository;

  final HomeRepository _homeRepository;

  DashboardData? _dashboard;
  bool _isLoading = false;
  String? _error;

  DashboardData? get dashboard => _dashboard;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> load(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _homeRepository.getDashboard(userId);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
