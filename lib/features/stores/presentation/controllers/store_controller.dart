import 'package:flutter/foundation.dart';

import '../../../../shared/models/ui_models.dart';
import '../../data/store_repository.dart';

class StoreController extends ChangeNotifier {
  StoreController({required StoreRepository storeRepository})
    : _storeRepository = storeRepository;

  final StoreRepository _storeRepository;

  List<StoreSummary> _stores = [];
  StoreDetailData? _detail;
  bool _isLoading = false;
  String? _error;

  List<StoreSummary> get stores => _stores;
  StoreDetailData? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStores({String query = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _stores = await _storeRepository.getStores(query: query);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail(int storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await _storeRepository.getStoreDetail(storeId);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
