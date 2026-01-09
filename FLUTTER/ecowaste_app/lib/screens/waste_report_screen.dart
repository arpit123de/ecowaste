import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../models/waste_report.dart';
import '../providers/waste_provider.dart';
import '../providers/auth_provider.dart';

class WasteReportScreen extends StatefulWidget {
  const WasteReportScreen({super.key});

  @override
  State<WasteReportScreen> createState() => _WasteReportScreenState();
}

class _WasteReportScreenState extends State<WasteReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _wasteType = 'plastic';
  String _quantityType = 'small';
  String _wasteCondition = 'mixed';
  XFile? _imageFile;
  Position? _position;
  bool _usingLocation = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions permanently denied')),
        );
      }
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _position = position;
      _usingLocation = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location captured successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please capture or select an image')),
        );
        return;
      }

      final wasteProvider = Provider.of<WasteProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      wasteProvider.setApiToken(authProvider.token ?? '');

      final report = WasteReport(
        mobileNumber: _mobileController.text.trim(),
        wasteType: _wasteType,
        quantityType: _quantityType,
        wasteCondition: _wasteCondition,
        locationAuto: _usingLocation,
        latitude: _position?.latitude.toStringAsFixed(5),
        longitude: _position?.longitude.toStringAsFixed(5),
        area: _areaController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        fullAddress: _addressController.text.trim(),
        additionalNotes: _notesController.text.trim(),
      );

      try {
        await wasteProvider.createWasteReport(report, _imageFile);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waste report submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit: ${e.toString()}'),
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
      appBar: AppBar(
        title: const Text('Report Waste'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              const Text('Waste Photo *', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_imageFile != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: kIsWeb
                      ? FutureBuilder<Uint8List>(
                          future: _imageFile!.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                              );
                            }
                            return const Center(child: CircularProgressIndicator());
                          },
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_imageFile!.path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        ),
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Contact
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number *',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Waste Type
              DropdownButtonFormField<String>(
                initialValue: _wasteType,
                decoration: const InputDecoration(
                  labelText: 'Waste Type *',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'plastic', child: Text('♻️ Plastic')),
                  DropdownMenuItem(value: 'paper', child: Text('📦 Paper')),
                  DropdownMenuItem(value: 'organic', child: Text('🍌 Organic')),
                  DropdownMenuItem(value: 'metal', child: Text('🔩 Metal')),
                  DropdownMenuItem(value: 'glass', child: Text('🧴 Glass')),
                  DropdownMenuItem(value: 'e_waste', child: Text('💻 E-Waste')),
                ],
                onChanged: (value) => setState(() => _wasteType = value!),
              ),
              const SizedBox(height: 16),

              // Quantity
              DropdownButtonFormField<String>(
                initialValue: _quantityType,
                decoration: const InputDecoration(
                  labelText: 'Quantity *',
                  prefixIcon: Icon(Icons.scale),
                ),
                items: const [
                  DropdownMenuItem(value: 'small', child: Text('Small (<5kg)')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium (5-20kg)')),
                  DropdownMenuItem(value: 'large', child: Text('Large (>20kg)')),
                ],
                onChanged: (value) => setState(() => _quantityType = value!),
              ),
              const SizedBox(height: 16),

              // Condition
              DropdownButtonFormField<String>(
                initialValue: _wasteCondition,
                decoration: const InputDecoration(
                  labelText: 'Condition *',
                  prefixIcon: Icon(Icons.check_circle),
                ),
                items: const [
                  DropdownMenuItem(value: 'clean', child: Text('Clean & Sorted')),
                  DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                  DropdownMenuItem(value: 'contaminated', child: Text('Contaminated')),
                ],
                onChanged: (value) => setState(() => _wasteCondition = value!),
              ),
              const SizedBox(height: 20),

              // Location
              const Text('Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.my_location),
                label: Text(_usingLocation ? 'Location Captured' : 'Use Current Location'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _usingLocation ? Colors.green : null,
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _areaController,
                decoration: const InputDecoration(
                  labelText: 'Area',
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _stateController,
                decoration: const InputDecoration(
                  labelText: 'State',
                  prefixIcon: Icon(Icons.map),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Full Address',
                  prefixIcon: Icon(Icons.home),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  prefixIcon: Icon(Icons.note),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              Consumer<WasteProvider>(
                builder: (context, wasteProvider, child) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: wasteProvider.isLoading ? null : _submitReport,
                      child: wasteProvider.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Submit Report', style: TextStyle(fontSize: 18)),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
