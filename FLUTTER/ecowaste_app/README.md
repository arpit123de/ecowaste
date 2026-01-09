# EcoWaste Mobile App

A Flutter mobile application for the EcoWaste waste management platform.

## Features

- 📱 User authentication (register, login, logout)
- 📸 Waste report creation with image capture
- 📍 GPS location tracking (5 decimal precision)
- 📊 Dashboard with statistics
- 📋 View and manage waste reports
- 🏪 Browse verified waste buyers
- 👤 User profile management

## Prerequisites

- Flutter SDK 3.0 or higher
- Dart 2.19 or higher
- Android Studio / VS Code with Flutter extension
- Android emulator or physical device
- Django backend running at http://127.0.0.1:8000

## Installation

1. **Navigate to the Flutter app directory:**
   ```bash
   cd flutter/ecowaste_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Verify Flutter setup:**
   ```bash
   flutter doctor
   ```

## Running the App

### On Android Emulator

1. Start your Android emulator
2. Ensure Django backend is running at http://127.0.0.1:8000
3. Run the app:
   ```bash
   flutter run
   ```

The app will connect to the backend at `http://10.0.2.2:8000/api/` (emulator localhost mapping)

### On iOS Simulator

1. Start iOS simulator
2. Update API base URL in `lib/services/api_service.dart`:
   ```dart
   static const String baseUrl = 'http://localhost:8000/api';
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### On Physical Device

1. Enable USB debugging on your Android device
2. Connect device via USB
3. Update API base URL in `lib/services/api_service.dart` with your computer's IP:
   ```dart
   static const String baseUrl = 'http://YOUR_IP:8000/api';
   ```
4. Run the app:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── waste_report.dart
│   └── buyer.dart
├── services/                 # API and storage services
│   ├── api_service.dart
│   └── storage_service.dart
├── providers/                # State management
│   ├── auth_provider.dart
│   └── waste_provider.dart
└── screens/                  # UI screens
    ├── splash_screen.dart
    ├── login_screen.dart
    ├── register_screen.dart
    ├── home_screen.dart
    ├── waste_report_screen.dart
    ├── waste_list_screen.dart
    ├── buyers_screen.dart
    └── profile_screen.dart
```

## Configuration

### API Endpoints

Default configuration in `lib/services/api_service.dart`:

- **Android Emulator:** `http://10.0.2.2:8000/api/`
- **iOS Simulator:** `http://localhost:8000/api/`
- **Physical Device:** `http://YOUR_IP:8000/api/`

### Permissions

The app requires the following permissions:
- Internet access
- Camera access
- Location access (GPS)
- Storage access (read/write)

All permissions are configured in `android/app/src/main/AndroidManifest.xml`

## API Integration

The app connects to the Django REST API with the following endpoints:

- `POST /auth/register/` - User registration
- `POST /auth/login/` - User login
- `POST /auth/logout/` - User logout
- `GET /waste-reports/` - List waste reports
- `POST /waste-reports/` - Create waste report
- `DELETE /waste-reports/{id}/` - Delete waste report
- `GET /buyers/` - List buyers

Authentication uses token-based auth stored securely in flutter_secure_storage.

## Building for Release

### Android APK

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle

```bash
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## Troubleshooting

### Connection Issues

1. **Emulator can't connect to backend:**
   - Ensure Django is running at 127.0.0.1:8000
   - Use `http://10.0.2.2:8000/api/` for Android emulator
   - Check `network_security_config.xml` allows cleartext traffic

2. **Physical device can't connect:**
   - Ensure device and computer are on same network
   - Update API base URL with computer's IP address
   - Disable firewall temporarily for testing

### Location Issues

- Grant location permission when prompted
- Enable GPS on device
- For emulator, set location via Extended Controls

### Camera Issues

- Grant camera permission when prompted
- For emulator, use webcam or virtual scene

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.1          # State management
  http: ^1.1.0              # HTTP client
  dio: ^5.4.0               # Advanced HTTP client
  image_picker: ^1.0.7      # Image capture
  geolocator: ^11.0.0       # GPS location
  flutter_secure_storage: ^9.0.0  # Secure storage
  cached_network_image: ^3.3.0    # Image caching
```

## Development

### Hot Reload

While the app is running, press `r` in the terminal to hot reload changes.

### Debug Mode

The app runs in debug mode by default with:
- Hot reload enabled
- Debug banner
- Performance overlay available

### Testing

Run tests with:
```bash
flutter test
```

## Support

For issues or questions:
1. Check the main project README
2. Review API documentation in `API_DOCUMENTATION.md`
3. Check Flutter setup guide in `FLUTTER_SETUP_GUIDE.md`

## License

Part of the EcoWaste project.
