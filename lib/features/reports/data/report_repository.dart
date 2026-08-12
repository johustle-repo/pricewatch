import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/models/commodity_model.dart';
import '../../../shared/models/report_model.dart';
import '../../../shared/models/store_model.dart';
import '../../../shared/models/ui_models.dart';

class ReportRepository {
  ReportRepository({required CloudDataService cloudDataService})
    : _cloudDataService = cloudDataService;

  final CloudDataService _cloudDataService;

  Future<void> submitReport({
    required int userId,
    required int commodityId,
    required int storeId,
    required double observedPrice,
    required double srpSnapshot,
    required String reason,
    String? photoPath,
  }) async {
    final now = DateTimeUtils.nowIso();
    final id = _cloudDataService.generateId();
    await _cloudDataService.setDocument('reports', id, {
      'id': id,
      'user_id': userId,
      'commodity_id': commodityId,
      'store_id': storeId,
      'observed_price': observedPrice,
      'srp_snapshot': srpSnapshot,
      'reason': reason.trim(),
      'photo_path': photoPath?.trim().isEmpty == true ? null : photoPath,
      'status': 'pending',
      'created_at': now,
      'updated_at': now,
    });

    final notificationId = _cloudDataService.generateId();
    await _cloudDataService.setDocument('notifications', notificationId, {
      'id': notificationId,
      'user_id': userId,
      'title': 'Report submitted',
      'body': 'Your overpricing report has been saved for review.',
      'type': 'system',
      'is_read': 0,
      'created_at': now,
    });
  }

  Future<List<ReportViewData>> getUserReports(int userId) async {
    return _loadReportViews(userId: userId);
  }

  Future<List<ReportViewData>> getStoreReports(int storeId) async {
    return _loadReportViews(storeId: storeId);
  }

  Future<List<ReportViewData>> getAllReports() async => _loadReportViews();

  Future<ReportViewData> getReportDetail(int reportId) async {
    final report = await getRawReport(reportId);
    final commodityRow = await _cloudDataService.getDocument(
      'commodities',
      report.commodityId,
    );
    final storeRow = await _cloudDataService.getDocument(
      'stores',
      report.storeId,
    );
    return _toView(
      report,
      commodityRow == null ? null : CommodityModel.fromMap(commodityRow).name,
      storeRow == null ? null : StoreModel.fromMap(storeRow).name,
    );
  }

  Future<ReportModel> getRawReport(int reportId) async {
    final row = await _cloudDataService.getDocument('reports', reportId);
    if (row == null) {
      throw Exception('Report not found.');
    }
    return ReportModel.fromMap(row);
  }

  Future<void> updateReportStatus({
    required int reportId,
    required String status,
  }) async {
    final report = await getRawReport(reportId);
    await _cloudDataService.setDocument('reports', reportId, {
      ...report.toMap(),
      'status': status,
      'updated_at': DateTimeUtils.nowIso(),
    });

    final notificationId = _cloudDataService.generateId();
    await _cloudDataService.setDocument('notifications', notificationId, {
      'id': notificationId,
      'user_id': report.userId,
      'title': 'Report status updated',
      'body': 'Your report is now marked as $status.',
      'type': 'report_status_update',
      'is_read': 0,
      'created_at': DateTimeUtils.nowIso(),
    });
  }

  Future<List<ReportViewData>> _loadReportViews({
    int? userId,
    int? storeId,
  }) async {
    final reportRows = userId != null
        ? await _cloudDataService.getCollectionWhere(
            'reports',
            field: 'user_id',
            value: userId,
          )
        : storeId != null
        ? await _cloudDataService.getCollectionWhere(
            'reports',
            field: 'store_id',
            value: storeId,
          )
        : await _cloudDataService.getCollection('reports');
    final reports =
        reportRows
            .map(ReportModel.fromMap)
            .where((item) => userId == null || item.userId == userId)
            .where((item) => storeId == null || item.storeId == storeId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final commodities = (await _cloudDataService.getCollection(
      'commodities',
    )).map(CommodityModel.fromMap).toList();
    final stores = (await _cloudDataService.getCollection(
      'stores',
    )).map(StoreModel.fromMap).where((item) => !item.isArchived).toList();

    return reports
        .map((report) {
          final reportId = report.id;
          if (reportId == null) {
            return null;
          }
          final commodity = commodities
              .where((item) => item.id == report.commodityId)
              .firstOrNull;
          final store = stores
              .where((item) => item.id == report.storeId)
              .firstOrNull;
          return _toView(report, commodity?.name, store?.name);
        })
        .nonNulls
        .toList();
  }

  ReportViewData _toView(
    ReportModel report,
    String? commodityName,
    String? storeName,
  ) {
    final reportId = report.id;
    if (reportId == null) throw Exception('Report not found.');
    return ReportViewData(
      reportId: reportId,
      commodityName: commodityName ?? 'Unknown commodity',
      storeName: storeName ?? 'Unknown store',
      userName: 'Community member',
      observedPrice: report.observedPrice,
      srpSnapshot: report.srpSnapshot,
      reason: report.reason,
      photoPath: report.photoPath,
      status: report.status,
      createdAt: report.createdAt,
      updatedAt: report.updatedAt,
    );
  }
}
