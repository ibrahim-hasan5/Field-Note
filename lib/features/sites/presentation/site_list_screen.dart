import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/site_bloc.dart';
import '../bloc/site_event.dart';
import '../bloc/site_state.dart';
import '../models/site_model.dart';
import 'site_detail_screen.dart';
import 'site_form_screen.dart';

class SiteListScreen extends StatefulWidget {
  final String? customerId;
  final String? customerName;

  const SiteListScreen({
    super.key,
    this.customerId,
    this.customerName,
  });

  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SiteBloc>().add(LoadSites(customerId: widget.customerId));
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.customerName != null
        ? '${widget.customerName} - Sites'
        : 'Project Sites';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SiteBloc>().add(
                    LoadSites(customerId: widget.customerId, refresh: true),
                  );
            },
          ),
        ],
      ),
      floatingActionButton: widget.customerId != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SiteFormScreen(
                      customerId: widget.customerId!,
                      customerName: widget.customerName,
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('New Site', style: TextStyle(color: Colors.white)),
            )
          : null,
      body: BlocBuilder<SiteBloc, SiteState>(
        builder: (context, state) {
          if (state is SiteLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SiteError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.syncError),
                  const SizedBox(height: 12),
                  Text(state.message),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SiteBloc>().add(
                            LoadSites(customerId: widget.customerId, refresh: true),
                          );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is SiteLoaded) {
            if (state.sites.isEmpty) {
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
                          Icons.location_city_outlined,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No Sites Found',
                        style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create a project site under this customer to begin logging field notes.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<SiteBloc>().add(
                      LoadSites(customerId: widget.customerId, refresh: true),
                    );
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.sites.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final site = state.sites[index];
                  return _SiteCard(site: site);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  final SiteModel site;

  const _SiteCard({required this.site});

  @override
  Widget build(BuildContext context) {
    final isSynced = site.syncStatus == 'synced';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SiteDetailScreen(site: site),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            site.name,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: (isSynced ? AppColors.syncSuccess : AppColors.syncPending)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isSynced ? 'Synced' : 'Local',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSynced ? AppColors.syncSuccess : AppColors.syncPending,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (site.address != null)
                      Text(
                        site.address!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.lightTextSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
