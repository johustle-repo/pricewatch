import 'package:flutter/foundation.dart';

import '../../../../shared/models/ui_models.dart';
import '../../data/report_repository.dart';

class ReportController extends ChangeNotifier {
  ReportController({required ReportRepository reportRepository})
    : _reportRepository = reportRepository;

  final ReportRepository _reportRepository;

  List<ReportViewData> _reports = [];
  ReportViewData? _detail;
  bool _isLoading = false;
  String? _error;

  List<ReportViewData> get reports => _reports;
  ReportViewData? get detail => _detail;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUserReports(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _reportRepository.getUserReports(userId);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStoreReports(int storeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _reports = await _reportRepository.getStoreReports(storeId);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadReport(int reportId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _detail = await _reportRepository.getReportDetail(reportId);
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateReportStatus({
    required int reportId,
    required String status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _reportRepository.updateReportStatus(
        reportId: reportId,
        status: status,
      );
      await loadReport(reportId);
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitReport({
    required int userId,
    required int commodityId,
    required int storeId,
    required double observedPrice,
    required double srpSnapshot,
    required String reason,
    String? photoPath,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _reportRepository.submitReport(
        userId: userId,
        commodityId: commodityId,
        storeId: storeId,
        observedPrice: observedPrice,
        srpSnapshot: srpSnapshot,
        reason: reason,
        photoPath: photoPath,
      );
      await loadUserReports(userId);
      return true;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
