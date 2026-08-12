import 'package:flutter/foundation.dart';

import '../../../../shared/models/category_model.dart';
import '../../../../shared/models/commodity_model.dart';
import '../../../../shared/models/store_model.dart';
import '../../../../shared/models/ui_models.dart';
import '../../../../shared/models/user_model.dart';
import '../../data/admin_repository.dart';
import '../../data/csv_import_service.dart';

class AdminController extends ChangeNotifier {
  AdminController({required AdminRepository adminRepository})
    : _adminRepository = adminRepository;

  final AdminRepository _adminRepository;

  List<CategoryModel> _categories = [];
  List<CommodityModel> _commodities = [];
  List<StoreModel> _stores = [];
  List<StoreModel> _archivedStores = [];
  List<UserModel> _users = [];
  List<ReportViewData> _reports = [];
  List<AdminPriceEntryView> _priceEntries = [];
  AdminAnalyticsData? _analytics;
  List<Map<String, Object?>> _auditLogs = [];
  bool _isLoading = false;
  double? _importProgress;
  String? _error;

  List<CategoryModel> get categories => _categories;
  List<CommodityModel> get commodities => _commodities;
  List<StoreModel> get stores => _stores;
  List<StoreModel> get archivedStores => _archivedStores;
  List<UserModel> get users => _users;
  List<ReportViewData> get reports => _reports;
  List<AdminPriceEntryView> get priceEntries => _priceEntries;
  AdminAnalyticsData? get analytics => _analytics;
  List<Map<String, Object?>> get auditLogs => _auditLogs;
  bool get isLoading => _isLoading;
  double? get importProgress => _importProgress;
  String? get error => _error;

  Future<void> loadCategories() async {
    await _run(() async {
      _categories = await _adminRepository.getCategories();
    });
  }

  Future<void> loadCommodities() async {
    await _run(() async {
      _commodities = await _adminRepository.getCommodities();
    });
  }

  Future<void> loadStores() async {
    await _run(() async {
      _stores = await _adminRepository.getStores();
      _archivedStores = await _adminRepository.getStores(archived: true);
    });
  }

  Future<void> loadReports() async {
    await _run(() async {
      _reports = await _adminRepository.getReports();
    });
  }

  Future<void> loadPriceEntries() async {
    await _run(() async {
      _priceEntries = await _adminRepository.getPriceEntries();
    });
  }

  Future<void> loadUsers() async {
    await _run(() async {
      _users = await _adminRepository.getUsers();
    });
  }

  Future<void> loadAnalytics() async {
    await _run(() async {
      _analytics = await _adminRepository.getAnalytics();
      _auditLogs = await _adminRepository.getAuditLogs();
    });
  }

  Future<void> saveCategory({
    int? id,
    required String name,
    required String icon,
  }) async {
    await _run(() async {
      await _adminRepository.saveCategory(id: id, name: name, icon: icon);
      _categories = await _adminRepository.getCategories();
    });
  }

  Future<void> deleteCategory(int categoryId) async {
    await _run(() async {
      await _adminRepository.deleteCategory(categoryId);
      _categories = await _adminRepository.getCategories();
    });
  }

  Future<void> saveCommodity({
    int? id,
    required int categoryId,
    required String name,
    required String description,
    required String unit,
    required double srp,
  }) async {
    await _run(() async {
      await _adminRepository.saveCommodity(
        id: id,
        categoryId: categoryId,
        name: name,
        description: description,
        unit: unit,
        srp: srp,
      );
      _commodities = await _adminRepository.getCommodities();
    });
  }

  Future<void> deleteCommodity(int commodityId) async {
    await _run(() async {
      await _adminRepository.deleteCommodity(commodityId);
      _commodities = await _adminRepository.getCommodities();
    });
  }

  Future<void> saveStore({
    int? id,
    required String name,
    required String ownerName,
    int? ownerUserId,
    required String marketName,
    required String address,
    required String city,
  }) async {
    await _run(() async {
      await _adminRepository.saveStore(
        id: id,
        name: name,
        ownerName: ownerName,
        ownerUserId: ownerUserId,
        marketName: marketName,
        address: address,
        city: city,
      );
      _stores = await _adminRepository.getStores();
    });
  }

