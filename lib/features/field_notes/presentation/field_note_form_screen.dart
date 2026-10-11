import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../settings/data/settings_repository.dart';
import '../bloc/field_note_bloc.dart';
import '../bloc/field_note_event.dart';
import '../models/field_note_model.dart';

class FieldNoteFormScreen extends StatefulWidget {
  final String siteId;
  final String? siteName;
  final FieldNoteModel? note;

  const FieldNoteFormScreen({
    super.key,
    required this.siteId,
    this.siteName,
    this.note,
  });

  @override
  State<FieldNoteFormScreen> createState() => _FieldNoteFormScreenState();
}

class _FieldNoteFormScreenState extends State<FieldNoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();
  final _imagePicker = ImagePicker();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  late DateTime _selectedDate;
  late String _status;
  double? _latitude;
  double? _longitude;
  String? _photoPath;
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _descriptionController = TextEditingController(text: widget.note?.description ?? '');

    _selectedDate = widget.note != null
        ? DateTime.tryParse(widget.note!.noteDate) ?? DateTime.now()
        : DateTime.now();

    final defaultStatus = SettingsRepository.instance.getDefaultNoteStatus();
    _status = widget.note?.status ?? defaultStatus;
    _latitude = widget.note?.latitude;
    _longitude = widget.note?.longitude;
    _photoPath = widget.note?.photoPath;

    if (widget.note == null) {
      _fetchLocation();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isGettingLocation = true);
    final pos = await _locationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        if (pos != null) {
          _latitude = pos.latitude;
          _longitude = pos.longitude;
        }
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (picked != null) {
        setState(() {
          _photoPath = picked.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not access image: $e')),
      );
    }
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now().toIso8601String();
      if (widget.note == null) {
        final newNote = FieldNoteModel(
          id: const Uuid().v4(),
          siteId: widget.siteId,
          siteName: widget.siteName,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          noteDate: _selectedDate.toIso8601String(),
          status: _status,
          photoPath: _photoPath,
          createdAt: now,
          updatedAt: now,
          syncStatus: 'pending',
        );
        context.read<FieldNoteBloc>().add(AddFieldNote(newNote));
      } else {
        final updated = widget.note!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          noteDate: _selectedDate.toIso8601String(),
          status: _status,
          photoPath: _photoPath,
          updatedAt: now,
          syncStatus: 'pending',
        );
        context.read<FieldNoteBloc>().add(UpdateFieldNote(updated));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.note != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Field Note' : 'New Field Note'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.siteName != null) ...[
                  Text(
                    'Site: ${widget.siteName}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                Text(
                  'Note Title *',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Electrical wire inspection passed',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Note title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Description
                Text(
                  'Observations / Details',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'Describe physical conditions, safety measures, observations...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),

                // Status & Date Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _status,
                            items: const [
                              DropdownMenuItem(value: 'DRAFT', child: Text('Draft')),
                              DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                              DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.calendar_today_outlined, size: 20),
                              ),
                              child: Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // GPS Location Widget
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.my_location, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GPS Coordinates',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 3),
                              if (_isGettingLocation)
                                const Text('Acquiring location...', style: TextStyle(fontSize: 12))
                              else if (_latitude != null && _longitude != null)
                                Text(
                                  '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                                )
                              else
                                const Text('No GPS tagged', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: AppColors.primary),
                          onPressed: _fetchLocation,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Attached Photo
                Text(
                  'Site Photo Evidence',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_photoPath != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: kIsWeb
                            ? Image.network(
                                _photoPath!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                File(_photoPath!),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => setState(() => _photoPath = null),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Take Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('From Gallery'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Update Note' : 'Save Field Note'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
