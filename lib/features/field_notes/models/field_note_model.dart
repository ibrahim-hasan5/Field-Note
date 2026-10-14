import 'package:equatable/equatable.dart';
import '../../../core/database/sqlite_compat.dart';

class FieldNoteModel extends Equatable {
  final String id;
  final String siteId;
  final String? siteName;
  final String? customerName;
  final String title;
  final String? description;
  final double? latitude;
  final double? longitude;
  final String noteDate;
  final String status; // DRAFT, IN_PROGRESS, COMPLETED
  final String? photoPath; // Local path
  final String? photoUrl;  // Remote URL
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus; // pending, synced, error

  const FieldNoteModel({
    required this.id,
    required this.siteId,
    this.siteName,
    this.customerName,
    required this.title,
    this.description,
    this.latitude,
    this.longitude,
    required this.noteDate,
    this.status = 'DRAFT',
    this.photoPath,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  FieldNoteModel copyWith({
    String? id,
    String? siteId,
    String? siteName,
    String? customerName,
    String? title,
    String? description,
    double? latitude,
    double? longitude,
    String? noteDate,
    String? status,
    String? photoPath,
    String? photoUrl,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return FieldNoteModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      siteName: siteName ?? this.siteName,
      customerName: customerName ?? this.customerName,
      title: title ?? this.title,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      noteDate: noteDate ?? this.noteDate,
      status: status ?? this.status,
      photoPath: photoPath ?? this.photoPath,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'site_id': siteId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'note_date': noteDate,
      'status': status,
      'photo_path': photoPath,
      'photo_url': photoUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory FieldNoteModel.fromMap(Map<String, dynamic> map) {
    return FieldNoteModel(
      id: sqliteRequiredString(map['id']),
      siteId: sqliteRequiredString(map['site_id']),
      siteName: sqliteString(map['site_name']),
      customerName: sqliteString(map['customer_name']),
      title: sqliteRequiredString(map['title']),
      description: sqliteString(map['description']),
      latitude: sqliteDouble(map['latitude']),
      longitude: sqliteDouble(map['longitude']),
      noteDate: sqliteRequiredString(map['note_date']),
      status: sqliteString(map['status']) ?? 'DRAFT',
      photoPath: sqliteString(map['photo_path']),
      photoUrl: sqliteString(map['photo_url']),
      createdAt: sqliteRequiredString(map['created_at']),
      updatedAt: sqliteRequiredString(map['updated_at']),
      deletedAt: sqliteString(map['deleted_at']),
      syncStatus: sqliteString(map['sync_status']) ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'siteId': siteId,
      'title': title,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'noteDate': noteDate,
      'status': status,
      'photoUrl': photoUrl,
    };
  }

  factory FieldNoteModel.fromJson(Map<String, dynamic> json) {
    return FieldNoteModel(
      id: json['id'] as String,
      siteId: json['siteId'] as String,
      siteName: json['siteName'] as String?,
      customerName: json['customerName'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      noteDate: (json['noteDate'] ?? DateTime.now().toIso8601String()) as String,
      status: (json['status'] as String?) ?? 'DRAFT',
      photoUrl: json['photoUrl'] as String?,
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()) as String,
      updatedAt: (json['updatedAt'] ?? DateTime.now().toIso8601String()) as String,
      deletedAt: json['deletedAt'] as String?,
      syncStatus: 'synced',
    );
  }

  @override
  List<Object?> get props => [
        id,
        siteId,
        siteName,
        customerName,
        title,
        description,
        latitude,
        longitude,
        noteDate,
        status,
        photoPath,
        photoUrl,
        createdAt,
        updatedAt,
        deletedAt,
        syncStatus,
      ];
}