  Future<void> deleteStore(int storeId) async {
    await _run(() async {
      await _adminRepository.deleteStore(storeId);
      _stores = await _adminRepository.getStores();
      _archivedStores = await _adminRepository.getStores(archived: true);
    });
  }

  Future<void> archiveStore(int storeId) async {
    await _run(() async {
      await _adminRepository.archiveStore(storeId);
      _stores = await _adminRepository.getStores();
      _archivedStores = await _adminRepository.getStores(archived: true);
    });
  }

  Future<void> restoreStore(int storeId) async {
    await _run(() async {
      await _adminRepository.restoreStore(storeId);
      _stores = await _adminRepository.getStores();
      _archivedStores = await _adminRepository.getStores(archived: true);
    });
  }

  Future<void> saveUser({
    int? id,
    required String fullName,
    required String email,
    required String role,
    int? storeId,
    String? password,
  }) async {
    await _run(() async {
      await _adminRepository.saveUser(
        id: id,
        fullName: fullName,
        email: email,
        role: role,
        storeId: storeId,
        password: password,
      );
      _users = await _adminRepository.getUsers();
    });
  }

  Future<void> deleteUser(int userId) async {
    await _run(() async {
      await _adminRepository.deleteUser(userId);
      _users = await _adminRepository.getUsers();
    });
  }

  Future<void> addPriceEntry({
    required int commodityId,
    required int storeId,
    required double price,
  }) async {
    await _run(() async {
      await _adminRepository.addPriceEntry(
        commodityId: commodityId,
        storeId: storeId,
        price: price,
      );
      _priceEntries = await _adminRepository.getPriceEntries();
    });
  }

  Future<void> deletePriceEntry(int priceEntryId) async {
    await _run(() async {
      await _adminRepository.deletePriceEntry(priceEntryId);
      _priceEntries = await _adminRepository.getPriceEntries();
    });
  }

