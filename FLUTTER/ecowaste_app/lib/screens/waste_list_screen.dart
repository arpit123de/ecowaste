import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/waste_provider.dart';
import '../providers/auth_provider.dart';

class WasteListScreen extends StatefulWidget {
  const WasteListScreen({super.key});

  @override
  State<WasteListScreen> createState() => _WasteListScreenState();
}

class _WasteListScreenState extends State<WasteListScreen> {
  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    wasteProvider.setApiToken(authProvider.token ?? '');
    await wasteProvider.loadWasteReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Waste Reports'),
      ),
      body: Consumer<WasteProvider>(
        builder: (context, wasteProvider, child) {
          if (wasteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (wasteProvider.wasteReports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No waste reports yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/waste-report');
                    },
                    child: const Text('Create First Report'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadReports,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wasteProvider.wasteReports.length,
              itemBuilder: (context, index) {
                final report = wasteProvider.wasteReports[index];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: report.imagePath != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: report.imagePath!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.image),
                          ),
                    title: Text(report.wasteTypeDisplay ?? report.wasteType),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${report.city ?? ""} ${report.area ?? ""}'),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(report.status),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            report.statusDisplay ?? report.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Report'),
                            content: const Text(
                                'Are you sure you want to delete this report?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true && mounted) {
                          try {
                            await wasteProvider.deleteWasteReport(report.id!);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Report deleted'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'scheduled':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
