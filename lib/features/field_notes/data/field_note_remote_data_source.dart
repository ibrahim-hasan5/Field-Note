import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/field_note_model.dart';

class FieldNoteRemoteDataSource {
  final ApiClient _apiClient;

  FieldNoteRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<FieldNoteModel>> getNotes({
    String? siteId,
    String? status,
    String? query,
  }) async {
    final queryParams = <String, dynamic>{};
    if (siteId != null) queryParams['siteId'] = siteId;
    if (status != null) queryParams['status'] = status;
    if (query != null && query.isNotEmpty) queryParams['q'] = query;

    final response = await _apiClient.dio.get(
      ApiConstants.notes,
      queryParameters: queryParams,
    );

    final data = response.data;
    List list = [];
    if (data is Map && data.containsKey('content')) {
      list = data['content'] as List;
    } else if (data is List) {
      list = data;
    }
    return list
        .map((item) => FieldNoteModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FieldNoteModel> createNote(FieldNoteModel note) async {
    final response = await _apiClient.dio.post(
      ApiConstants.notes,
      data: note.toJson(),
    );
    return FieldNoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FieldNoteModel> updateNote(FieldNoteModel note) async {
    final response = await _apiClient.dio.put(
      '${ApiConstants.notes}/${note.id}',
      data: note.toJson(),
    );
    return FieldNoteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteNote(String id) async {
    await _apiClient.dio.delete('${ApiConstants.notes}/$id');
  }

  Future<String?> uploadPhoto(String noteId, String localPath) async {
    final file = File(localPath);
    if (!await file.exists()) return null;

    final fileName = localPath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(localPath, filename: fileName),
    });

    final response = await _apiClient.dio.post(
      '${ApiConstants.notes}/$noteId/photo',
      data: formData,
    );

    if (response.statusCode == 200) {
      return response.data['photoUrl'] as String?;
    }
    return null;
  }
}
