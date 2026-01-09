import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/waste_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
    try {
      await wasteProvider.fetchWasteReports();
    } catch (e) {
      // Handle error silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final wasteProvider = Provider.of<WasteProvider>(context);
    final user = authProvider.user;

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
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadStats,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildProfileCard(user),
              const SizedBox(height: 20),
              _buildStatsGrid(wasteProvider),
              const SizedBox(height: 20),
              _buildActionCard(
                title: 'Edit Profile',
                subtitle: 'Update your personal information',
                icon: Icons.edit,
                color: const Color(0xFF3b82f6),
                onTap: () => _showEditProfileDialog(context, user),
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                title: 'My Reports',
                subtitle: 'View all your waste reports',
                icon: Icons.description,
                color: const Color(0xFF10b981),
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                icon: Icons.notifications,
                color: const Color(0xFFf59e0b),
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                title: 'Help & Support',
                subtitle: 'Get help or contact support',
                icon: Icons.help_outline,
                color: const Color(0xFF8b5cf6),
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _buildActionCard(
                title: 'About App',
                subtitle: 'Version 1.0.0',
                icon: Icons.info_outline,
                color: const Color(0xFF6366f1),
                onTap: () => _showAboutDialog(context),
              ),
              const SizedBox(height: 24),
              _buildLogoutButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Manage your account and preferences',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF10b981).withOpacity(0.2),
            const Color(0xFF3b82f6).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10b981).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10b981),
                  Color(0xFF3b82f6),
                ],
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
            ),
            child: Center(
              child: Text(
                user?.username?.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user?.username ?? 'User',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (user?.email != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Colors.white70,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  user!.email!,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withOpacity(0.2),
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
                  Icons.verified,
                  color: Color(0xFF10b981),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  user?.role?.toUpperCase() ?? 'USER',
                  style: const TextStyle(
                    color: Color(0xFF10b981),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(WasteProvider wasteProvider) {
    final reports = wasteProvider.wasteReports;
    final totalReports = reports.length;
    final pendingReports = reports.where((r) => r.status == 'pending').length;
    final collectedReports = reports.where((r) => r.status == 'collected').length;
    final ecoPoints = collectedReports * 10;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Impact',
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
              child: _buildStatCard(
                title: 'Total Reports',
                value: totalReports.toString(),
                icon: Icons.description,
                color: const Color(0xFF3b82f6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Eco Points',
                value: ecoPoints.toString(),
                icon: Icons.star,
                color: const Color(0xFFf59e0b),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Pending',
                value: pendingReports.toString(),
                icon: Icons.pending,
                color: const Color(0xFFef4444),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                title: 'Collected',
                value: collectedReports.toString(),
                icon: Icons.check_circle,
                color: const Color(0xFF10b981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
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
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showLogoutDialog(context),
        icon: const Icon(Icons.logout),
        label: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFef4444),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Profile editing feature coming soon!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('OK'),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10b981), Color(0xFF3b82f6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.eco, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Text(
              'EcoWaste',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'EcoWaste Management System helps you report and manage waste collection efficiently. Together, we can make our environment cleaner and greener.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 16),
            Text(
              '© 2024 EcoWaste. All rights reserved.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
