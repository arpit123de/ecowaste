import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waste_provider.dart';
import '../providers/auth_provider.dart';

class BuyersScreen extends StatefulWidget {
  const BuyersScreen({super.key});

  @override
  State<BuyersScreen> createState() => _BuyersScreenState();
}

class _BuyersScreenState extends State<BuyersScreen> {
  @override
  void initState() {
    super.initState();
    _loadBuyers();
  }

  Future<void> _loadBuyers() async {
    final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    wasteProvider.setApiToken(authProvider.token ?? '');
    await wasteProvider.loadBuyers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Buyers'),
      ),
      body: Consumer<WasteProvider>(
        builder: (context, wasteProvider, child) {
          if (wasteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (wasteProvider.buyers.isEmpty) {
            return const Center(
              child: Text('No buyers available'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: wasteProvider.buyers.length,
            itemBuilder: (context, index) {
              final buyer = wasteProvider.buyers[index];
              
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.green[100],
                            child: const Icon(Icons.store, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  buyer.shopName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${buyer.city}, ${buyer.state}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                if (buyer.averageRating != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.orange,
                                      ),
                                      Text(
                                        ' ${buyer.averageRating!.toStringAsFixed(1)} (${buyer.totalRatings})',
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Accepts:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 4,
                        children: buyer.wasteTypesAccepted.map((type) {
                          return Chip(
                            label: Text(type),
                            backgroundColor: Colors.green[50],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16),
                          const SizedBox(width: 4),
                          Text(buyer.contactNumber),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
