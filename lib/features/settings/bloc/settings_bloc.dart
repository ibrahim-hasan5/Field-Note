import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/settings_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

  SettingsBloc({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository,
        super(SettingsState(
          isDarkMode: settingsRepository.isDarkMode(),
          forceOfflineMode: settingsRepository.isOfflineMode(),
          defaultNoteStatus: settingsRepository.getDefaultNoteStatus(),
          autoSyncEnabled: settingsRepository.isAutoSyncEnabled(),
        )) {
    on<LoadSettings>(_onLoadSettings);
    on<ToggleDarkMode>(_onToggleDarkMode);
    on<ToggleOfflineMode>(_onToggleOfflineMode);
    on<ChangeDefaultStatus>(_onChangeDefaultStatus);
    on<ToggleAutoSync>(_onToggleAutoSync);
  }

  void _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) {
    emit(state.copyWith(
      isDarkMode: _settingsRepository.isDarkMode(),
      forceOfflineMode: _settingsRepository.isOfflineMode(),
      defaultNoteStatus: _settingsRepository.getDefaultNoteStatus(),
      autoSyncEnabled: _settingsRepository.isAutoSyncEnabled(),
    ));
  }

  Future<void> _onToggleDarkMode(ToggleDarkMode event, Emitter<SettingsState> emit) async {
    await _settingsRepository.setDarkMode(event.isDark);
    emit(state.copyWith(isDarkMode: event.isDark));
  }

  Future<void> _onToggleOfflineMode(ToggleOfflineMode event, Emitter<SettingsState> emit) async {
    await _settingsRepository.setOfflineMode(event.isOffline);
    emit(state.copyWith(forceOfflineMode: event.isOffline));
  }

  Future<void> _onChangeDefaultStatus(ChangeDefaultStatus event, Emitter<SettingsState> emit) async {
    await _settingsRepository.setDefaultNoteStatus(event.status);
    emit(state.copyWith(defaultNoteStatus: event.status));
  }

  Future<void> _onToggleAutoSync(ToggleAutoSync event, Emitter<SettingsState> emit) async {
    await _settingsRepository.setAutoSyncEnabled(event.enabled);
    emit(state.copyWith(autoSyncEnabled: event.enabled));
  }
}
