import 'package:equatable/equatable.dart';

class CustomerModel extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final String syncStatus; // pending, synced, error

  const CustomerModel({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.syncStatus = 'pending',
  });

  CustomerModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    String? syncStatus,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
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
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'sync_status': syncStatus,
    };
  }

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      address: map['address'] as String?,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
      deletedAt: map['deleted_at'] as String?,
      syncStatus: (map['sync_status'] as String?) ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
    };
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
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
        name,
        phone,
        email,
        address,
        createdAt,
        updatedAt,
        deletedAt,
        syncStatus,
      ];
}
