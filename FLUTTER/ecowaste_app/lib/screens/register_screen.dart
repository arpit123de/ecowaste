import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import 'dart:ui';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _password2Controller = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _mobileController = TextEditingController();
  
  // Buyer specific controllers
  final _shopNameController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _aadhaarController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscurePassword2 = true;
  bool _isLoading = false;
  String _selectedRole = 'User';
  File? _shopPhoto;
  File? _tradeLicense;
  final List<String> _selectedWasteTypes = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  final List<String> _wasteTypes = [
    'Plastic',
    'Metal',
    'Paper & Cardboard',
    'Glass',
    'Organic',
    'E-Waste',
    'Mixed Waste',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _password2Controller.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _mobileController.dispose();
    _shopNameController.dispose();
    _shopAddressController.dispose();
    _aadhaarController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isShopPhoto) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        if (isShopPhoto) {
          _shopPhoto = File(image.path);
        } else {
          _tradeLicense = File(image.path);
        }
      });
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  double _getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.25;
    return strength;
  }


  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      // Validate buyer-specific fields
      if (_selectedRole == 'Buyer') {
        if (_mobileController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mobile number is required for buyers')),
          );
          return;
        }
        if (_shopNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop name is required')),
          );
          return;
        }
        if (_shopAddressController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shop address is required')),
          );
          return;
        }
        if (_aadhaarController.text.trim().length != 12) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aadhaar must be exactly 12 digits')),
          );
          return;
        }
        if (_selectedWasteTypes.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Select at least one waste type')),
          );
          return;
        }
      }
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      try {
        setState(() => _isLoading = true);
        
        if (_selectedRole == 'Buyer') {
          // Use the new buyer registration method
          await authProvider.registerBuyer(
            fullName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim(),
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            mobile: _mobileController.text.trim(),
            password: _passwordController.text,
            shopName: _shopNameController.text.trim(),
            shopType: 'scrap_dealer', // Default for now
            shopAddress: _shopAddressController.text.trim(),
            wasteCategories: _selectedWasteTypes.map((type) {
              switch (type) {
                case 'Plastic': return 'plastic';
                case 'Metal': return 'metal';
                case 'Paper & Cardboard': return 'paper';
                case 'Glass': return 'glass';
                case 'Organic': return 'organic';
                case 'E-Waste': return 'ewaste';
                case 'Mixed Waste': return 'mixed';
                default: return type.toLowerCase();
              }
            }).toList(),
            aadhaarNumber: _aadhaarController.text.trim(),
          );
          
          if (mounted) {
            setState(() => _isLoading = false);
            // Navigate to buyer dashboard
            Navigator.pushNamedAndRemoveUntil(context, '/buyer-dashboard', (route) => false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome ${_shopNameController.text}!'),
                backgroundColor: const Color(0xFF10b981),
              ),
            );
          }
        } else {
          // Regular user registration
          await authProvider.register(
            username: _usernameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            password2: _password2Controller.text,
            firstName: _firstNameController.text.trim().isEmpty 
                ? null 
                : _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim().isEmpty 
                ? null 
                : _lastNameController.text.trim(),
            role: 'user',
          );
          
          if (mounted) {
            setState(() => _isLoading = false);
            // Navigate to user dashboard
            Navigator.pushReplacementNamed(context, '/home');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Welcome ${_firstNameController.text.isNotEmpty ? _firstNameController.text : _usernameController.text}!'),
                backgroundColor: const Color(0xFF10b981),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final passwordStrength = _getPasswordStrength(_passwordController.text);
    
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: const Color(0xFF10b981).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10b981).withOpacity(0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF10b981), Color(0xFF14b8a6)],
                              ).createShader(bounds),
                              child: const Icon(
                                Icons.person_add_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF10b981), Color(0xFF14b8a6)],
                              ).createShader(bounds),
                              child: const Text(
                                'Join EcoWaste',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start making a difference today',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Role Toggle
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedRole = 'User'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'User'
                                              ? const Color(0xFF10b981)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'User',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _selectedRole == 'User'
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.5),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _selectedRole = 'Buyer'),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        decoration: BoxDecoration(
                                          color: _selectedRole == 'Buyer'
                                              ? const Color(0xFF10b981)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Buyer',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _selectedRole == 'Buyer'
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.5),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            // First Name & Last Name
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF10b981)),
                                      filled: true,
                                      fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF10b981)),
                                      filled: true,
                                      fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Username
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Username *',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.account_circle, color: Color(0xFF10b981)),
                                filled: true,
                                fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                ),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            // Email
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email *',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.email, color: Color(0xFF10b981)),
                                filled: true,
                                fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter email';
                                }
                                if (!value!.contains('@')) {
                                  return 'Please enter valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            // Password
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password *',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFF10b981)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFF10b981),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              onChanged: (_) => setState(() {}),
                              validator: _validatePassword,
                            ),
                            const SizedBox(height: 8),
                            // Password Strength Indicator
                            if (_passwordController.text.isNotEmpty) ...[
                              LinearProgressIndicator(
                                value: passwordStrength,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  passwordStrength < 0.5
                                      ? Colors.red
                                      : passwordStrength < 0.75
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                                minHeight: 4,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                passwordStrength < 0.5
                                    ? 'Weak'
                                    : passwordStrength < 0.75
                                        ? 'Medium'
                                        : 'Strong',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: passwordStrength < 0.5
                                      ? Colors.red
                                      : passwordStrength < 0.75
                                          ? Colors.orange
                                          : Colors.green,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            // Confirm Password
                            TextFormField(
                              controller: _password2Controller,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password *',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.lock, color: Color(0xFF10b981)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword2 ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFF10b981),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword2 = !_obscurePassword2;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                ),
                              ),
                              obscureText: _obscurePassword2,
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please confirm password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            // Buyer-specific fields
                            if (_selectedRole == 'Buyer') ...[
                              Divider(color: Colors.white.withOpacity(0.2)),
                              const SizedBox(height: 12),
                              const Text(
                                'Business Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF10b981),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Mobile Number
                              TextFormField(
                                controller: _mobileController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number *',
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF10b981)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                  ),
                                ),
                                keyboardType: TextInputType.phone,
                              ),
                              const SizedBox(height: 12),
                              // Shop Name
                              TextFormField(
                                controller: _shopNameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Shop/Business Name *',
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  prefixIcon: const Icon(Icons.store, color: Color(0xFF10b981)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Shop Address
                              TextFormField(
                                controller: _shopAddressController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Shop Address *',
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  prefixIcon: const Icon(Icons.location_on, color: Color(0xFF10b981)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                  ),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              // Aadhaar Number
                              TextFormField(
                                controller: _aadhaarController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Aadhaar Number *',
                                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                  prefixIcon: const Icon(Icons.credit_card, color: Color(0xFF10b981)),
                                  filled: true,
                                  fillColor: const Color(0xFF0F172A).withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF10b981), width: 2),
                                  ),
                                  hintText: 'XXXX XXXX XXXX',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                ),
                                keyboardType: TextInputType.number,
                                maxLength: 12,
                              ),
                              const SizedBox(height: 12),
                              // Waste Types
                              Text(
                                'Waste Types Handled *',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _wasteTypes.map((type) {
                                  final isSelected = _selectedWasteTypes.contains(type);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedWasteTypes.remove(type);
                                        } else {
                                          _selectedWasteTypes.add(type);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF10b981)
                                            : const Color(0xFF0F172A).withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF10b981)
                                              : Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: Text(
                                        type,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 16),
                              // Shop Photo Upload
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.add_a_photo, color: Color(0xFF10b981)),
                                  title: Text(
                                    _shopPhoto != null ? 'Shop Photo Selected' : 'Upload Shop Photo',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: _shopPhoto != null
                                      ? Text(
                                          _shopPhoto!.path.split('/').last,
                                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                        )
                                      : null,
                                  trailing: Icon(
                                    _shopPhoto != null ? Icons.check_circle : Icons.upload_file,
                                    color: _shopPhoto != null ? Colors.green : Colors.white.withOpacity(0.5),
                                  ),
                                  onTap: () => _pickImage(true),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Trade License Upload
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                child: ListTile(
                                  leading: const Icon(Icons.description, color: Color(0xFF10b981)),
                                  title: Text(
                                    _tradeLicense != null ? 'Trade License Selected' : 'Upload Trade License (Optional)',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: _tradeLicense != null
                                      ? Text(
                                          _tradeLicense!.path.split('/').last,
                                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                                        )
                                      : null,
                                  trailing: Icon(
                                    _tradeLicense != null ? Icons.check_circle : Icons.upload_file,
                                    color: _tradeLicense != null ? Colors.green : Colors.white.withOpacity(0.5),
                                  ),
                                  onTap: () => _pickImage(false),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            // Register Button
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading ? null : _register,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10b981),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: authProvider.isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text(
                                            'Create Account',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Already have an account? Login',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF10b981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
