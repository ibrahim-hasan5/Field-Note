import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../sites/presentation/site_list_screen.dart';
import '../bloc/customer_bloc.dart';
import '../bloc/customer_event.dart';
import '../models/customer_model.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  final CustomerModel customer;

  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(customer.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CustomerFormScreen(customer: customer),
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
                  title: const Text('Delete Customer?'),
                  content: Text('Are you sure you want to delete ${customer.name}? All linked sites will be affected.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.syncError),
                      onPressed: () {
                        context.read<CustomerBloc>().add(DeleteCustomer(customer.id));
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
            // Header Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      child: Text(
                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            customer.name,
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (customer.syncStatus == 'synced'
                                      ? AppColors.syncSuccess
                                      : AppColors.syncPending)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              customer.syncStatus == 'synced' ? 'Synced with cloud' : 'Pending cloud sync',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: customer.syncStatus == 'synced'
                                    ? AppColors.syncSuccess
                                    : AppColors.syncPending,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Contact Information Section
            Text(
              'Contact Details',
              style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                    title: const Text('Email'),
                    subtitle: Text(customer.email ?? 'Not provided'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    title: const Text('Phone'),
                    subtitle: Text(customer.phone ?? 'Not provided'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    title: const Text('Address'),
                    subtitle: Text(customer.address ?? 'Not provided'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Project Sites Section Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SiteListScreen(customerId: customer.id, customerName: customer.name),
                    ),
                  );
                },
                icon: const Icon(Icons.location_city_rounded),
                label: const Text('View Customer Project Sites'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
