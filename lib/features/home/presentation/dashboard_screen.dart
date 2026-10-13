import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../customers/bloc/customer_bloc.dart';
import '../../customers/bloc/customer_event.dart';
import '../../customers/bloc/customer_state.dart';
import '../../customers/presentation/customer_list_screen.dart';
import '../../field_notes/bloc/field_note_bloc.dart';
import '../../field_notes/bloc/field_note_event.dart';
import '../../field_notes/bloc/field_note_state.dart';
import '../../field_notes/models/field_note_model.dart';
import '../../field_notes/presentation/field_note_detail_screen.dart';
import '../../field_notes/presentation/field_note_form_screen.dart';
import '../../sites/bloc/site_bloc.dart';
import '../../sites/bloc/site_event.dart';
import '../../sites/bloc/site_state.dart';
import '../../sites/presentation/site_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    // Load all blocs
    context.read<CustomerBloc>().add(const LoadCustomers());
    context.read<SiteBloc>().add(const LoadSites());
    context.read<FieldNoteBloc>().add(const LoadFieldNotes());

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is Authenticated ? authState.user : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: FadeTransition(
        opacity: _fadeIn,
        child: CustomScrollView(
          slivers: [
            // ── Hero AppBar ─────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.edit_note_rounded,
                                    color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Field Note',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Good ${_greeting()}, ${user?.displayName?.split(' ').first ?? 'Engineer'} 👋',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.92),
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            DateFormat('EEEE, MMMM d yyyy').format(DateTime.now()),
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stat Cards Row
                  _StatsRow(isDark: isDark),
                  const SizedBox(height: 24),

                  // Quick Actions
                  _SectionTitle(title: 'Quick Actions', isDark: isDark),
                  const SizedBox(height: 12),
                  _QuickActions(),
                  const SizedBox(height: 24),

                  // Recent Field Notes
                  _SectionTitle(title: 'Recent Notes', isDark: isDark),
                  const SizedBox(height: 12),
                  _RecentNotes(),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

/* ── Section Title ─────────────────────────────────────────────────────────── */

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }
}

/* ── Stats Row ─────────────────────────────────────────────────────────────── */

class _StatsRow extends StatelessWidget {
  final bool isDark;
  const _StatsRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FieldNoteBloc, FieldNoteState>(
      builder: (context, noteState) {
        return BlocBuilder<CustomerBloc, CustomerState>(
          builder: (context, customerState) {
            return BlocBuilder<SiteBloc, SiteState>(
              builder: (context, siteState) {
                final notes = noteState is FieldNoteLoaded ? noteState.notes : <FieldNoteModel>[];
                final totalNotes = notes.length;
                final pendingSync = notes.where((n) => n.syncStatus == 'pending').length;
                final completedNotes = notes.where((n) => n.status == 'COMPLETED').length;
                final totalCustomers = customerState is CustomerLoaded ? customerState.customers.length : 0;
                final totalSites = siteState is SiteLoaded ? siteState.sites.length : 0;

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.note_alt_rounded,
                            label: 'Total Notes',
                            value: '$totalNotes',
                            color: AppColors.primary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.check_circle_rounded,
                            label: 'Completed',
                            value: '$completedNotes',
                            color: AppColors.statusCompleted,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.location_city_rounded,
                            label: 'Sites',
                            value: '$totalSites',
                            color: AppColors.secondary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            icon: pendingSync > 0
                                ? Icons.cloud_upload_rounded
                                : Icons.cloud_done_rounded,
                            label: pendingSync > 0 ? 'Pending Sync' : 'All Synced',
                            value: pendingSync > 0 ? '$pendingSync' : '✓',
                            color: pendingSync > 0
                                ? AppColors.syncPending
                                : AppColors.syncSuccess,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    if (totalCustomers > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: _StatCard(
                          icon: Icons.people_rounded,
                          label: 'Customers',
                          value: '$totalCustomers',
                          color: AppColors.accent,
                          isDark: isDark,
                          fullWidth: true,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;
  final bool fullWidth;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: fullWidth
          ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    Text(
                      value,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
    );
  }
}

/* ── Quick Actions ─────────────────────────────────────────────────────────── */

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.note_add_rounded,
            label: 'New Note',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<FieldNoteBloc>(),
                    child: const FieldNoteFormScreen(siteId: ''),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.location_city_rounded,
            label: 'All Sites',
            color: AppColors.secondary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<SiteBloc>()),
                      BlocProvider.value(value: context.read<FieldNoteBloc>()),
                    ],
                    child: const SiteListScreen(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.people_rounded,
            label: 'Clients',
            color: AppColors.accent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<CustomerBloc>()),
                      BlocProvider.value(value: context.read<SiteBloc>()),
                    ],
                    child: const CustomerListScreen(),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ── Recent Notes ──────────────────────────────────────────────────────────── */

class _RecentNotes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<FieldNoteBloc, FieldNoteState>(
      builder: (context, state) {
        if (state is FieldNoteLoading) {
          return const Center(
              child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ));
        }

        if (state is FieldNoteLoaded) {
          final recent = state.notes.take(5).toList();
          if (recent.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.note_alt_outlined,
                      size: 40,
                      color: AppColors.primary.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text(
                    'No notes yet',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: recent.map((note) => _RecentNoteCard(note: note, isDark: isDark)).toList(),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _RecentNoteCard extends StatelessWidget {
  final FieldNoteModel note;
  final bool isDark;

  const _RecentNoteCard({required this.note, required this.isDark});

  Color _statusColor(String s) {
    switch (s) {
      case 'COMPLETED': return AppColors.statusCompleted;
      case 'IN_PROGRESS': return AppColors.statusInProgress;
      default: return AppColors.statusDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(note.status);
    final parsedDate = DateTime.tryParse(note.noteDate) ?? DateTime.now();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<FieldNoteBloc>(),
                  child: FieldNoteDetailScreen(note: note),
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              children: [
                // Left colored accent bar
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${note.siteName ?? 'Unknown Site'} • ${DateFormat('MMM dd').format(parsedDate)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    note.status == 'IN_PROGRESS' ? 'WIP' : note.status,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
