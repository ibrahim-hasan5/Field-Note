import 'package:equatable/equatable.dart';
import '../../../core/database/sqlite_compat.dart';

class SiteModel extends Equatable {
  final String id;
  final String customerId;
  final String? customerName;
  final String name;
  final String? address;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus;

  const SiteModel({
    required this.id,
    required this.customerId,
    this.customerName,
    required this.name,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  SiteModel copyWith({
    String? id,
    String? customerId,
    String? customerName,
    String? name,
    String? address,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return SiteModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'name': name,
      'address': address,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory SiteModel.fromMap(Map<String, dynamic> map) {
    return SiteModel(
      id: sqliteRequiredString(map['id']),
      customerId: sqliteRequiredString(map['customer_id']),
      customerName: sqliteString(map['customer_name']),
      name: sqliteRequiredString(map['name']),
      address: sqliteString(map['address']),
      createdAt: sqliteRequiredString(map['created_at']),
      updatedAt: sqliteRequiredString(map['updated_at']),
      deletedAt: sqliteString(map['deleted_at']),
      syncStatus: sqliteString(map['sync_status']) ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'name': name,
      'address': address,
    };
  }

  factory SiteModel.fromJson(Map<String, dynamic> json) {
    return SiteModel(
      id: json['id'] as String,
      customerId: json['customerId'] as String,
      customerName: json['customerName'] as String?,
      name: json['name'] as String,
      address: json['address'] as String?,
      createdAt: (json['createdAt'] ?? DateTime.now().toIso8601String()) as String,
      updatedAt: (json['updatedAt'] ?? DateTime.now().toIso8601String()) as String,
      deletedAt: json['deletedAt'] as String?,
      syncStatus: 'synced',
    );
  }

  @override
  List<Object?> get props => [
        id,
        customerId,
        customerName,
        name,
        address,
        createdAt,
        updatedAt,
        deletedAt,
        syncStatus,
      ];
}
