import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/waste_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (authProvider.isAuthenticated) {
      wasteProvider.setApiToken(authProvider.token ?? '');
      await wasteProvider.loadWasteReports();
      await wasteProvider.loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoWaste'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Card(
                      color: const Color(0xFF10b981),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.waving_hand,
                              size: 40,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Hello, ${authProvider.user?.username ?? "User"}!',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const Text(
                                    'Ready to make a difference?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                // Report Waste Button
                SizedBox(
                  width: double.infinity,
                  height: 120,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/waste-report');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                      padding: const EdgeInsets.all(20),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 40, color: Colors.white),
                        SizedBox(height: 8),
                        Text(
                          'Report Waste',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Statistics
                Consumer<WasteProvider>(
                  builder: (context, wasteProvider, child) {
                    final stats = wasteProvider.statistics;
                    
                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Total Reports',
                            value: stats?['total_reports']?.toString() ?? '0',
                            icon: Icons.description,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Pending',
                            value: stats?['pending']?.toString() ?? '0',
                            icon: Icons.pending,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Consumer<WasteProvider>(
                  builder: (context, wasteProvider, child) {
                    final stats = wasteProvider.statistics;
                    
                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Scheduled',
                            value: stats?['scheduled']?.toString() ?? '0',
                            icon: Icons.schedule,
                            color: Colors.purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Completed',
                            value: stats?['completed']?.toString() ?? '0',
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        title: 'My Reports',
                        icon: Icons.list_alt,
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pushNamed(context, '/waste-list');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        title: 'Browse Buyers',
                        icon: Icons.store,
                        color: Colors.teal,
                        onTap: () {
                          Navigator.pushNamed(context, '/buyers');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
