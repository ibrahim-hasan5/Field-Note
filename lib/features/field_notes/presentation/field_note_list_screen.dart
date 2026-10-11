import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/field_note_bloc.dart';
import '../bloc/field_note_event.dart';
import '../bloc/field_note_state.dart';
import '../models/field_note_model.dart';
import 'field_note_detail_screen.dart';
import 'field_note_form_screen.dart';

class FieldNoteListScreen extends StatefulWidget {
  final String? siteId;
  final String? siteName;

  const FieldNoteListScreen({
    super.key,
    this.siteId,
    this.siteName,
  });

  @override
  State<FieldNoteListScreen> createState() => _FieldNoteListScreenState();
}

class _FieldNoteListScreenState extends State<FieldNoteListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus; // null means 'ALL'

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadNotes({bool refresh = false}) {
    context.read<FieldNoteBloc>().add(
          LoadFieldNotes(
            siteId: widget.siteId,
            status: _selectedStatus,
            searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
            refresh: refresh,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.siteName != null ? '${widget.siteName} - Notes' : 'Field Notes';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadNotes(refresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FieldNoteFormScreen(
                siteId: widget.siteId ?? '',
                siteName: widget.siteName,
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Note', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadNotes(),
                  decoration: InputDecoration(
                    hintText: 'Search notes by keyword...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _loadNotes();
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                // Status Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedStatus == null,
                        onSelected: () {
                          setState(() => _selectedStatus = null);
                          _loadNotes();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Draft',
                        isSelected: _selectedStatus == 'DRAFT',
                        onSelected: () {
                          setState(() => _selectedStatus = 'DRAFT');
                          _loadNotes();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'In Progress',
                        isSelected: _selectedStatus == 'IN_PROGRESS',
                        onSelected: () {
                          setState(() => _selectedStatus = 'IN_PROGRESS');
                          _loadNotes();
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Completed',
                        isSelected: _selectedStatus == 'COMPLETED',
                        onSelected: () {
                          setState(() => _selectedStatus = 'COMPLETED');
                          _loadNotes();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: BlocBuilder<FieldNoteBloc, FieldNoteState>(
              builder: (context, state) {
                if (state is FieldNoteLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is FieldNoteError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: AppColors.syncError),
                        const SizedBox(height: 12),
                        Text(state.message),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _loadNotes(refresh: true),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is FieldNoteLoaded) {
                  if (state.notes.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.note_alt_outlined,
                                size: 56,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No Field Notes Found',
                              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the button below to record your first field note inspection.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async => _loadNotes(refresh: true),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.notes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final note = state.notes[index];
                        return _NoteCard(note: note);
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary.withOpacity(0.18),
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        color: isSelected ? AppColors.primary : AppColors.lightTextSecondary,
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  final FieldNoteModel note;

  const _NoteCard({required this.note});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'COMPLETED':
        return AppColors.statusCompleted;
      case 'IN_PROGRESS':
        return AppColors.statusInProgress;
      default:
        return AppColors.statusDraft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(note.status);
    final isSynced = note.syncStatus == 'synced';
    final parsedDate = DateTime.tryParse(note.noteDate) ?? DateTime.now();
    final formattedDate = DateFormat('MMM dd, yyyy').format(parsedDate);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FieldNoteDetailScreen(note: note),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Date & Status Chip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.lightTextSecondary),
                      const SizedBox(width: 5),
                      Text(
                        formattedDate,
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Sync badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isSynced ? AppColors.syncSuccess : AppColors.syncPending)
                              .withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isSynced ? Icons.cloud_done : Icons.cloud_queue,
                          size: 13,
                          color: isSynced ? AppColors.syncSuccess : AppColors.syncPending,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          note.status,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Title & Site Info
              Text(
                note.title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (note.siteName != null || note.customerName != null) ...[
                const SizedBox(height: 3),
                Text(
                  '${note.siteName ?? ''}${note.customerName != null ? " • ${note.customerName}" : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Description snippet
              if (note.description != null && note.description!.isNotEmpty)
                Text(
                  note.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.lightTextSecondary,
                  ),
                ),

              // Bottom Badges: GPS & Photo indicator
              const SizedBox(height: 12),
              Row(
                children: [
                  if (note.latitude != null && note.longitude != null) ...[
                    const Icon(Icons.place, size: 14, color: AppColors.lightTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${note.latitude!.toStringAsFixed(3)}, ${note.longitude!.toStringAsFixed(3)}',
                      style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (note.photoPath != null || note.photoUrl != null) ...[
                    const Icon(Icons.photo_camera, size: 14, color: AppColors.lightTextSecondary),
                    const SizedBox(width: 4),
                    const Text(
                      'Photo attached',
                      style: TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
