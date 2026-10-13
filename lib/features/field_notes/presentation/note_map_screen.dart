import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/field_note_model.dart';

/// Fullscreen map view that pins a field note's GPS location.
/// Uses OpenStreetMap tiles (no API key required).
class NoteMapScreen extends StatefulWidget {
  final FieldNoteModel note;

  const NoteMapScreen({super.key, required this.note});

  @override
  State<NoteMapScreen> createState() => _NoteMapScreenState();
}

class _NoteMapScreenState extends State<NoteMapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final lat = widget.note.latitude!;
    final lng = widget.note.longitude!;
    final center = LatLng(lat, lng);

    Color statusColor(String s) {
      switch (s) {
        case 'COMPLETED': return AppColors.statusCompleted;
        case 'IN_PROGRESS': return AppColors.statusInProgress;
        default: return AppColors.statusDraft;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note.title,
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Center map on note pin
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on note',
            onPressed: () {
              _mapController.move(center, 16.0);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 16.0,
              maxZoom: 19.0,
              minZoom: 3.0,
            ),
            children: [
              // OpenStreetMap tiles (free, no API key)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.fieldnotes.app',
              ),
              // Marker at note location
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () => _showNotePopup(context, _statusColor(widget.note.status)),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Shadow circle
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withOpacity(0.18),
                            ),
                          ),
                          // Pin icon
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _statusColor(widget.note.status),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _statusColor(widget.note.status).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.note_alt_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Bottom info card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 6,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _statusColor(widget.note.status).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.note.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _statusColor(widget.note.status),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.note.title,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (widget.note.siteName != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_city_outlined,
                              size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            widget.note.siteName!,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.pin_drop,
                            size: 14, color: AppColors.lightTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Zoom controls (top-right)
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _ZoomButton(
                  icon: Icons.add,
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom + 1,
                    );
                  },
                ),
                const SizedBox(height: 4),
                _ZoomButton(
                  icon: Icons.remove,
                  onTap: () {
                    _mapController.move(
                      _mapController.camera.center,
                      _mapController.camera.zoom - 1,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showNotePopup(BuildContext context, Color statusColor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.note.title,
                style: GoogleFonts.outfit(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            if (widget.note.description?.isNotEmpty == true)
              Text(
                widget.note.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    color: AppColors.lightTextSecondary, fontSize: 13),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(widget.note.status,
                      style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}
