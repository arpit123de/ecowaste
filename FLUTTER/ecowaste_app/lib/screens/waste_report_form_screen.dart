import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/auth_provider.dart';
import '../providers/waste_provider.dart';
import '../models/waste_report.dart';
import 'dart:ui';

class WasteReportFormScreen extends StatefulWidget {
  const WasteReportFormScreen({super.key});

  @override
  State<WasteReportFormScreen> createState() => _WasteReportFormScreenState();
}

class _WasteReportFormScreenState extends State<WasteReportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _notesController = TextEditingController();

  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _isLoadingLocation = false;
  bool _isAnalyzing = false;
  bool _isSubmitting = false;
  
  String? _selectedWasteType;
  String? _selectedQuantity;
  String? _selectedCondition;
  
  Position? _currentPosition;
  String? _area;
  String? _city;
  String? _state;
  String? _fullAddress;
  
  // AI detected values
  Map<String, dynamic>? _aiResults;

  final List<Map<String, dynamic>> _wasteTypes = [
    {'value': 'plastic', 'label': '♻️ Plastic', 'icon': Icons.recycling},
    {'value': 'paper', 'label': '📦 Paper', 'icon': Icons.description},
    {'value': 'organic', 'label': '🍌 Organic', 'icon': Icons.eco},
    {'value': 'metal', 'label': '🔩 Metal', 'icon': Icons.construction},
    {'value': 'glass', 'label': '🧴 Glass', 'icon': Icons.local_drink},
    {'value': 'e_waste', 'label': '💻 E-Waste', 'icon': Icons.computer},
    {'value': 'medical', 'label': '🏥 Medical', 'icon': Icons.medical_services},
    {'value': 'construction', 'label': '🧱 Construction', 'icon': Icons.home_repair_service},
    {'value': 'other', 'label': '❓ Other', 'icon': Icons.help_outline},
  ];

  final List<Map<String, String>> _quantities = [
    {'value': 'small', 'label': 'Small (1-2 kg)'},
    {'value': 'medium', 'label': 'Medium (3-10 kg)'},
    {'value': 'large', 'label': 'Large (10+ kg)'},
  ];

  final List<Map<String, String>> _conditions = [
    {'value': 'dry', 'label': 'Dry'},
    {'value': 'wet', 'label': 'Wet'},
    {'value': 'mixed', 'label': 'Mixed'},
    {'value': 'hazardous', 'label': 'Hazardous'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _getCurrentLocation();
    _initializeTokens();
  }

  void _initializeTokens() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
    
    print('Auth token: ${authProvider.token}');
    if (authProvider.token != null) {
      wasteProvider.setApiToken(authProvider.token!);
      print('Token set for waste provider');
    } else {
      print('No auth token available');
      // Try to reload the token from storage
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await authProvider.checkAuth();
        if (authProvider.token != null) {
          wasteProvider.setApiToken(authProvider.token!);
          print('Token set after auth check');
        }
      });
    }
  }

  void _initializeForm() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    
    _nameController.text = user?.firstName != null && user?.lastName != null
        ? '${user!.firstName} ${user.lastName}'
        : user?.username ?? '';
    _emailController.text = user?.email ?? '';
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.deniedForever) {
        // Show permission denied message and use demo location
        setState(() {
          _area = 'City Center';
          _city = 'Mumbai';
          _state = 'Maharashtra';
          _fullAddress = 'City Center, Mumbai, Maharashtra';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('📍 Location permission denied. Please enable location access in browser settings.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      // For web, try real browser geolocation
      if (kIsWeb) {
        try {
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            timeLimit: const Duration(seconds: 10),
          );

          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            setState(() {
              _currentPosition = position;
              _area = place.subLocality ?? place.locality ?? 'Unknown Area';
              _city = place.locality ?? place.subAdministrativeArea ?? 'Unknown City';
              _state = place.administrativeArea ?? 'Unknown State';
              _fullAddress = [
                place.street ?? '',
                place.subLocality ?? '',
                place.locality ?? '',
                place.administrativeArea ?? ''
              ].where((s) => s.isNotEmpty).join(', ');
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📍 Location detected: $_city, $_state'),
                  backgroundColor: const Color(0xFF10b981),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
            setState(() => _isLoadingLocation = false);
            return;
          }
        } catch (e) {
          print('Web location error: $e');
        }
      }

      // For mobile devices, check location services
      if (!kIsWeb) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw Exception('Location services disabled. Please enable GPS.');
        }

        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );

        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          setState(() {
            _currentPosition = position;
            _area = place.subLocality ?? place.locality ?? 'Unknown';
            _city = place.locality ?? 'Unknown';
            _state = place.administrativeArea ?? 'Unknown';
            _fullAddress = '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}'.replaceAll(RegExp(r',\s*,'), ',').trim();
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Location detected!'),
                backgroundColor: Color(0xFF10b981),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e) {
      // Fallback to demo location when real location fails
      setState(() {
        _area = 'City Center';
        _city = 'Mumbai';
        _state = 'Maharashtra';
        _fullAddress = 'City Center, Mumbai, Maharashtra';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Using demo location: ${e.toString().contains('denied') ? 'Permission denied' : 'Unable to get location'}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Edit',
              textColor: Colors.white,
              onPressed: () {
                // You can scroll to location fields here if needed
              },
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _imageFile = photo;
          _imageBytes = bytes;
        });
        
        // Analyze image with AI
        await _analyzeImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      
      // Call API to classify image
      final results = await wasteProvider.classifyWasteImage(_imageFile!);
      
      setState(() {
        _aiResults = results;
        
        // Handle genuine AI classification results
        int confidence = results['confidence'] ?? 0;
        String wasteCategory = results['waste_category'] ?? 'single';
        
        if (confidence == 0 || wasteCategory == 'fake') {
          // Fake waste or invalid image detected
          String errorMsg = results['error'] ?? '❌ Fake or invalid image detected! Please upload actual waste materials only.';
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMsg),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 6),
              ),
            );
          }
          return;
        }
        
        // Auto-fill form with genuine AI results
        List materials = results['materials_detected'] ?? [];
        
        if (materials.isNotEmpty) {
          // Map detected material to our waste type categories
          String detectedMaterial = materials[0]['material'] ?? 'unknown';
          
          // Map specific materials to our form categories  
          Map<String, String> materialToWasteType = {
            'plastic_pet': 'plastic',
            'plastic_other': 'plastic',
            'iron': 'metal',
            'steel': 'metal', 
            'aluminum': 'metal',
            'copper': 'metal',
            'paper': 'paper',
            'cardboard': 'paper',
            'glass': 'glass',
            'organic': 'organic',
            'electronic': 'e_waste',
            'unknown': 'other'
          };
          
          _selectedWasteType = materialToWasteType[detectedMaterial] ?? 'other';
          
          // Set quantity based on total estimated weight
          double totalWeight = results['total_estimated_weight_kg'] ?? 0.0;
          if (totalWeight <= 2) {
            _selectedQuantity = 'small';  // 1-2 kg
          } else if (totalWeight <= 10) {
            _selectedQuantity = 'medium'; // 3-10 kg
          } else {
            _selectedQuantity = 'large';  // 10+ kg
          }
          
          // Set condition based on recyclability
          bool isRecyclable = materials[0]['recyclable'] ?? false;
          _selectedCondition = isRecyclable ? 'dry' : 'mixed';
        }
      });

      if (mounted) {
        String wasteCategory = results['waste_category'] ?? 'single';
        List materials = results['materials_detected'] ?? [];
        int confidence = results['confidence'] ?? 0;
        double totalWeight = results['total_estimated_weight_kg'] ?? 0.0;
        
        String message;
        if (wasteCategory == 'mixed' && materials.length > 1) {
          // Mixed waste - show all detected materials with weights
          List<String> materialNames = materials.map((m) => 
            '${m['material']?.toString().replaceAll('_', ' ')} (${m['estimated_weight_kg']}kg)'
          ).toList();
          message = '✨ Mixed waste detected (${confidence}%): ${materialNames.join(', ')} | Total: ${totalWeight}kg';
        } else if (materials.isNotEmpty) {
          // Single waste item with weight
          String mainMaterial = materials[0]['material']?.toString().replaceAll('_', ' ') ?? 'Unknown';
          double weight = materials[0]['estimated_weight_kg'] ?? 0.0;
          bool recyclable = materials[0]['recyclable'] ?? false;
          String recycleIcon = recyclable ? '♻️' : '🗑️';
          message = '✨ AI detected (${confidence}%): $recycleIcon $mainMaterial (${weight}kg) ${recyclable ? 'Recyclable' : 'Non-recyclable'}';
        } else {
          message = '✨ Waste detected (${confidence}%)';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: confidence > 70 ? const Color(0xFF10b981) : 
                           confidence > 40 ? Colors.orange : Colors.red,
            duration: Duration(seconds: confidence < 50 ? 4 : 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('AI analysis failed: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      setState(() => _isAnalyzing = false);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please take a photo of the waste'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWasteType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select waste type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      
      final report = WasteReport(
        name: _nameController.text,
        mobileNumber: _mobileController.text,
        email: _emailController.text,
        wasteType: _selectedWasteType!,
        quantityType: _selectedQuantity ?? 'medium',
        wasteCondition: _selectedCondition ?? 'mixed',
        locationAuto: _currentPosition != null,
        latitude: _currentPosition?.latitude.toString(),
        longitude: _currentPosition?.longitude.toString(),
        area: _area,
        city: _city,
        state: _state,
        fullAddress: _fullAddress,
        landmark: _landmarkController.text.isEmpty ? null : _landmarkController.text,
        additionalNotes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      await wasteProvider.createWasteReport(report, _imageFile);

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10b981).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10b981),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Report Submitted!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your waste report has been submitted successfully and is now pending review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Go back to dashboard
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white38),
                        ),
                        child: const Text('Back to Home'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Close dialog
                          Navigator.pop(context); // Go back to dashboard
                          // Navigate to submitted reports tab
                          if (context.mounted) {
                            // This will trigger the dashboard to switch to submitted reports tab
                            Navigator.pushNamedAndRemoveUntil(
                              context, 
                              '/home', 
                              (route) => false,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('View Reports'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _landmarkController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F172A),
              const Color(0xFF1E293B),
              const Color(0xFF064E3B),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPhotoSection(),
                        const SizedBox(height: 24),
                        if (_aiResults != null) ...[
                          _buildAIResultsSection(),
                          const SizedBox(height: 24),
                        ],
                        _buildWasteDetailsSection(),
                        const SizedBox(height: 24),
                        _buildLocationSection(),
                        const SizedBox(height: 24),
                        _buildContactSection(),
                        const SizedBox(height: 24),
                        _buildSubmitButton(),
                        const SizedBox(height: 32),
                      ],
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Waste',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Help keep the environment clean',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF10b981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 1: Take Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Capture clear image of waste',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_imageFile != null && _imageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: kIsWeb
                  ? Image.memory(
                      _imageBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Image.file(
                      File(_imageFile!.path),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(height: 16),
          ],
          if (_isAnalyzing)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF10b981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10b981)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '🤖 AI is analyzing your photo...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: Text(_imageFile == null ? 'Take Photo' : 'Retake Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10b981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Max 5MB • JPG/PNG • AI will auto-detect',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIResultsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF10b981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF10b981).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF10b981).withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF10b981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Detected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Review and adjust if needed',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAIInfoRow('Category', _aiResults!['waste_category'] ?? 'Unknown'),
          if (_aiResults!['materials_detected'] != null && _aiResults!['materials_detected'].isNotEmpty) ...[
            _buildAIInfoRow('Materials', 
              (_aiResults!['materials_detected'] as List).map((m) => 
                '${m['material']?.toString().replaceAll('_', ' ')} (${m['estimated_weight_kg']}kg) ${m['recyclable'] == true ? '♻️' : '🗑️'}'
              ).join('\n')
            ),
          ],
          _buildAIInfoRow('Total Weight', '${_aiResults!['total_estimated_weight_kg'] ?? 0}kg'),
          _buildAIInfoRow('Confidence', '${_aiResults!['confidence'] ?? 0}%'),
        ],
      ),
    );
  }

  Widget _buildAIInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWasteDetailsSection() {
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF3b82f6).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.category,
                  color: Color(0xFF3b82f6),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waste Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Select waste type and quantity',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Waste Type *',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _wasteTypes.map((type) {
              final isSelected = _selectedWasteType == type['value'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedWasteType = type['value'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10b981)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10b981)
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    type['label'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Quantity *',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ..._quantities.map((quantity) {
            final isSelected = _selectedQuantity == quantity['value'];
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedQuantity = quantity['value'];
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10b981).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10b981)
                        : Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFF10b981) : Colors.white70,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      quantity['label']!,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          const Text(
            'Condition *',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _conditions.map((condition) {
              final isSelected = _selectedCondition == condition['value'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCondition = condition['value'];
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10b981)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF10b981)
                          : Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    condition['label']!,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFf59e0b).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Color(0xFFf59e0b),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Auto-detected from GPS',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoadingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf59e0b)),
                  ),
                )
              else
                IconButton(
                  onPressed: _getCurrentLocation,
                  icon: const Icon(Icons.refresh, color: Color(0xFFf59e0b)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_fullAddress != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFf59e0b).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFFf59e0b)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _fullAddress!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _landmarkController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Landmark (Optional)',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'e.g., Near City Mall',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
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
        ],
      ),
    );
  }

  Widget _buildContactSection() {
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
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFF8b5cf6).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF8b5cf6),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'For pickup coordination',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
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
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _mobileController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number *',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
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
              if (value == null || value.isEmpty) {
                return 'Please enter mobile number';
              }
              if (value.length < 10) {
                return 'Please enter valid mobile number';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
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
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            style: const TextStyle(color: Colors.white),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Additional Notes (Optional)',
              labelStyle: const TextStyle(color: Colors.white70),
              hintText: 'Any special instructions or details...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
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
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10b981),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 8,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Submit Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
