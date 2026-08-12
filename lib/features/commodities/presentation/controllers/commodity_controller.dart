import 'package:flutter/foundation.dart';

import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../watchlist/data/watchlist_repository.dart';
import '../../data/commodity_repository.dart';

class CommodityController extends ChangeNotifier {
  CommodityController({
    required CommodityRepository commodityRepository,
    required WatchlistRepository watchlistRepository,
  }) : _commodityRepository = commodityRepository,
       _watchlistRepository = watchlistRepository;

  final CommodityRepository _commodityRepository;
  final WatchlistRepository _watchlistRepository;

  List<CategoryModel> _categories = [];
  List<CommodityOverview> _commodities = [];
  CommodityDetailData? _detail;
  bool _isLoading = false;
  String? _error;
  int? _selectedCategoryId;
  String _query = '';

  List<CategoryModel> get categories => _categories;
  List<CommodityOverview> get commodities => _commodities;
  CommodityDetailData? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;
  String get query => _query;

  Future<void> loadCategories() async {
    _categories = await _commodityRepository.getCategories();
    notifyListeners();
  }

  Future<void> loadCommodities({required int userId}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _commodities = await _commodityRepository.getCommodities(
        query: _query,
        categoryId: _selectedCategoryId,
        userId: userId,
      );
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDetail({
    required int commodityId,
    required int userId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await _commodityRepository.getCommodityDetail(
        commodityId,
        userId: userId,
      );
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<void> toggleWatchlist({
    required int userId,
    required int commodityId,
    double? threshold,
  }) async {
    await _watchlistRepository.toggleWatchlist(
      userId: userId,
      commodityId: commodityId,
      threshold: threshold,
    );
    await loadCommodities(userId: userId);
    await loadDetail(commodityId: commodityId, userId: userId);
  }
}
