import 'package:flutter/foundation.dart';

import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/subcategory_model.dart';
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
  List<SubcategoryModel> _subcategories = [];
  List<CommodityOverview> _commodities = [];
  CommodityDetailData? _detail;
  bool _isLoading = false;
  String? _error;
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  String _query = '';

  List<CategoryModel> get categories => _categories;

  /// Sub-categories of the selected category; empty when none is selected.
  List<SubcategoryModel> get subcategories => _subcategories;
  List<CommodityOverview> get commodities => _commodities;
  CommodityDetailData? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int? get selectedCategoryId => _selectedCategoryId;
  int? get selectedSubcategoryId => _selectedSubcategoryId;
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
      _subcategories = _selectedCategoryId == null
          ? []
          : await _commodityRepository.getSubcategories(
              categoryId: _selectedCategoryId,
            );
      if (!_subcategories.any((item) => item.id == _selectedSubcategoryId)) {
        _selectedSubcategoryId = null;
      }
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
    if (_selectedCategoryId != categoryId) {
      _selectedSubcategoryId = null;
    }
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSubcategory(int? subcategoryId) {
    _selectedSubcategoryId = subcategoryId;
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
