import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class ToggleDarkMode extends SettingsEvent {
  final bool isDark;
  const ToggleDarkMode(this.isDark);

  @override
  List<Object?> get props => [isDark];
}

class ToggleOfflineMode extends SettingsEvent {
  final bool isOffline;
  const ToggleOfflineMode(this.isOffline);

  @override
  List<Object?> get props => [isOffline];
}

class ChangeDefaultStatus extends SettingsEvent {
  final String status;
  const ChangeDefaultStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class ToggleAutoSync extends SettingsEvent {
  final bool enabled;
  const ToggleAutoSync(this.enabled);

  @override
  List<Object?> get props => [enabled];
}
