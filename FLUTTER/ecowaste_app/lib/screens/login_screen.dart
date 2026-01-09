import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:ui';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _selectedRole = 'User';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      try {
        await authProvider.login(
          _usernameController.text.trim(),
          _passwordController.text,
        );
        
        print('LoginScreen - After login, isBuyer: ${authProvider.isBuyer}');
        print('LoginScreen - User: ${authProvider.user?.username}');
        
        if (mounted) {
          // Route based on user type
          if (authProvider.isBuyer) {
            print('LoginScreen - Navigating to /buyer-dashboard');
            Navigator.pushReplacementNamed(context, '/buyer-dashboard');
          } else {
            print('LoginScreen - Navigating to /home');
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      } catch (e) {
        print('LoginScreen - Error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                Icons.recycling_rounded,
                                size: 60,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF10b981), Color(0xFF14b8a6)],
                              ).createShader(bounds),
                              child: const Text(
                                'EcoWaste',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Welcome back!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 32),
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
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _usernameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Username',
                                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                                prefixIcon: const Icon(Icons.person, color: Color(0xFF10b981)),
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
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
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
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),
                            Consumer<AuthProvider>(
                              builder: (context, authProvider, child) {
                                return SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF10b981),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: authProvider.isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : const Text(
                                            'Login',
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
                                Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                "Don't have an account? Sign Up",
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
