import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../customers/bloc/customer_bloc.dart';
import '../../customers/bloc/customer_event.dart';
import '../../customers/presentation/customer_list_screen.dart';
import '../../field_notes/bloc/field_note_bloc.dart';
import '../../field_notes/bloc/field_note_event.dart';
import '../../field_notes/presentation/field_note_list_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../sites/bloc/site_bloc.dart';
import '../../sites/bloc/site_event.dart';
import '../../sites/presentation/site_list_screen.dart';

class HomeNavScreen extends StatefulWidget {
  const HomeNavScreen({super.key});

  @override
  State<HomeNavScreen> createState() => _HomeNavScreenState();
}

class _HomeNavScreenState extends State<HomeNavScreen> {
  int _currentIndex = 0;
  bool _isOnline = true;
  bool _isSyncing = false;

  final _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  void _initConnectivity() async {
    final online = await _connectivityService.isOnline;
    if (mounted) setState(() => _isOnline = online);

    _connectivityService.isOnlineStream.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);
        if (online) {
          _triggerSync();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    // Refresh all three blocs
    context.read<CustomerBloc>().add(const LoadCustomers(refresh: true));
    context.read<SiteBloc>().add(const LoadSites(refresh: true));
    context.read<FieldNoteBloc>().add(const LoadFieldNotes(refresh: true));

    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Synchronization complete!'),
          backgroundColor: AppColors.syncSuccess,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  final List<Widget> _screens = const [
    FieldNoteListScreen(),
    SiteListScreen(),
    CustomerListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 10),
            Text(
              'Field Note',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          // Online/Offline status indicator badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: (_isOnline ? AppColors.syncSuccess : AppColors.syncPending).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: _isOnline ? AppColors.syncSuccess : AppColors.syncPending,
                ),
                const SizedBox(width: 6),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? AppColors.syncSuccess : AppColors.syncPending,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Manual sync button
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sync now',
            onPressed: _isSyncing ? null : _triggerSync,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt, color: AppColors.primary),
            label: 'Notes',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_city_outlined),
            selectedIcon: Icon(Icons.location_city, color: AppColors.primary),
            label: 'Sites',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people, color: AppColors.primary),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppColors.primary),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
