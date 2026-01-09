import 'package:flutter/material.dart';
import '../models/waste_report.dart';
import 'dart:ui';

class ReportDetailScreen extends StatelessWidget {
  final WasteReport report;

  const ReportDetailScreen({super.key, required this.report});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return const Color(0xFF10b981);
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Pending Review';
      case 'confirmed':
        return 'Confirmed';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'in_progress':
        return Icons.refresh;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(report.status);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E293B),
            Color(0xFF064E3B),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Report #${report.id}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status Header
              _buildStatusHeader(statusColor),
              const SizedBox(height: 24),

              // Waste Image
              if (report.imagePath != null) _buildImageSection(),

              // Report Details
              _buildDetailsSection(),

              // Location Details
              _buildLocationSection(),

              // Additional Information
              if (report.additionalNotes?.isNotEmpty == true) _buildNotesSection(),

              // Timeline Section
              _buildTimelineSection(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(report.status),
              color: statusColor,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusText(report.status),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Submitted on ${_formatDate(report.createdAt ?? DateTime.now())}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.photo_camera,
                      color: Color(0xFF10b981),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Waste Photo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[800],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: Colors.white54,
                            size: 50,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Waste Image',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildDetailsSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF10b981),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Report Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailRow('Name', report.name ?? 'Not provided'),
                _buildDetailRow('Mobile', report.mobileNumber),
                if (report.email?.isNotEmpty == true)
                  _buildDetailRow('Email', report.email!),
                _buildDetailRow('Waste Type', _getWasteTypeDisplay(report.wasteType)),
                _buildDetailRow('Quantity', _getQuantityDisplay()),
                _buildDetailRow('Condition', _getConditionDisplay(report.wasteCondition)),
                if (report.exactQuantity != null)
                  _buildDetailRow('Exact Weight', '${report.exactQuantity} kg'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFF10b981),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (report.locationAuto) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10b981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Auto-detected',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10b981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                if (report.fullAddress?.isNotEmpty == true)
                  _buildDetailRow('Full Address', report.fullAddress!),
                if (report.area?.isNotEmpty == true)
                  _buildDetailRow('Area', report.area!),
                if (report.city?.isNotEmpty == true)
                  _buildDetailRow('City', report.city!),
                if (report.state?.isNotEmpty == true)
                  _buildDetailRow('State', report.state!),
                if (report.landmark?.isNotEmpty == true)
                  _buildDetailRow('Landmark', report.landmark!),
                if (report.latitude != null && report.longitude != null)
                  _buildDetailRow('Coordinates', '${report.latitude}, ${report.longitude}'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      color: Color(0xFF10b981),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Additional Notes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    report.additionalNotes!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
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

  Widget _buildTimelineSection() {
    return Container(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: Color(0xFF10b981),
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Progress Timeline',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTimelineStep('Report Submitted', true, Icons.upload_file, 'Your waste report was submitted successfully'),
                _buildTimelineStep('Under Review', report.status != 'pending', Icons.search, 'Report is being reviewed by our team'),
                _buildTimelineStep('Confirmed', ['confirmed', 'in_progress', 'completed'].contains(report.status), Icons.check_circle, 'Report confirmed and pickup scheduled'),
                _buildTimelineStep('In Progress', ['in_progress', 'completed'].contains(report.status), Icons.local_shipping, 'Collection team is on the way'),
                _buildTimelineStep('Completed', report.status == 'completed', Icons.done_all, 'Waste collected successfully'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String title, bool isCompleted, IconData icon, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFF10b981) : Colors.grey.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? Colors.white : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted ? Colors.white.withOpacity(0.8) : Colors.grey.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
  }

  String _getWasteTypeDisplay(String wasteType) {
    switch (wasteType) {
      case 'plastic':
        return '♻️ Plastic';
      case 'paper':
        return '📦 Paper';
      case 'organic':
        return '🍌 Organic';
      case 'metal':
        return '🔩 Metal';
      case 'glass':
        return '🧴 Glass';
      case 'e_waste':
        return '💻 E-Waste';
      case 'medical':
        return '🏥 Medical';
      case 'construction':
        return '🧱 Construction';
      default:
        return '❓ Other';
    }
  }

  String _getQuantityDisplay() {
    if (report.exactQuantity != null) {
      return '${report.exactQuantity} kg';
    }
    switch (report.quantityType) {
      case 'small':
        return 'Small (1-2 kg)';
      case 'medium':
        return 'Medium (3-10 kg)';
      case 'large':
        return 'Large (10+ kg)';
      default:
        return report.quantityType;
    }
  }

  String _getConditionDisplay(String condition) {
    switch (condition) {
      case 'dry':
        return 'Dry';
      case 'wet':
        return 'Wet';
      case 'mixed':
        return 'Mixed';
      case 'hazardous':
        return 'Hazardous';
      default:
        return condition;
    }
  }
}