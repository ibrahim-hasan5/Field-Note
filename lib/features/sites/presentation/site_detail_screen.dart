import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../field_notes/presentation/field_note_form_screen.dart';
import '../../field_notes/presentation/field_note_list_screen.dart';
import '../bloc/site_bloc.dart';
import '../bloc/site_event.dart';
import '../models/site_model.dart';
import 'site_form_screen.dart';

class SiteDetailScreen extends StatelessWidget {
  final SiteModel site;

  const SiteDetailScreen({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(site.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SiteFormScreen(
                    customerId: site.customerId,
                    customerName: site.customerName,
                    site: site,
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
                  title: const Text('Delete Site?'),
                  content: Text('Are you sure you want to delete ${site.name}? Linked field notes will also be removed.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.syncError),
                      onPressed: () {
                        context.read<SiteBloc>().add(
                              DeleteSite(site.id, customerId: site.customerId),
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.location_city, color: AppColors.secondary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                site.name,
                                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (site.customerName != null)
                                Text(
                                  'Client: ${site.customerName}',
                                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (site.address != null) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place_outlined, size: 20, color: AppColors.lightTextSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              site.address!,
                              style: GoogleFonts.inter(color: AppColors.lightTextSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions for Notes
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FieldNoteFormScreen(
                            siteId: site.id,
                            siteName: site.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New Field Note'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FieldNoteListScreen(
                            siteId: site.id,
                            siteName: site.name,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.notes_rounded),
                    label: const Text('View Notes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
