import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/database/customer_dao.dart';
import '../../../core/database/field_note_dao.dart';
import '../../../core/database/site_dao.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../features/customers/models/customer_model.dart';
import '../../../features/field_notes/data/field_note_remote_data_source.dart';
import '../../../features/field_notes/models/field_note_model.dart';
import '../../../features/sites/models/site_model.dart';

/// Handles the bidirectional sync between the local SQLite database and the
/// Spring Boot backend.
///
/// Push flow:
///   1. Read all pending records from local DAOs.
///   2. POST them to /api/sync/push in a single batch.
///   3. On success, mark each record as 'synced' locally.
///   4. Also upload pending photos for notes.
///
/// Pull flow:
///   Delegates entirely to existing repository methods.
class SyncEngine {
  final ApiClient _apiClient;
  final ConnectivityService _connectivityService;
  final CustomerDao _customerDao;
  final SiteDao _siteDao;
  final FieldNoteDao _noteDao;
  final FieldNoteRemoteDataSource _noteRemoteSource;

  SyncEngine({
    required ApiClient apiClient,
    required ConnectivityService connectivityService,
    required CustomerDao customerDao,
    required SiteDao siteDao,
    required FieldNoteDao noteDao,
    required FieldNoteRemoteDataSource noteRemoteSource,
  })  : _apiClient = apiClient,
        _connectivityService = connectivityService,
        _customerDao = customerDao,
        _siteDao = siteDao,
        _noteDao = noteDao,
        _noteRemoteSource = noteRemoteSource;

  /// Run a full push sync cycle.
  /// Returns a [SyncResult] describing what was synced.
  Future<SyncResult> pushPending() async {
    final isOnline = await _connectivityService.isOnline;
    if (!isOnline) {
      return SyncResult(
        success: false,
        message: 'Device is offline — sync skipped',
      );
    }

    try {
      final pendingCustomers = await _customerDao.getPendingSyncCustomers();
      final pendingSites = await _siteDao.getPendingSyncSites();
      final pendingNotes = await _noteDao.getPendingSyncNotes();

      // Nothing to push
      if (pendingCustomers.isEmpty && pendingSites.isEmpty && pendingNotes.isEmpty) {
        return SyncResult(success: true, message: 'Everything is up to date');
      }

      // Build the push payload
      final payload = _buildPushPayload(pendingCustomers, pendingSites, pendingNotes);

      // POST to /api/sync/push
      final response = await _apiClient.dio.post(
        ApiConstants.syncPush,
        data: payload,
      );

      if (response.statusCode == 200) {
        // Mark all pushed records as synced locally
        for (final c in pendingCustomers) {
          await _customerDao.markSynced(c.id);
        }
        for (final s in pendingSites) {
          await _siteDao.markSynced(s.id);
        }
        for (final n in pendingNotes) {
          // Also upload any pending photo before marking synced
          String? photoUrl;
          if (n.photoPath != null && n.photoUrl == null) {
            try {
              photoUrl = await _noteRemoteSource.uploadPhoto(n.id, n.photoPath!);
            } catch (_) {
              // Photo upload failed — note is still marked synced, photo retried next time
            }
          }
          await _noteDao.markSynced(n.id, photoUrl: photoUrl);
        }

        final total = pendingCustomers.length + pendingSites.length + pendingNotes.length;
        return SyncResult(
          success: true,
          customersUpserted: pendingCustomers.length,
          sitesUpserted: pendingSites.length,
          notesUpserted: pendingNotes.length,
          message: 'Synced $total record${total == 1 ? '' : 's'} to the server',
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Server returned ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return SyncResult(
        success: false,
        message: 'Network error: ${e.message}',
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Sync failed: ${e.toString()}',
      );
    }
  }

  Map<String, dynamic> _buildPushPayload(
    List<CustomerModel> customers,
    List<SiteModel> sites,
    List<FieldNoteModel> notes,
  ) {
    return {
      'customers': customers
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'phone': c.phone,
                'email': c.email,
                'address': c.address,
                'deletedAt': c.deletedAt,
              })
          .toList(),
      'sites': sites
          .map((s) => {
                'id': s.id,
                'customerId': s.customerId,
                'name': s.name,
                'address': s.address,
                'deletedAt': s.deletedAt,
              })
          .toList(),
      'notes': notes
          .map((n) => {
                'id': n.id,
                'siteId': n.siteId,
                'title': n.title,
                'description': n.description,
                'latitude': n.latitude,
                'longitude': n.longitude,
                'noteDate': n.noteDate,
                'status': n.status,
                'deletedAt': n.deletedAt,
              })
          .toList(),
    };
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int customersUpserted;
  final int sitesUpserted;
  final int notesUpserted;

  SyncResult({
    required this.success,
    required this.message,
    this.customersUpserted = 0,
    this.sitesUpserted = 0,
    this.notesUpserted = 0,
  });

  int get totalSynced => customersUpserted + sitesUpserted + notesUpserted;
}
