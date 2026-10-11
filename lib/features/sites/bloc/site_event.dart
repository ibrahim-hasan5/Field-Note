import 'package:equatable/equatable.dart';
import '../models/site_model.dart';

abstract class SiteEvent extends Equatable {
  const SiteEvent();

  @override
  List<Object?> get props => [];
}

class LoadSites extends SiteEvent {
  final String? customerId;
  final bool refresh;

  const LoadSites({this.customerId, this.refresh = false});

  @override
  List<Object?> get props => [customerId, refresh];
}

class AddSite extends SiteEvent {
  final SiteModel site;
  const AddSite(this.site);

  @override
  List<Object?> get props => [site];
}

class UpdateSite extends SiteEvent {
  final SiteModel site;
  const UpdateSite(this.site);

  @override
  List<Object?> get props => [site];
}

class DeleteSite extends SiteEvent {
  final String id;
  final String? customerId;

  const DeleteSite(this.id, {this.customerId});

  @override
  List<Object?> get props => [id, customerId];
}
