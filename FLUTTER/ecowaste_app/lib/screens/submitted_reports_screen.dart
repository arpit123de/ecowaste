import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waste_provider.dart';
import '../models/waste_report.dart';
import 'report_detail_screen.dart';
import 'dart:ui';

class SubmittedReportsScreen extends StatefulWidget {
  const SubmittedReportsScreen({super.key});

  @override
  State<SubmittedReportsScreen> createState() => _SubmittedReportsScreenState();
}

class _SubmittedReportsScreenState extends State<SubmittedReportsScreen> {
  bool _isLoading = true;
  List<WasteReport> _reports = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      await wasteProvider.loadWasteReports();
      setState(() {
        _reports = wasteProvider.wasteReports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

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
          title: const Text(
            'My Reports',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadReports,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10b981)),
                ),
              )
            : _reports.isEmpty
                ? _buildEmptyState()
                : _buildReportsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.description_outlined,
              size: 60,
              color: Color(0xFF10b981),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Reports Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Submit your first waste report to\nhelp the environment!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/create-report');
            },
            icon: const Icon(Icons.add),
            label: const Text('Submit Report'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return RefreshIndicator(
      onRefresh: _loadReports,
      color: const Color(0xFF10b981),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reports.length,
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildReportCard(report);
        },
      ),
    );
  }

  Widget _buildReportCard(WasteReport report) {
    final statusColor = _getStatusColor(report.status);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailScreen(report: report),
            ),
          );
        },
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
                // Header with status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Report #${report.id}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${report.wasteType} • ${report.quantityType}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(report.status),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusText(report.status),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Tap hint
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF10b981).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.touch_app,
                        size: 14,
                        color: Color(0xFF10b981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tap to view full details',
                        style: TextStyle(
                          fontSize: 12,
                          color: const Color(0xFF10b981),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Details
                _buildDetailRow(Icons.location_on, 'Location', '${report.area}, ${report.city}'),
                if (report.exactQuantity != null)
                  _buildDetailRow(Icons.scale, 'Weight', '${report.exactQuantity} kg'),
                _buildDetailRow(Icons.calendar_today, 'Submitted', _formatDate(report.createdAt ?? DateTime.now())),
                if (report.additionalNotes?.isNotEmpty == true)
                  _buildDetailRow(Icons.note, 'Notes', report.additionalNotes!),
                
                const SizedBox(height: 16),
                
                // Action buttons based on status
                _buildActionButtons(report),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF10b981),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.8),
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

  Widget _buildActionButtons(WasteReport report) {
    List<Widget> buttons = [];
    
    // Always show View Details button
    buttons.add(
      Expanded(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReportDetailScreen(report: report),
              ),
            );
          },
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('View Details'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10b981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
    
    if (report.status.toLowerCase() == 'pending') {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Cancel report functionality
              _showCancelDialog(report);
            },
            icon: const Icon(Icons.cancel_outlined, size: 16),
            label: const Text('Cancel'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }
    
    if (report.status.toLowerCase() == 'confirmed') {
      buttons.add(const SizedBox(width: 8));
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Track progress functionality
              _showProgressDialog(report);
            },
            icon: const Icon(Icons.track_changes, size: 16),
            label: const Text('Track'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      );
    }
    
    return Row(
      children: buttons,
    );
  }

  void _showCancelDialog(WasteReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Cancel Report', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this report?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement cancel functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report cancellation requested'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showProgressDialog(WasteReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Report Progress', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildProgressStep('Submitted', true, Icons.check),
            _buildProgressStep('Confirmed', true, Icons.check),
            _buildProgressStep('In Progress', report.status == 'in_progress', Icons.refresh),
            _buildProgressStep('Completed', report.status == 'completed', Icons.check_circle),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String title, bool isActive, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF10b981) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}