import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/waste_provider.dart';
import 'submitted_reports_screen.dart';
import 'dart:ui';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  int _selectedIndex = 0;
  int _totalReports = 0;
  int _pendingRequests = 0;
  int _ecoPoints = 0;
  double _totalImpact = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      
      // Ensure token is set before making API calls
      if (authProvider.token != null) {
        wasteProvider.setApiToken(authProvider.token!);
      } else {
        // Try to refresh auth
        await authProvider.checkAuth();
        if (authProvider.token != null) {
          wasteProvider.setApiToken(authProvider.token!);
        }
      }
      
      await wasteProvider.loadWasteReports();
      
      final reports = wasteProvider.wasteReports;
      
      setState(() {
        _totalReports = reports.length;
        _pendingRequests = reports.where((r) => r.status == 'pending').length;
        _ecoPoints = reports.length * 10; // 10 points per report
        _totalImpact = reports.fold(0.0, (sum, r) => sum + (r.exactQuantity ?? 0));
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      body: Container(
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
        child: SafeArea(
          child: _selectedIndex == 0
              ? _buildHomeTab(user)
              : _selectedIndex == 1
                  ? _buildReportsTab()
                  : _selectedIndex == 2
                      ? _buildBuyersTab()
                      : const SubmittedReportsScreen(),
        ),
      ),
      floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, '/create-report');
              },
              backgroundColor: const Color(0xFF10b981),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Report Waste'),
            )
          : null,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeTab(user) {
    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: const Color(0xFF10b981),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingSection(user),
            const SizedBox(height: 20),
            _buildReportWasteButton(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildDashboardCards(),
            const SizedBox(height: 20),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingSection(user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10b981).withOpacity(0.8),
            const Color(0xFF059669).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withOpacity(0.3),
            child: Text(
              user?.username?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                fontSize: 28,
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
                const Text(
                  '👋 Hello,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  user?.username ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Ready to make a difference today?',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications, color: Colors.white, size: 28),
                if (_pendingRequests > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_pendingRequests',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(Icons.logout, color: Colors.white, size: 28),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildReportWasteButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/create-report');
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF10b981),
              Color(0xFF14b8a6),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10b981).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Report Waste',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Take a photo and help keep your area clean',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle, color: Color(0xFF10b981)),
                  SizedBox(width: 8),
                  Text(
                    'Report Now',
                    style: TextStyle(
                      color: Color(0xFF10b981),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.inbox,
                label: 'My Requests',
                badge: _pendingRequests,
                color: const Color(0xFF3b82f6),
                onTap: () => Navigator.pushNamed(context, '/notifications'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                icon: Icons.calendar_today,
                label: 'Schedule',
                color: const Color(0xFF10b981),
                onTap: () => setState(() => _selectedIndex = 1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String label,
    int? badge,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                if (badge != null && badge > 0)
                  Positioned(
                    right: -5,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildStatCard(
          icon: Icons.recycling,
          title: 'My Reports',
          value: _totalReports,
          color: const Color(0xFF10b981),
        ),
        _buildStatCard(
          icon: Icons.pending_actions,
          title: 'Pending',
          value: _pendingRequests,
          color: const Color(0xFFf59e0b),
        ),
        _buildStatCard(
          icon: Icons.stars,
          title: 'Eco Points',
          value: _ecoPoints,
          color: const Color(0xFFfbbf24),
        ),
        _buildStatCard(
          icon: Icons.eco,
          title: 'Impact',
          value: _totalImpact.toInt(),
          suffix: 'kg',
          color: const Color(0xFF3b82f6),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required num value,
    String suffix = '',
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 40, color: color),
                const SizedBox(height: 12),
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: value.toInt()),
                  duration: const Duration(milliseconds: 1500),
                  builder: (context, value, child) {
                    return Text(
                      '$value$suffix',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final wasteProvider = Provider.of<WasteProvider>(context);
    final recentReports = wasteProvider.wasteReports.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _selectedIndex = 1),
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF10b981)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentReports.isEmpty)
          _buildEmptyState()
        else
          ...recentReports.map((report) => _buildActivityItem(report)),
      ],
    );
  }

  Widget _buildActivityItem(report) {
    IconData icon;
    Color iconColor;
    
    if (report.status == 'collected') {
      icon = Icons.check_circle;
      iconColor = const Color(0xFF10b981);
    } else if (report.status == 'assigned' || report.status == 'scheduled') {
      icon = Icons.schedule;
      iconColor = const Color(0xFF3b82f6);
    } else {
      icon = Icons.hourglass_empty;
      iconColor = const Color(0xFFf59e0b);
    }

    // Build location string
    String location = 'No location';
    if (report.fullAddress != null && report.fullAddress!.isNotEmpty) {
      location = report.fullAddress!;
    } else if (report.area != null && report.area!.isNotEmpty) {
      location = report.area!;
    } else if (report.city != null && report.city!.isNotEmpty) {
      location = report.city!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.wasteTypeDisplay ?? report.wasteType ?? 'Waste Report',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  location,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.statusDisplay ?? report.status ?? 'pending',
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Today',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox,
            size: 80,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'No reports yet',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start by reporting your first waste',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    return const Center(
      child: Text(
        'Reports Screen - Coming Soon',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildBuyersTab() {
    return const Center(
      child: Text(
        'Buyers Screen - Coming Soon',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildProfileTab(user) {
    return const Center(
      child: Text(
        'Profile Screen - Coming Soon',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF10b981),
        unselectedItemColor: Colors.white.withOpacity(0.5),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Buyers',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_turned_in),
            label: 'My Reports',
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFef4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
