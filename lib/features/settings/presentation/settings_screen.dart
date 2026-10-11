import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_event.dart';
import '../../auth/bloc/auth_state.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // User Profile Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        child: const Icon(Icons.person, size: 30, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName?.isNotEmpty == true
                                  ? user!.displayName!
                                  : 'Field Engineer',
                              style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? 'engineer@company.com',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Appearance
              Text(
                'Appearance & Theme',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('High contrast dark theme for field work'),
                      secondary: const Icon(Icons.dark_mode_outlined, color: AppColors.primary),
                      value: state.isDarkMode,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ToggleDarkMode(val));
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sync & Offline Options
              Text(
                'Data Sync & Offline Policy',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Auto-Sync in Background'),
                      subtitle: const Text('Automatically sync local records when connected'),
                      secondary: const Icon(Icons.sync, color: AppColors.primary),
                      value: state.autoSyncEnabled,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ToggleAutoSync(val));
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Force Offline Mode'),
                      subtitle: const Text('Simulate disconnected environment for testing'),
                      secondary: const Icon(Icons.signal_cellular_connected_no_internet_4_bar,
                          color: AppColors.accent),
                      value: state.forceOfflineMode,
                      onChanged: (val) {
                        context.read<SettingsBloc>().add(ToggleOfflineMode(val));
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.edit_attributes_outlined, color: AppColors.primary),
                      title: const Text('Default Note Status'),
                      subtitle: Text('Current: ${state.defaultNoteStatus}'),
                      trailing: DropdownButton<String>(
                        value: state.defaultNoteStatus,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT')),
                          DropdownMenuItem(value: 'IN_PROGRESS', child: Text('IN PROGRESS')),
                          DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            context.read<SettingsBloc>().add(ChangeDefaultStatus(val));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Logout Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.syncError,
                  side: const BorderSide(color: AppColors.syncError),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Log Out'),
                      content: const Text('Are you sure you want to log out? Local data will remain saved.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.syncError),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.read<AuthBloc>().add(AuthLogoutRequested());
                          },
                          child: const Text('Log Out'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ],
          );
        },
      ),
    );
  }
}
