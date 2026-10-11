import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final bool forceOfflineMode;
  final String defaultNoteStatus;
  final bool autoSyncEnabled;

  const SettingsState({
    this.isDarkMode = false,
    this.forceOfflineMode = false,
    this.defaultNoteStatus = 'DRAFT',
    this.autoSyncEnabled = true,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    bool? forceOfflineMode,
    String? defaultNoteStatus,
    bool? autoSyncEnabled,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      forceOfflineMode: forceOfflineMode ?? this.forceOfflineMode,
      defaultNoteStatus: defaultNoteStatus ?? this.defaultNoteStatus,
      autoSyncEnabled: autoSyncEnabled ?? this.autoSyncEnabled,
    );
  }

  @override
  List<Object?> get props => [
        isDarkMode,
        forceOfflineMode,
        defaultNoteStatus,
        autoSyncEnabled,
      ];
}
