import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class BuyerRegisterScreen extends StatefulWidget {
  const BuyerRegisterScreen({super.key});

  @override
  State<BuyerRegisterScreen> createState() => _BuyerRegisterScreenState();
}

class _BuyerRegisterScreenState extends State<BuyerRegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Controllers
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _aadhaarController = TextEditingController();

  // State variables
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _currentPage = 0;
  String _selectedShopType = 'scrap_dealer';
  List<String> _selectedWasteCategories = [];
  bool _isLoading = false;

  final List<Map<String, String>> _shopTypes = [
    {'value': 'scrap_dealer', 'label': 'Scrap Dealer', 'icon': '♻️'},
    {'value': 'recycling_center', 'label': 'Recycling Center', 'icon': '🏭'},
    {'value': 'waste_collector', 'label': 'Waste Collector', 'icon': '🚚'},
    {'value': 'junkyard', 'label': 'Junkyard', 'icon': '🏗️'},
    {'value': 'ewaste_handler', 'label': 'E-Waste Handler', 'icon': '💻'},
    {'value': 'other', 'label': 'Other', 'icon': '🔧'},
  ];

  final List<Map<String, String>> _wasteCategories = [
    {'value': 'plastic', 'label': 'Plastic', 'icon': '♻️'},
    {'value': 'metal', 'label': 'Metal', 'icon': '🔩'},
    {'value': 'paper', 'label': 'Paper & Cardboard', 'icon': '📦'},
    {'value': 'glass', 'label': 'Glass', 'icon': '🧴'},
    {'value': 'organic', 'label': 'Organic', 'icon': '🍌'},
    {'value': 'ewaste', 'label': 'E-Waste', 'icon': '💻'},
    {'value': 'mixed', 'label': 'Mixed Waste', 'icon': '🗂️'},
  ];

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
    _pageController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        final success = await authProvider.registerBuyer(
          fullName: _fullNameController.text.trim(),
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          mobile: _mobileController.text.trim(),
          password: _passwordController.text,
          shopName: _shopNameController.text.trim(),
          shopType: _selectedShopType,
          shopAddress: _shopAddressController.text.trim(),
          wasteCategories: _selectedWasteCategories,
          aadhaarNumber: _aadhaarController.text.trim(),
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Buyer registration successful!'),
                ],
              ),
              backgroundColor: Color(0xFF10b981),
              duration: Duration(seconds: 2),
            ),
          );
          Navigator.pushNamedAndRemoveUntil(context, '/buyer-dashboard', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Registration failed: $e')),
                ],
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          'Buyer Registration',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Progress Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Row(
                    children: [
                      _buildProgressIndicator(0, 'Personal'),
                      Expanded(child: _buildProgressLine(0)),
                      _buildProgressIndicator(1, 'Business'),
                      Expanded(child: _buildProgressLine(1)),
                      _buildProgressIndicator(2, 'Verification'),
                    ],
                  ),
                ),
                
                // Page View
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildPersonalInfoPage(),
                      _buildBusinessInfoPage(),
                      _buildVerificationPage(),
                    ],
                  ),
                ),
                
                // Navigation Buttons
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF10b981),
                              side: const BorderSide(color: Color(0xFF10b981)),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text('Previous'),
                          ),
                        ),
                      
                      if (_currentPage > 0) const SizedBox(width: 16),
                      
                      Expanded(
                        flex: _currentPage > 0 ? 1 : 2,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_currentPage < 2 ? _nextPage : _register),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10b981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(_currentPage < 2 ? 'Next' : 'Complete Registration'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(int step, String label) {
    bool isActive = _currentPage >= step;
    bool isCompleted = _currentPage > step;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF10b981) : Colors.grey.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF10b981) : Colors.grey,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? const Color(0xFF10b981) : Colors.grey,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(int step) {
    bool isActive = _currentPage > step;
    
    return Container(
      height: 2,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF10b981) : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personal Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us about yourself',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildTextField(
              controller: _fullNameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.account_circle,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a username';
                }
                if (value.trim().length < 3) {
                  return 'Username must be at least 3 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _mobileController,
              label: 'Mobile Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your mobile number';
                }
                if (!RegExp(r'^\+?1?\d{9,15}$').hasMatch(value)) {
                  return 'Please enter a valid mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _passwordController,
              label: 'Password',
              icon: Icons.lock,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us about your business',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _shopNameController,
            label: 'Shop/Business Name',
            icon: Icons.store,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your shop name';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Shop Type Selection
          const Text(
            'Business Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _shopTypes.map((type) => _buildShopTypeChip(type)).toList(),
          ),
          
          const SizedBox(height: 24),
          
          _buildTextField(
            controller: _shopAddressController,
            label: 'Shop Address',
            icon: Icons.location_on,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your shop address';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Waste Categories Selection
          const Text(
            'Waste Categories You Handle',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select all types of waste your business can handle',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _wasteCategories.map((category) => _buildWasteCategoryChip(category)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us verify your identity',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          
          _buildTextField(
            controller: _aadhaarController,
            label: 'Aadhaar Number',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your Aadhaar number';
              }
              if (value.replaceAll(' ', '').length != 12) {
                return 'Aadhaar number must be 12 digits';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10b981).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: const Color(0xFF10b981),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Security & Privacy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Your Aadhaar number will be encrypted and securely stored\n'
                  '• Only the last 4 digits will be displayed for verification\n'
                  '• Your data will never be shared with third parties\n'
                  '• Required for legal compliance and fraud prevention',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Important Note',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account will be under review after registration. You can start browsing available waste immediately, but pickup scheduling will be available after verification approval.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF10b981)),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        filled: true,
        fillColor: const Color(0xFF1E293B).withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildShopTypeChip(Map<String, String> type) {
    bool isSelected = _selectedShopType == type['value'];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedShopType = type['value']!;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10b981) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF10b981) : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              type['icon']!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              type['label']!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteCategoryChip(Map<String, String> category) {
    bool isSelected = _selectedWasteCategories.contains(category['value']);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedWasteCategories.remove(category['value']);
          } else {
            _selectedWasteCategories.add(category['value']!);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10b981) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFF10b981) : Colors.white.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              category['icon']!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(width: 8),
            Text(
              category['label']!,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}