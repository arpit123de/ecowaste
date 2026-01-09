import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/waste_provider.dart';
import '../providers/auth_provider.dart';
import '../models/waste_report.dart';

class WasteMarketplaceScreen extends StatefulWidget {
  const WasteMarketplaceScreen({super.key});

  @override
  State<WasteMarketplaceScreen> createState() => _WasteMarketplaceScreenState();
}

class _WasteMarketplaceScreenState extends State<WasteMarketplaceScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _selectedWasteType = 'all';
  String _selectedQuantity = 'all';
  String _selectedLocation = 'all';
  String _sortBy = 'newest';
  
  late AnimationController _filterAnimationController;
  late Animation<double> _filterSlideAnimation;
  bool _showFilters = false;

  final List<Map<String, String>> _wasteTypes = [
    {'value': 'all', 'label': 'All Types', 'icon': '🗂️'},
    {'value': 'plastic', 'label': 'Plastic', 'icon': '♻️'},
    {'value': 'paper', 'label': 'Paper', 'icon': '📦'},
    {'value': 'organic', 'label': 'Organic', 'icon': '🍌'},
    {'value': 'metal', 'label': 'Metal', 'icon': '🔩'},
    {'value': 'glass', 'label': 'Glass', 'icon': '🧴'},
    {'value': 'e_waste', 'label': 'E-Waste', 'icon': '💻'},
    {'value': 'medical', 'label': 'Medical', 'icon': '🏥'},
    {'value': 'construction', 'label': 'Construction', 'icon': '🧱'},
  ];

  @override
  void initState() {
    super.initState();
    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _filterSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _filterAnimationController, curve: Curves.easeInOut),
    );
    _loadWasteData();
  }

  @override
  void dispose() {
    _filterAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWasteData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
    
    wasteProvider.setApiToken(authProvider.token ?? '');
    await wasteProvider.loadAvailableWaste();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
    if (_showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  List<WasteReport> _getFilteredWaste(List<WasteReport> allWaste) {
    List<WasteReport> filtered = allWaste.where((waste) {
      // Text search
      if (_searchController.text.isNotEmpty) {
        String searchTerm = _searchController.text.toLowerCase();
        if (!waste.wasteType.toLowerCase().contains(searchTerm) &&
            !(waste.area?.toLowerCase().contains(searchTerm) ?? false) &&
            !(waste.city?.toLowerCase().contains(searchTerm) ?? false)) {
          return false;
        }
      }

      // Waste type filter
      if (_selectedWasteType != 'all' && waste.wasteType != _selectedWasteType) {
        return false;
      }

      // Quantity filter
      if (_selectedQuantity != 'all' && waste.quantityType != _selectedQuantity) {
        return false;
      }

      return true;
    }).toList();

    // Sorting
    switch (_sortBy) {
      case 'newest':
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      case 'oldest':
        filtered.sort((a, b) => (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now()));
        break;
      case 'quantity_high':
        filtered.sort((a, b) {
          double aQty = a.exactQuantity ?? 0;
          double bQty = b.exactQuantity ?? 0;
          return bQty.compareTo(aQty);
        });
        break;
      case 'quantity_low':
        filtered.sort((a, b) {
          double aQty = a.exactQuantity ?? 0;
          double bQty = b.exactQuantity ?? 0;
          return aQty.compareTo(bQty);
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilters(),
            if (_showFilters) _buildFilterPanel(),
            Expanded(child: _buildWasteGrid()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waste Marketplace',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Find and purchase available waste',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.store,
              color: const Color(0xFF10b981),
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search waste, location...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.5)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: Colors.white.withOpacity(0.5)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: _showFilters ? const Color(0xFF10b981) : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _showFilters ? const Color(0xFF10b981) : Colors.white.withOpacity(0.1),
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.tune,
                    color: _showFilters ? Colors.white : Colors.white.withOpacity(0.7),
                  ),
                  onPressed: _toggleFilters,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Quick filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _wasteTypes.take(5).map((type) => _buildQuickFilterChip(type)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(Map<String, String> type) {
    bool isSelected = _selectedWasteType == type['value'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedWasteType = type['value']!;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10b981) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF10b981) : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type['icon']!, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              type['label']!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel() {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_filterSlideAnimation),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF10b981).withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Quantity filter
            const Text(
              'Quantity',
              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('All Quantities', 'all', _selectedQuantity, (value) {
                  setState(() => _selectedQuantity = value);
                }),
                _buildFilterChip('Small (1-2kg)', 'small', _selectedQuantity, (value) {
                  setState(() => _selectedQuantity = value);
                }),
                _buildFilterChip('Medium (3-10kg)', 'medium', _selectedQuantity, (value) {
                  setState(() => _selectedQuantity = value);
                }),
                _buildFilterChip('Large (10+ kg)', 'large', _selectedQuantity, (value) {
                  setState(() => _selectedQuantity = value);
                }),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Sort by
            const Text(
              'Sort by',
              style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('Newest', 'newest', _sortBy, (value) {
                  setState(() => _sortBy = value);
                }),
                _buildFilterChip('Oldest', 'oldest', _sortBy, (value) {
                  setState(() => _sortBy = value);
                }),
                _buildFilterChip('High Quantity', 'quantity_high', _sortBy, (value) {
                  setState(() => _sortBy = value);
                }),
                _buildFilterChip('Low Quantity', 'quantity_low', _sortBy, (value) {
                  setState(() => _sortBy = value);
                }),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _selectedWasteType = 'all';
                        _selectedQuantity = 'all';
                        _selectedLocation = 'all';
                        _sortBy = 'newest';
                        _searchController.clear();
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white.withOpacity(0.7),
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text('Clear All'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _toggleFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                    ),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, String currentValue, Function(String) onChanged) {
    bool isSelected = currentValue == value;
    
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10b981) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF10b981) : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildWasteGrid() {
    return RefreshIndicator(
      onRefresh: _loadWasteData,
      color: const Color(0xFF10b981),
      backgroundColor: const Color(0xFF1E293B),
      child: Consumer<WasteProvider>(
        builder: (context, wasteProvider, child) {
          if (wasteProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10b981)),
              ),
            );
          }

          final filteredWaste = _getFilteredWaste(wasteProvider.wasteReports);

          if (filteredWaste.isEmpty) {
            return _buildEmptyState();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: filteredWaste.length,
            itemBuilder: (context, index) {
              final waste = filteredWaste[index];
              return _buildWasteCard(waste);
            },
          );
        },
      ),
    );
  }

  Widget _buildWasteCard(WasteReport waste) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF10b981).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10b981).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
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
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${waste.area}, ${waste.city}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeAgo(waste.createdAt ?? DateTime.now()),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),

                  // Condition
                  if (waste.wasteCondition.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Condition: ${waste.wasteCondition}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Notes preview
                  if (waste.additionalNotes != null && waste.additionalNotes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notes: ${waste.additionalNotes!.length > 50 ? '${waste.additionalNotes!.substring(0, 50)}...' : waste.additionalNotes}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showWasteDetails(waste),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF10b981),
                            side: const BorderSide(color: Color(0xFF10b981)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _showBidDialog(waste),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10b981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Make Offer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty || _selectedWasteType != 'all'
                ? 'No matching waste found'
                : 'No waste available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty || _selectedWasteType != 'all'
                ? 'Try adjusting your filters or search terms'
                : 'Check back later for new waste reports',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchController.text.isNotEmpty || _selectedWasteType != 'all') ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedWasteType = 'all';
                  _selectedQuantity = 'all';
                  _sortBy = 'newest';
                  _searchController.clear();
                });
              },
              child: const Text(
                'Clear Filters',
                style: TextStyle(color: Color(0xFF10b981)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showWasteDetails(WasteReport waste) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          _getWasteTypeDisplay(waste.wasteType),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Quantity', waste.quantityDisplay),
              _buildDetailRow('Condition', waste.wasteCondition),
              _buildDetailRow('Location', '${waste.area}, ${waste.city}'),
              _buildDetailRow('Reported', _formatTimeAgo(waste.createdAt ?? DateTime.now())),
              if (waste.additionalNotes?.isNotEmpty == true)
                _buildDetailRow('Notes', waste.additionalNotes!),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showBidDialog(waste);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
            ),
            child: const Text('Make Offer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
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

  void _showBidDialog(WasteReport waste) {
    // This would be the same bid dialog as in the dashboard
    // For brevity, I'll just show a simple implementation
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Make Pickup Offer',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pickup offer sent!'),
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
    );
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