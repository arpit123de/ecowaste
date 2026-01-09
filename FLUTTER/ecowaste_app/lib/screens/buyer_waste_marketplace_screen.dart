import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/waste_provider.dart';
import '../providers/auth_provider.dart';
import '../models/waste_report.dart';

class BuyerWasteMarketplaceScreen extends StatefulWidget {
  const BuyerWasteMarketplaceScreen({super.key});

  @override
  State<BuyerWasteMarketplaceScreen> createState() => _BuyerWasteMarketplaceScreenState();
}

class _BuyerWasteMarketplaceScreenState extends State<BuyerWasteMarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedWasteType = 'all';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWasteData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWasteData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
    
    wasteProvider.setApiToken(authProvider.token ?? '');
    await wasteProvider.loadWasteReports();
  }

  List<WasteReport> _getFilteredWaste(List<WasteReport> allWaste) {
    return allWaste.where((waste) {
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

      return waste.status == 'pending';
    }).toList();
  }

  void _showPickupRequestDialog(WasteReport waste) {
    showDialog(
      context: context,
      builder: (context) => PickupRequestDialog(waste: waste),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Waste Marketplace',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadWasteData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: Consumer<WasteProvider>(
              builder: (context, wasteProvider, child) {
                if (wasteProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF10b981),
                    ),
                  );
                }

                final filteredWaste = _getFilteredWaste(wasteProvider.wasteReports);

                if (filteredWaste.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.recycling,
                          size: 80,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No waste available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadWasteData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredWaste.length,
                    itemBuilder: (context, index) {
                      return _buildWasteCard(filteredWaste[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() {}),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by waste type or location...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF10b981)),
              filled: true,
              fillColor: const Color(0xFF0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                _buildFilterChip('♻️ Plastic', 'plastic'),
                _buildFilterChip('📦 Paper', 'paper'),
                _buildFilterChip('🍌 Organic', 'organic'),
                _buildFilterChip('🔩 Metal', 'metal'),
                _buildFilterChip('🧴 Glass', 'glass'),
                _buildFilterChip('💻 E-Waste', 'e_waste'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedWasteType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedWasteType = value;
          });
        },
        backgroundColor: const Color(0xFF0F172A),
        selectedColor: const Color(0xFF10b981),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[400],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.white,
      ),
    );
  }

  Widget _buildWasteCard(WasteReport waste) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      child: InkWell(
        onTap: () => _showPickupRequestDialog(waste),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF0F172A),
                      image: waste.imagePath != null
                          ? DecorationImage(
                              image: NetworkImage('http://127.0.0.1:8000${waste.imagePath}'),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: waste.imagePath == null
                        ? const Icon(
                            Icons.delete,
                            size: 40,
                            color: Color(0xFF10b981),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          waste.wasteTypeDisplay ?? waste.wasteType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10b981),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          waste.quantityDisplay,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${waste.area ?? 'Unknown'}, ${waste.city ?? 'Unknown'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0xFF334155)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.health_and_safety,
                    waste.wasteCondition.toUpperCase(),
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    Icons.calendar_today,
                    DateFormat('MMM dd, yyyy').format(waste.createdAt ?? DateTime.now()),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showPickupRequestDialog(waste),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Send Pickup Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}

class PickupRequestDialog extends StatefulWidget {
  final WasteReport waste;

  const PickupRequestDialog({super.key, required this.waste});

  @override
  State<PickupRequestDialog> createState() => _PickupRequestDialogState();
}

class _PickupRequestDialogState extends State<PickupRequestDialog> {
  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSubmitting = false;

  final List<String> _timeSlots = [
    '9:00 AM - 11:00 AM',
    '11:00 AM - 1:00 PM',
    '2:00 PM - 4:00 PM',
    '4:00 PM - 6:00 PM',
  ];

  @override
  void dispose() {
    _priceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF10b981),
              surface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a pickup date'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a time slot'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter estimated price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      
      await wasteProvider.sendPickupRequest(
        wasteReportId: widget.waste.id!,
        pickupDate: _selectedDate!,
        pickupTime: _selectedTimeSlot!,
        priceOffer: double.parse(_priceController.text),
        message: _messageController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup request sent successfully! User will be notified.'),
            backgroundColor: Color(0xFF10b981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping,
                    color: Color(0xFF10b981),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Send Pickup Request',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Waste Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.waste.wasteTypeDisplay ?? widget.waste.wasteType.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10b981),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quantity: ${widget.waste.quantityDisplay}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                    Text(
                      'Location: ${widget.waste.area}, ${widget.waste.city}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Date Selection
              const Text(
                'Pickup Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Color(0xFF10b981)),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDate == null
                            ? 'Select Date'
                            : DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate!),
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate == null ? Colors.grey[500] : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Time Slot Selection
              const Text(
                'Time Slot',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timeSlots.map((slot) {
                  final isSelected = _selectedTimeSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTimeSlot = selected ? slot : null;
                      });
                    },
                    backgroundColor: const Color(0xFF0F172A),
                    selectedColor: const Color(0xFF10b981),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[400],
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Price Offer
              const Text(
                'Price Offer (₹)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter your price offer',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF10b981)),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Message
              const Text(
                'Message (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add any special instructions or notes...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10b981),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Send Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
