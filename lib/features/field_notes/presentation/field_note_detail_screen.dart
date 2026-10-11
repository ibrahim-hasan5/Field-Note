import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/field_note_bloc.dart';
import '../bloc/field_note_event.dart';
import '../models/field_note_model.dart';
import 'field_note_form_screen.dart';

class FieldNoteDetailScreen extends StatelessWidget {
  final FieldNoteModel note;

  const FieldNoteDetailScreen({super.key, required this.note});

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
    final parsedDate = DateTime.tryParse(note.noteDate) ?? DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM dd, yyyy').format(parsedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Field Note Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FieldNoteFormScreen(
                    siteId: note.siteId,
                    siteName: note.siteName,
                    note: note,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.syncError),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Field Note?'),
                  content: Text('Are you sure you want to delete "${note.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.syncError),
                      onPressed: () {
                        context.read<FieldNoteBloc>().add(
                              DeleteFieldNote(note.id, siteId: note.siteId),
                            );
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Date Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    note.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Note Title
            Text(
              note.title,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),

            // Site and Customer Link
            if (note.siteName != null || note.customerName != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    '${note.siteName ?? ''}${note.customerName != null ? ' (${note.customerName})' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Photo Evidence
            if (note.photoPath != null || note.photoUrl != null) ...[
              Text(
                'Photo Evidence',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: note.photoPath != null && File(note.photoPath!).existsSync()
                    ? Image.file(
                        File(note.photoPath!),
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : (note.photoUrl != null
                        ? Image.network(
                            note.photoUrl!,
                            height: 240,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 140,
                              color: Colors.grey.withOpacity(0.2),
                              child: const Center(child: Text('Image not available')),
                            ),
                          )
                        : const SizedBox.shrink()),
              ),
              const SizedBox(height: 20),
            ],

            // Description / Inspection Content
            Text(
              'Observation & Notes',
              style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    note.description?.isNotEmpty == true
                        ? note.description!
                        : 'No detailed observations recorded for this note.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.5,
                      color: note.description?.isNotEmpty == true
                          ? null
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Location Section
            if (note.latitude != null && note.longitude != null) ...[
              Text(
                'GPS Location Tag',
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.pin_drop, color: AppColors.primary),
                  ),
                  title: Text(
                    '${note.latitude!.toStringAsFixed(6)}, ${note.longitude!.toStringAsFixed(6)}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text('Exact field coordinates logged upon creation'),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Sync Information
            Card(
              child: ListTile(
                leading: Icon(
                  note.syncStatus == 'synced' ? Icons.cloud_done : Icons.cloud_upload_outlined,
                  color: note.syncStatus == 'synced' ? AppColors.syncSuccess : AppColors.syncPending,
                ),
                title: Text(
                  note.syncStatus == 'synced' ? 'Synchronized with Cloud Server' : 'Stored Locally (Offline)',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text('Last updated: ${DateFormat('MMM dd, hh:mm a').format(DateTime.tryParse(note.updatedAt) ?? DateTime.now())}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
