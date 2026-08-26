import 'package:flutter/foundation.dart';

import '../../../../shared/models/vendor_incident_model.dart';
import '../../data/vendor_incident_repository.dart';

class VendorIncidentController extends ChangeNotifier {
  VendorIncidentController({required VendorIncidentRepository repository})
    : _repository = repository;

  final VendorIncidentRepository _repository;
  List<VendorIncidentViewData> _incidents = [];
  bool _isLoading = false;
  String? _error;
  String? _scope;

  List<VendorIncidentViewData> get incidents => _incidents;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUser(int userId) => _load(
    scope: 'user:$userId',
    request: () => _repository.getForUser(userId),
  );
  Future<void> loadAdmin() =>
      _load(scope: 'admin', request: _repository.getAll);

  Future<void> _load({
    required String scope,
    required Future<List<VendorIncidentViewData>> Function() request,
  }) async {
    if (_scope != scope) {
      _scope = scope;
      _incidents = [];
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _incidents = await request();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submit({
    required int userId,
    required String reportedVendorName,
    required String marketLocation,
    required String reasonCode,
    required String details,
    required List<String> evidencePhotos,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.submit(
        userId: userId,
        reportedVendorName: reportedVendorName,
        marketLocation: marketLocation,
        reasonCode: reasonCode,
        details: details,
        evidencePhotos: evidencePhotos,
      );
      await loadUser(userId);
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(int id, String status) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.updateStatus(id: id, status: status);
      await loadAdmin();
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteIncident(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.delete(id);
      await loadAdmin();
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
