import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lawyer_provider.dart';
import '../models/lawyer_model.dart';
import 'package:url_launcher/url_launcher.dart';

class LawyerDetailsScreen extends StatefulWidget {
  final LawyerModel lawyer;

  const LawyerDetailsScreen({super.key, required this.lawyer});

  @override
  State<LawyerDetailsScreen> createState() => _LawyerDetailsScreenState();
}

class _LawyerDetailsScreenState extends State<LawyerDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المحامي'),
        actions: [
          if (widget.lawyer.phone != null && widget.lawyer.phone!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.phone),
              onPressed: () => _makePhoneCall(widget.lawyer.phone!),
              tooltip: 'اتصال',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildInfoCard(),
            const SizedBox(height: 16),
            if (widget.lawyer.addressDetails != null && widget.lawyer.addressDetails!.isNotEmpty)
              _buildAddressCard(),
            const SizedBox(height: 16),
            if (widget.lawyer.notes != null && widget.lawyer.notes!.isNotEmpty)
              _buildNotesCard(),
            const SizedBox(height: 16),
            if (widget.lawyer.phone != null && widget.lawyer.phone!.isNotEmpty)
              _buildContactCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    widget.lawyer.name.isNotEmpty 
                        ? widget.lawyer.name[0]
                        : '?',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lawyer.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.lawyer.gradeDisplay,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'المعلومات الأساسية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.badge,
              'رقم القيد',
              widget.lawyer.registrationNumber,
            ),
            if (widget.lawyer.branch != null && widget.lawyer.branch!.isNotEmpty)
              _buildInfoRow(
                Icons.business,
                'الفرع',
                widget.lawyer.branch!,
              ),
            if (widget.lawyer.governorate != null && widget.lawyer.governorate!.isNotEmpty)
              _buildInfoRow(
                Icons.location_city,
                'المحافظة',
                widget.lawyer.governorate!,
              ),
            if (widget.lawyer.directorate != null && widget.lawyer.directorate!.isNotEmpty)
              _buildInfoRow(
                Icons.location_on,
                'المديرية',
                widget.lawyer.directorate!,
              ),
            if (widget.lawyer.neighborhood != null && widget.lawyer.neighborhood!.isNotEmpty)
              _buildInfoRow(
                Icons.place,
                'الحي',
                widget.lawyer.neighborhood!,
              ),
            if (widget.lawyer.officeType != null && widget.lawyer.officeType!.isNotEmpty)
              _buildInfoRow(
                Icons.store,
                'نوع المكتب',
                widget.lawyer.officeType!,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'العنوان',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.map, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.lawyer.addressDetails!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملاحظات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.note, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.lawyer.notes!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'معلومات الاتصال',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.lawyer.phone!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () => _makePhoneCall(widget.lawyer.phone!),
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (!await launchUrl(launchUri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن إجراء المكالمة')),
        );
      }
    }
  }
}
