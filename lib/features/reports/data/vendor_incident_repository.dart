import '../../../core/database/cloud_data_service.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/vendor_incident_model.dart';

class VendorIncidentRepository {
  VendorIncidentRepository({required CloudDataService cloudDataService})
    : _cloudDataService = cloudDataService;

  final CloudDataService _cloudDataService;

  Future<void> submit({
    required int userId,
    required String reportedVendorName,
    required String marketLocation,
    required String reasonCode,
    required String details,
    required List<String> evidencePhotos,
  }) async {
    final cleanDetails = details.trim();
    final cleanVendorName = reportedVendorName.trim();
    final cleanLocation = marketLocation.trim();
    if (cleanVendorName.length < 2) {
      throw Exception('Enter the name, alias, or description of the vendor.');
    }
    if (cleanLocation.length < 5) {
      throw Exception('Enter where the unregistered vendor can be found.');
    }
    if (cleanDetails.length < 20) {
      throw Exception(
        'Please provide at least 20 characters of incident details.',
      );
    }
    if (evidencePhotos.isEmpty || evidencePhotos.length > 3) {
      throw Exception('Attach between one and three evidence photos.');
    }
    final now = DateTimeUtils.nowIso();
    final id = _cloudDataService.generateId();
    await _cloudDataService.setDocument('vendor_incidents', id, {
      'id': id,
      'user_id': userId,
      'reported_vendor_name': cleanVendorName,
      'market_location': cleanLocation,
      'reason_code': reasonCode,
      'details': cleanDetails,
      'evidence_photos': evidencePhotos,
      'status': 'pending',
      'created_at': now,
      'updated_at': now,
    });
    final notificationId = _cloudDataService.generateId();
    await _cloudDataService.setDocument('notifications', notificationId, {
      'id': notificationId,
      'user_id': userId,
      'title': 'Vendor incident submitted',
      'body':
          'Your vendor incident was sent securely for administrator review.',
      'type': 'incident_update',
      'is_read': 0,
      'created_at': now,
    });
  }

  Future<List<VendorIncidentViewData>> getForUser(int userId) async =>
      _load(userId: userId);

  Future<List<VendorIncidentViewData>> getAll() => _load();

  Future<void> delete(int id) async {
    final row = await _cloudDataService.getDocument('vendor_incidents', id);
    if (row == null) throw Exception('Incident not found.');
    await _cloudDataService.deleteDocument('vendor_incidents', id);
  }

  Future<void> updateStatus({required int id, required String status}) async {
    if (!const {
      'pending',
      'under_review',
      'resolved',
      'dismissed',
    }.contains(status)) {
      throw Exception('Unsupported incident status.');
    }
    final row = await _cloudDataService.getDocument('vendor_incidents', id);
    if (row == null) throw Exception('Incident not found.');
    final incident = VendorIncidentModel.fromMap(row);
    final now = DateTimeUtils.nowIso();
    await _cloudDataService.setDocument('vendor_incidents', id, {
      ...incident.toMap(),
      'status': status,
      'updated_at': now,
    });
    final notificationId = _cloudDataService.generateId();
    await _cloudDataService.setDocument('notifications', notificationId, {
      'id': notificationId,
      'user_id': incident.userId,
      'title': 'Vendor incident updated',
      'body': 'Your vendor incident is now ${status.replaceAll('_', ' ')}.',
      'type': 'incident_update',
      'is_read': 0,
      'created_at': now,
    });
  }

  Future<List<VendorIncidentViewData>> _load({int? userId}) async {
    final rows = userId == null
        ? await _cloudDataService.getCollection('vendor_incidents')
        : await _cloudDataService.getCollectionWhere(
            'vendor_incidents',
            field: 'user_id',
            value: userId,
          );
    final incidents = rows.map(VendorIncidentModel.fromMap).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final users = userId == null
        ? (await _cloudDataService.getCollection(
            'users',
          )).map(UserModel.fromMap).toList()
        : const <UserModel>[];
    return incidents
        .map((incident) {
          final reporter = users
              .where((item) => item.id == incident.userId)
              .firstOrNull;
          return VendorIncidentViewData(
            incident: incident,
            reporterName: reporter?.fullName ?? 'Community member',
          );
        })
        .toList(growable: false);
  }
}
