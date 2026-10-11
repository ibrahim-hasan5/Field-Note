import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../bloc/site_bloc.dart';
import '../bloc/site_event.dart';
import '../models/site_model.dart';

class SiteFormScreen extends StatefulWidget {
  final String customerId;
  final String? customerName;
  final SiteModel? site;

  const SiteFormScreen({
    super.key,
    required this.customerId,
    this.customerName,
    this.site,
  });

  @override
  State<SiteFormScreen> createState() => _SiteFormScreenState();
}

class _SiteFormScreenState extends State<SiteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.site?.name ?? '');
    _addressController = TextEditingController(text: widget.site?.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final now = DateTime.now().toIso8601String();
      if (widget.site == null) {
        final newSite = SiteModel(
          id: const Uuid().v4(),
          customerId: widget.customerId,
          customerName: widget.customerName,
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          createdAt: now,
          updatedAt: now,
          syncStatus: 'pending',
        );
        context.read<SiteBloc>().add(AddSite(newSite));
      } else {
        final updated = widget.site!.copyWith(
          name: _nameController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          updatedAt: now,
          syncStatus: 'pending',
        );
        context.read<SiteBloc>().add(UpdateSite(updated));
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.site != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Site' : 'New Project Site'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.customerName != null) ...[
                  Text(
                    'Client: ${widget.customerName}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Site / Project Name *',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Building B - Substation',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Site name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Text(
                  'Physical Location / Address',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Plot 4, Sector 7, Industrial Area',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Update Site' : 'Create Site'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