  Future<CsvImportResult> importPriceRows(
    List<Map<String, String>> rows, {
    CsvDuplicateStrategy strategy = CsvDuplicateStrategy.update,
  }) async {
    _isLoading = true;
    _error = null;
    _importProgress = 0;
    notifyListeners();
    var imported = 0;
    final errors = <String>[];
    try {
      _commodities = await _adminRepository.getCommodities();
      _stores = await _adminRepository.getStores();
      final commoditiesByName = {
        for (final item in _commodities) item.name.trim().toLowerCase(): item,
      };
      final storesByName = {
        for (final item in _stores) item.name.trim().toLowerCase(): item,
      };
      final validRows =
          <({int commodityId, int storeId, double price, String key})>[];
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        final commodityName = CsvImportService.value(row, [
          'Commodity',
          'CommodityName',
          'Product',
        ]);
        final storeName = CsvImportService.value(row, ['StoreName', 'Store']);
        final priceText = CsvImportService.value(row, [
          'PriceList',
          'Price',
          'CurrentPrice',
        ]).replaceAll(',', '');
        final commodity = commoditiesByName[commodityName.toLowerCase()];
        final store = storesByName[storeName.toLowerCase()];
        final price = double.tryParse(priceText);
        final rowNumber = index + 2;
        if (commodity == null) {
          errors.add('Row $rowNumber: unknown commodity "$commodityName".');
          continue;
        }
        if (store == null) {
          errors.add('Row $rowNumber: unknown store "$storeName".');
          continue;
        }
        if (price == null || price <= 0) {
          errors.add('Row $rowNumber: invalid PriceList "$priceText".');
          continue;
        }
        validRows.add((
          commodityId: commodity.id!,
          storeId: store.id!,
          price: price,
          key: '${commodity.name.toLowerCase()}|${store.name.toLowerCase()}',
        ));
      }
      _priceEntries = await _adminRepository.getPriceEntries();
      final existingKeys = {
        for (final entry in _priceEntries)
          '${entry.commodityName.toLowerCase()}|${entry.storeName.toLowerCase()}',
      };
      for (var index = 0; index < validRows.length; index++) {
        final item = validRows[index];
        final duplicate = existingKeys.contains(item.key);
        if (duplicate && strategy == CsvDuplicateStrategy.skip) {
          errors.add('Duplicate skipped: ${item.key.replaceAll('|', ' at ')}.');
          _updateImportProgress(index + 1, validRows.length);
          continue;
        }
        if (duplicate && strategy == CsvDuplicateStrategy.update) {
          await _adminRepository.updateLatestPriceEntry(
            commodityId: item.commodityId,
            storeId: item.storeId,
            price: item.price,
          );
        } else if (duplicate && strategy == CsvDuplicateStrategy.replace) {
          await _adminRepository.replacePriceEntries(
            commodityId: item.commodityId,
            storeId: item.storeId,
            price: item.price,
          );
        } else {
          await _adminRepository.addPriceEntry(
            commodityId: item.commodityId,
            storeId: item.storeId,
            price: item.price,
          );
          existingKeys.add(item.key);
        }
        imported++;
        _updateImportProgress(index + 1, validRows.length);
      }
      _priceEntries = await _adminRepository.getPriceEntries();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _importProgress = null;
      notifyListeners();
    }
    return CsvImportResult(
      imported: imported,
      skipped: rows.length - imported,
      errors: errors,
    );
  }

  Future<CsvImportResult> importStoreRows(
    List<Map<String, String>> rows, {
    CsvDuplicateStrategy strategy = CsvDuplicateStrategy.update,
  }) async {
    _isLoading = true;
    _error = null;
    _importProgress = 0;
    notifyListeners();
    var imported = 0;
    final errors = <String>[];
    try {
      _stores = await _adminRepository.getStores();
      final existingByName = {
        for (final item in _stores) item.name.trim().toLowerCase(): item,
      };
      final validRows =
          <
            ({
              String name,
              String ownerName,
              String marketName,
              String address,
              String city,
            })
          >[];
      for (var index = 0; index < rows.length; index++) {
        final row = rows[index];
        final name = CsvImportService.value(row, ['StoreName', 'Store']);
        final ownerName = CsvImportService.value(row, [
          'OwnerName',
          'Owner',
          'Proprietor',
        ]);
        final marketName = CsvImportService.value(row, [
          'MarketName',
          'Market',
        ]);
        final address = CsvImportService.value(row, ['Address']);
        final city = CsvImportService.value(row, ['City', 'Municipality']);
        final rowNumber = index + 2;
        if (name.isEmpty || address.isEmpty || city.isEmpty) {
          errors.add(
            'Row $rowNumber: StoreName, Address, and City are required.',
          );
          continue;
        }
        validRows.add((
          name: name,
          ownerName: ownerName,
          marketName: marketName.isEmpty ? name : marketName,
          address: address,
          city: city,
        ));
      }
      for (var index = 0; index < validRows.length; index++) {
        final item = validRows[index];
        final existing = existingByName[item.name.toLowerCase()];
        if (existing != null && strategy == CsvDuplicateStrategy.skip) {
          errors.add('Duplicate skipped: ${item.name}.');
          _updateImportProgress(index + 1, validRows.length);
          continue;
        }
        await _adminRepository.saveStore(
          id: existing?.id,
          name: item.name,
          ownerName:
              strategy == CsvDuplicateStrategy.update && item.ownerName.isEmpty
              ? existing?.ownerName ?? ''
              : item.ownerName,
          marketName: item.marketName,
          address: item.address,
          city: item.city,
        );
        imported++;
        _updateImportProgress(index + 1, validRows.length);
      }
      _stores = await _adminRepository.getStores();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      _isLoading = false;
      _importProgress = null;
      notifyListeners();
    }
    return CsvImportResult(
      imported: imported,
      skipped: rows.length - imported,
      errors: errors,
    );
  }

  Future<void> updateReportStatus({
    required int reportId,
    required String status,
  }) async {
    await _run(() async {
      await _adminRepository.updateReportStatus(
        reportId: reportId,
        status: status,
      );
      _reports = await _adminRepository.getReports();
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateImportProgress(int completed, int total) {
    _importProgress = total == 0 ? 1 : completed / total;
    notifyListeners();
  }
}
