import '../../../core/database/field_note_dao.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/field_note_model.dart';
import 'field_note_remote_data_source.dart';

class FieldNoteRepository {
  final FieldNoteDao _noteDao;
  final FieldNoteRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;

  FieldNoteRepository({
    required FieldNoteDao noteDao,
    required FieldNoteRemoteDataSource remoteDataSource,
    required ConnectivityService connectivityService,
  })  : _noteDao = noteDao,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService;

  Future<List<FieldNoteModel>> getNotes({
    String? siteId,
    String? status,
    String? searchQuery,
    bool refreshRemote = false,
  }) async {
    final localList = await _noteDao.getAllActiveNotes(
      siteId: siteId,
      status: status,
      searchQuery: searchQuery,
    );

    if (refreshRemote || localList.isEmpty) {
      final isOnline = await _connectivityService.isOnline;
      if (isOnline) {
        try {
          final remoteList = await _remoteDataSource.getNotes(
            siteId: siteId,
            status: status,
            query: searchQuery,
          );
          for (final note in remoteList) {
            await _noteDao.insertNote(note.copyWith(syncStatus: 'synced'));
          }
          return await _noteDao.getAllActiveNotes(
            siteId: siteId,
            status: status,
            searchQuery: searchQuery,
          );
        } catch (e) {
          // Local fallback
        }
      }
    }
    return localList;
  }

  Future<void> saveNote(FieldNoteModel note) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        final created = await _remoteDataSource.createNote(note);
        String? remotePhotoUrl;
        if (note.photoPath != null) {
          remotePhotoUrl = await _remoteDataSource.uploadPhoto(note.id, note.photoPath!);
        }
        await _noteDao.insertNote(
          created.copyWith(
            photoPath: note.photoPath,
            photoUrl: remotePhotoUrl ?? created.photoUrl,
            syncStatus: 'synced',
          ),
        );
        return;
      } catch (e) {
        // Fall back to offline
      }
    }
    await _noteDao.insertNote(note.copyWith(syncStatus: 'pending'));
  }

  Future<void> updateNote(FieldNoteModel note) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        final updated = await _remoteDataSource.updateNote(note);
        String? remotePhotoUrl = note.photoUrl;
        if (note.photoPath != null && remotePhotoUrl == null) {
          remotePhotoUrl = await _remoteDataSource.uploadPhoto(note.id, note.photoPath!);
        }
        await _noteDao.updateNote(
          updated.copyWith(
            photoPath: note.photoPath,
            photoUrl: remotePhotoUrl ?? updated.photoUrl,
            syncStatus: 'synced',
          ),
        );
        return;
      } catch (e) {
        // Fall back to offline
      }
    }
    await _noteDao.updateNote(note.copyWith(syncStatus: 'pending'));
  }

  Future<void> deleteNote(String id) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        await _remoteDataSource.deleteNote(id);
      } catch (e) {
        // Fall back to offline
      }
    }
    await _noteDao.softDeleteNote(id);
  }
}
