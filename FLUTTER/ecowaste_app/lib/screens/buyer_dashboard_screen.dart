import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/waste_provider.dart';
import '../models/waste_report.dart';
import 'buyer_profile_screen.dart';
import 'buyer_waste_marketplace_screen.dart';
import 'buyer_orders_screen.dart';

class BuyerDashboardScreen extends StatefulWidget {
  const BuyerDashboardScreen({super.key});

  @override
  State<BuyerDashboardScreen> createState() => _BuyerDashboardScreenState();
}

class _BuyerDashboardScreenState extends State<BuyerDashboardScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _loadInitialData();
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
    
    wasteProvider.setApiToken(authProvider.token ?? '');
    await wasteProvider.loadAvailableWaste();
    await wasteProvider.loadBuyerOrders();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: _onTabChanged,
          children: const [
            BuyerDashboardTab(),
            BuyerWasteMarketplaceScreen(),
            BuyerProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onTabChanged,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF10b981),
          unselectedItemColor: Colors.white.withOpacity(0.6),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class BuyerDashboardTab extends StatefulWidget {
  const BuyerDashboardTab({super.key});

  @override
  State<BuyerDashboardTab> createState() => _BuyerDashboardTabState();
}

class _BuyerDashboardTabState extends State<BuyerDashboardTab>
    with TickerProviderStateMixin {
  late AnimationController _counterAnimationController;
  bool _hasAnimated = false;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _counterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Start counter animation after a short delay
    _loadStats();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_hasAnimated) {
        _counterAnimationController.forward();
        _hasAnimated = true;
      }
    });
  }

  Future<void> _loadStats() async {
    final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
    try {
      final stats = await wasteProvider.getBuyerStats();
      if (mounted) {
        setState(() {
          _stats = stats;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  @override
  void dispose() {
    _counterAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
        
        wasteProvider.setApiToken(authProvider.token ?? '');
        await wasteProvider.loadAvailableWaste();
        await wasteProvider.loadBuyerOrders();
        await _loadStats();
      },
      color: const Color(0xFF10b981),
      backgroundColor: const Color(0xFF1E293B),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSummaryCards(),
                const SizedBox(height: 24),
                _buildRecentWasteSection(),
                const SizedBox(height: 24),
                _buildQuickActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good ${_getGreeting()}!',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        authProvider.user?.displayName ?? 'EcoWaste Buyer',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF10b981),
                    child: Text(
                      authProvider.user?.displayName.substring(0, 1).toUpperCase() ?? 'B',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    size: 16,
                    color: true // Mock verified status for now
                        ? const Color(0xFF10b981)
                        : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    true // Mock verified status for now
                        ? 'Verified Buyer'
                        : 'Pending Verification',
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
        );
      },
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Waste Purchased',
            value: _stats != null ? _stats!['total_waste_kg'].toStringAsFixed(0) : '0',
            unit: 'kg',
            icon: Icons.scale,
            color: const Color(0xFF10b981),
            animation: _counterAnimationController,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            title: 'Active Orders',
            value: _stats != null ? _stats!['active_orders'].toString() : '0',
            unit: '',
            icon: Icons.shopping_bag,
            color: Colors.blue,
            animation: _counterAnimationController,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
    required AnimationController animation,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.trending_up,
                color: color,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              int animatedValue = (double.parse(value.replaceAll(',', '')) * animation.value).toInt();
              return Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _formatNumber(animatedValue),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (unit.isNotEmpty)
                      TextSpan(
                        text: ' $unit',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildRecentWasteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Available Waste',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                // Navigate to marketplace
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  color: Color(0xFF10b981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Consumer<WasteProvider>(
          builder: (context, wasteProvider, child) {
            if (wasteProvider.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10b981)),
                ),
              );
            }

            if (wasteProvider.wasteReports.isEmpty) {
              return _buildEmptyState();
            }

            return SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: wasteProvider.wasteReports.take(5).length,
                itemBuilder: (context, index) {
                  final waste = wasteProvider.wasteReports[index];
                  return _buildWasteCard(waste, index);
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWasteCard(WasteReport waste, int index) {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: 16, left: index == 0 ? 4 : 0),
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getWasteIcon(waste.wasteType),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getWasteTypeDisplay(waste.wasteType),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      waste.quantityDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(waste.status).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  waste.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(waste.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${waste.area}, ${waste.city}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                _formatTimeAgo(waste.createdAt ?? DateTime.now()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _showBidDialog(waste);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Make Offer',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No waste available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for new waste reports',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.shopping_cart,
                title: 'Browse Market',
                subtitle: 'Find available waste',
                color: const Color(0xFF10b981),
                onTap: () {
                  // Navigate to market
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                icon: Icons.history,
                title: 'Order History',
                subtitle: 'View past orders',
                color: Colors.blue,
                onTap: () {
                  // Navigate to orders
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showBidDialog(WasteReport waste) {
    final TextEditingController priceController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    DateTime? selectedTime1;
    DateTime? selectedTime2;
    DateTime? selectedTime3;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Make Pickup Offer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Waste info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(_getWasteIcon(waste.wasteType), style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getWasteTypeDisplay(waste.wasteType),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                waste.quantityDisplay,
                                style: TextStyle(color: Colors.white.withOpacity(0.7)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price offer
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Offer Price (₹)',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF10b981)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF10b981)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Time slots
                  const Text(
                    'Proposed Pickup Times (Select 3)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  
                  _buildTimeSlotSelector('Time Slot 1', selectedTime1, (time) {
                    setDialogState(() => selectedTime1 = time);
                  }),
                  _buildTimeSlotSelector('Time Slot 2', selectedTime2, (time) {
                    setDialogState(() => selectedTime2 = time);
                  }),
                  _buildTimeSlotSelector('Time Slot 3', selectedTime3, (time) {
                    setDialogState(() => selectedTime3 = time);
                  }),
                  
                  const SizedBox(height: 16),
                  
                  // Message
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Message (Optional)',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF10b981)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Send pickup request
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pickup offer sent successfully!'),
                    backgroundColor: Color(0xFF10b981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
              ),
              child: const Text('Send Offer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotSelector(String label, DateTime? selectedTime, Function(DateTime) onTimeSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              selectedTime != null ? '$label: ${_formatDateTime(selectedTime)}' : label,
              style: TextStyle(
                color: selectedTime != null ? Colors.white : Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  onTimeSelected(DateTime(date.year, date.month, date.day, time.hour, time.minute));
                }
              }
            },
            child: const Text(
              'Select',
              style: TextStyle(color: Color(0xFF10b981)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month} at ${TimeOfDay.fromDateTime(dateTime).format(context)}';
  }

  String _getWasteIcon(String wasteType) {
    switch (wasteType) {
      case 'plastic': return '♻️';
      case 'paper': return '📦';
      case 'organic': return '🍌';
      case 'metal': return '🔩';
      case 'glass': return '🧴';
      case 'e_waste': return '💻';
      case 'medical': return '🏥';
      case 'construction': return '🧱';
      default: return '❓';
    }
  }

  String _getWasteTypeDisplay(String wasteType) {
    switch (wasteType) {
      case 'plastic': return 'Plastic';
      case 'paper': return 'Paper';
      case 'organic': return 'Organic Waste';
      case 'metal': return 'Metal';
      case 'glass': return 'Glass';
      case 'e_waste': return 'E-Waste';
      case 'medical': return 'Medical Waste';
      case 'construction': return 'Construction Waste';
      default: return 'Other';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'in_progress': return const Color(0xFF10b981);
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}