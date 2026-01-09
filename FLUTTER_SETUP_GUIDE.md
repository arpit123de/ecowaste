# Flutter App Setup Guide for EcoWaste

## ✅ Backend is Ready!

Your Django REST API is now running at: **http://127.0.0.1:8000/api/**

API endpoints available:
- `/api/auth/register/` - User registration
- `/api/auth/login/` - User login
- `/api/auth/logout/` - User logout
- `/api/waste-reports/` - Waste report CRUD
- `/api/buyers/` - Browse buyers
- `/api/pickup-requests/` - Pickup requests
- `/api/ratings/` - Rate buyers
- `/api/pickup-history/` - View history

---

## Next Steps: Create Flutter App

### 1. Create Flutter Project

```bash
flutter create ecowaste_app
cd ecowaste_app
```

### 2. Add Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Network & API
  http: ^1.1.0
  dio: ^5.4.0
  
  # State Management
  provider: ^6.1.1
  
  # Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # UI Components
  image_picker: ^1.0.7
  cached_network_image: ^3.3.1
  flutter_rating_bar: ^4.0.1
  
  # Location
  geolocator: ^11.0.0
  geocoding: ^2.1.1
  
  # Maps (optional)
  google_maps_flutter: ^2.5.3
  
  # Utils
  intl: ^0.19.0
```

### 3. Project Structure

```
lib/
├── main.dart
├── models/
│   ├── user.dart
│   ├── waste_report.dart
│   ├── buyer.dart
│   └── pickup_request.dart
├── services/
│   ├── api_service.dart
│   ├── auth_service.dart
│   └── storage_service.dart
├── providers/
│   ├── auth_provider.dart
│   └── waste_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── waste_report_screen.dart
│   ├── buyers_screen.dart
│   └── profile_screen.dart
└── widgets/
    ├── custom_button.dart
    ├── waste_card.dart
    └── buyer_card.dart
```

### 4. Sample Code Snippets

#### API Service (lib/services/api_service.dart)

```dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this based on your setup:
  // Android Emulator: http://10.0.2.2:8000
  // iOS Simulator: http://127.0.0.1:8000
  // Physical Device: http://YOUR_IP:8000
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return data;
    } else {
      throw Exception('Login failed');
    }
  }

  Future<List<dynamic>> getWasteReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/waste-reports/'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['results'];
    } else {
      throw Exception('Failed to load reports');
    }
  }

  Future<Map<String, dynamic>> createWasteReport(
    Map<String, dynamic> data,
    File? imageFile,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/waste-reports/'),
    );

    request.headers['Authorization'] = 'Token $_token';

    data.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create report');
    }
  }
}
```

#### Auth Provider (lib/providers/auth_provider.dart)

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;

  Future<void> login(String username, String password) async {
    try {
      final data = await _apiService.login(username, password);
      _isAuthenticated = true;
      _user = data['user'];
      
      await _storageService.saveToken(data['token']);
      _apiService.setToken(data['token']);
      
      notifyListeners();
    } catch (e) {
      throw e;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _user = null;
    await _storageService.deleteToken();
    notifyListeners();
  }

  Future<void> checkAuth() async {
    final token = await _storageService.getToken();
    if (token != null) {
      _apiService.setToken(token);
      _isAuthenticated = true;
      notifyListeners();
    }
  }
}
```

#### Login Screen (lib/screens/login_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await Provider.of<AuthProvider>(context, listen: false).login(
          _usernameController.text,
          _passwordController.text,
        );
        
        Navigator.pushReplacementNamed(context, '/home');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.recycling,
                  size: 80,
                  color: Color(0xFF10b981),
                ),
                SizedBox(height: 24),
                Text(
                  'EcoWaste',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10b981),
                  ),
                ),
                SizedBox(height: 48),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter username';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter password';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10b981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Login',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: Text('Don\'t have an account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### 5. Main.dart Setup

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'EcoWaste',
        theme: ThemeData(
          primaryColor: Color(0xFF10b981),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(0xFF10b981),
          ),
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => SplashScreen(),
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(),
        },
      ),
    );
  }
}
```

### 6. Run the App

```bash
# Run on Android
flutter run

# Run on iOS
flutter run -d ios

# Run on specific device
flutter devices
flutter run -d DEVICE_ID
```

---

## Important Configuration

### Android (android/app/src/main/AndroidManifest.xml)

Add internet permission:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.CAMERA"/>
```

### Network Security (android/app/src/main/res/xml/network_security_config.xml)

For development with HTTP:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
</network-security-config>
```

Then add to AndroidManifest.xml:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

---

## Testing Checklist

- [ ] Backend API running on http://127.0.0.1:8000
- [ ] Can register new user via API
- [ ] Can login and get token
- [ ] Can create waste report with image
- [ ] Can list waste reports
- [ ] Can browse buyers
- [ ] Can create pickup requests
- [ ] Location services working
- [ ] Image picker working
- [ ] Token storage working

---

## Next Development Steps

1. **Phase 1**: Basic screens (Login, Register, Home)
2. **Phase 2**: Waste reporting with camera
3. **Phase 3**: Browse buyers & pickup requests
4. **Phase 4**: Real-time updates & notifications
5. **Phase 5**: Maps integration
6. **Phase 6**: Polish UI & animations

---

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [HTTP Package](https://pub.dev/packages/http)
- [Provider Pattern](https://pub.dev/packages/provider)
- [Image Picker](https://pub.dev/packages/image_picker)

Your backend is ready! Start building the Flutter app now! 🚀
