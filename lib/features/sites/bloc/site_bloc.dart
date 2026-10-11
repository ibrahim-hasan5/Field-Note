import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/site_repository.dart';
import 'site_event.dart';
import 'site_state.dart';

class SiteBloc extends Bloc<SiteEvent, SiteState> {
  final SiteRepository _siteRepository;

  SiteBloc({required SiteRepository siteRepository})
      : _siteRepository = siteRepository,
        super(SiteInitial()) {
    on<LoadSites>(_onLoadSites);
    on<AddSite>(_onAddSite);
    on<UpdateSite>(_onUpdateSite);
    on<DeleteSite>(_onDeleteSite);
  }

  Future<void> _onLoadSites(
    LoadSites event,
    Emitter<SiteState> emit,
  ) async {
    emit(SiteLoading());
    try {
      final sites = await _siteRepository.getSites(
        customerId: event.customerId,
        refreshRemote: event.refresh,
      );
      emit(SiteLoaded(sites));
    } catch (e) {
      emit(SiteError(e.toString()));
    }
  }

  Future<void> _onAddSite(
    AddSite event,
    Emitter<SiteState> emit,
  ) async {
    try {
      await _siteRepository.saveSite(event.site);
      add(LoadSites(customerId: event.site.customerId, refresh: false));
    } catch (e) {
      emit(SiteError(e.toString()));
    }
  }

  Future<void> _onUpdateSite(
    UpdateSite event,
    Emitter<SiteState> emit,
  ) async {
    try {
      await _siteRepository.updateSite(event.site);
      add(LoadSites(customerId: event.site.customerId, refresh: false));
    } catch (e) {
      emit(SiteError(e.toString()));
    }
  }

  Future<void> _onDeleteSite(
    DeleteSite event,
    Emitter<SiteState> emit,
  ) async {
    try {
      await _siteRepository.deleteSite(event.id);
      add(LoadSites(customerId: event.customerId, refresh: false));
    } catch (e) {
      emit(SiteError(e.toString()));
    }
  }
}
