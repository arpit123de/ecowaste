import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildProfileCard(),
                  const SizedBox(height: 24),
                  _buildBusinessDetails(),
                  const SizedBox(height: 24),
                  _buildStatisticsSection(),
                  const SizedBox(height: 24),
                  _buildSettingsSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Buyer Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Manage your business profile and settings',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.business,
          color: Color(0xFF10b981),
          size: 28,
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10b981).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Profile Picture and Basic Info
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF10b981),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user?.displayName.substring(0, 1).toUpperCase() ?? 'B',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10b981),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Shop Name',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.displayName ?? 'Owner Name',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: true // Mock verified status for now
                                    ? const Color(0xFF10b981).withOpacity(0.2)
                                    : Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: true // Mock verified status for now
                                      ? const Color(0xFF10b981)
                                      : Colors.orange,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    true // Mock verified status for now
                                        ? Icons.verified
                                        : Icons.pending,
                                    size: 14,
                                    color: true // Mock verified status for now
                                        ? const Color(0xFF10b981)
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    true // Mock verified status for now
                                        ? 'Verified'
                                        : 'Pending',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: true // Mock verified status for now
                                          ? const Color(0xFF10b981)
                                          : Colors.orange,
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
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Contact Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.email,
                      label: 'Email',
                      value: user?.email ?? 'Not provided',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.phone,
                      label: 'Mobile',
                      value: 'Not provided', // Mock mobile number for now
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      icon: Icons.location_on,
                      label: 'Address',
                      value: 'Not provided', // Mock address for now
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBusinessDetails() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF10b981).withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.business,
                    color: const Color(0xFF10b981),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Business Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              _buildDetailCard(
                title: 'Business Type',
                value: _formatShopType('other'), // Mock shop type for now
                icon: Icons.store,
              ),
              const SizedBox(height: 12),
              
              _buildDetailCard(
                title: 'Waste Categories',
                value: _formatWasteCategories([]), // Mock waste categories for now
                icon: Icons.category,
                isMultiline: true,
              ),
              const SizedBox(height: 12),
              
              _buildDetailCard(
                title: 'Aadhaar Number',
                value: _formatAadhaar(''), // Mock aadhaar for now
                icon: Icons.credit_card,
              ),
              
              const SizedBox(height: 16),
              
              // Edit Profile Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showEditProfileDialog();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10b981),
                    side: const BorderSide(color: Color(0xFF10b981)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: const Color(0xFF10b981),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Business Statistics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Purchases',
                  value: '1,250 kg',
                  icon: Icons.scale,
                  color: const Color(0xFF10b981),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Active Orders',
                  value: '12',
                  icon: Icons.shopping_bag,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Rating',
                  value: '4.8 ⭐',
                  icon: Icons.star,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Member Since',
                  value: 'Jan 2024',
                  icon: Icons.calendar_today,
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: const Color(0xFF10b981),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSettingsTile(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () => _showNotificationSettings(),
          ),
          
          _buildSettingsTile(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage your account security',
            onTap: () => _showSecuritySettings(),
          ),
          
          _buildSettingsTile(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help or contact support',
            onTap: () => _showHelpDialog(),
          ),
          
          _buildSettingsTile(
            icon: Icons.info,
            title: 'About EcoWaste',
            subtitle: 'Learn more about our platform',
            onTap: () => _showAboutDialog(),
          ),
          
          const SizedBox(height: 16),
          
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showLogoutDialog(),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
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
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required IconData icon,
    bool isMultiline = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: const Color(0xFF10b981),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: isMultiline ? null : 1,
                  overflow: isMultiline ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: color,
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF10b981),
        size: 24,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Colors.white.withOpacity(0.5),
        size: 16,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatShopType(String shopType) {
    switch (shopType) {
      case 'scrap_dealer': return 'Scrap Dealer';
      case 'recycling_center': return 'Recycling Center';
      case 'waste_collector': return 'Waste Collector';
      case 'junkyard': return 'Junkyard';
      case 'ewaste_handler': return 'E-Waste Handler';
      default: return 'Other';
    }
  }

  String _formatWasteCategories(List<dynamic> categories) {
    if (categories.isEmpty) return 'Not specified';
    return categories.map((cat) {
      switch (cat) {
        case 'plastic': return 'Plastic';
        case 'metal': return 'Metal';
        case 'paper': return 'Paper & Cardboard';
        case 'glass': return 'Glass';
        case 'organic': return 'Organic';
        case 'ewaste': return 'E-Waste';
        case 'mixed': return 'Mixed Waste';
        default: return cat.toString();
      }
    }).join(', ');
  }

  String _formatAadhaar(String last4) {
    return last4.isNotEmpty ? 'XXXX XXXX $last4' : 'Not provided';
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Profile editing functionality will be available soon. You can contact support for any changes needed.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    // Implementation for notification settings
  }

  void _showSecuritySettings() {
    // Implementation for security settings
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Help & Support',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Need help? Contact our support team:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            const Text(
              'Email: support@ecowaste.com\nPhone: +91 12345 67890\nWorking Hours: 9 AM - 6 PM',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'About EcoWaste',
          style: TextStyle(color: Colors.white),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EcoWaste Management Platform',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10b981),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 16),
            Text(
              'Connecting waste generators with buyers to create a sustainable circular economy.',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}