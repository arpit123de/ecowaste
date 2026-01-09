# EcoWaste API Documentation

## Base URL
`http://127.0.0.1:8000/api/`

## Authentication
The API uses Token Authentication. Include the token in the header:
```
Authorization: Token <your-token-here>
```

---

## Authentication Endpoints

### Register User
**POST** `/api/auth/register/`

Request body:
```json
{
    "username": "testuser",
    "email": "test@example.com",
    "password": "securepassword",
    "password2": "securepassword",
    "first_name": "John",
    "last_name": "Doe"
}
```

Response:
```json
{
    "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b",
    "user": {
        "id": 1,
        "username": "testuser",
        "email": "test@example.com",
        "first_name": "John",
        "last_name": "Doe"
    },
    "message": "User registered successfully"
}
```

### Login
**POST** `/api/auth/login/`

Request body:
```json
{
    "username": "testuser",
    "password": "securepassword"
}
```

Response:
```json
{
    "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b",
    "user": {
        "id": 1,
        "username": "testuser",
        "email": "test@example.com",
        "first_name": "John",
        "last_name": "Doe"
    }
}
```

### Logout
**POST** `/api/auth/logout/`
(Requires authentication)

Response:
```json
{
    "message": "Logged out successfully"
}
```

### Get Profile
**GET** `/api/auth/profile/`
(Requires authentication)

---

## Waste Reports

### List Waste Reports
**GET** `/api/waste-reports/`

### Create Waste Report
**POST** `/api/waste-reports/`
(Multipart form data for image upload)

Request body:
```json
{
    "name": "John Doe",
    "mobile_number": "+919876543210",
    "email": "john@example.com",
    "waste_type": "plastic",
    "quantity_type": "small",
    "exact_quantity": 5.0,
    "waste_condition": "mixed",
    "image": "<file>",
    "location_auto": true,
    "latitude": "28.61394",
    "longitude": "77.20902",
    "area": "Connaught Place",
    "city": "New Delhi",
    "state": "Delhi",
    "full_address": "123 Main Street",
    "additional_notes": "Pickup before 6 PM"
}
```

### Get Single Waste Report
**GET** `/api/waste-reports/{id}/`

### Update Waste Report
**PUT** `/api/waste-reports/{id}/`
**PATCH** `/api/waste-reports/{id}/`

### Delete Waste Report
**DELETE** `/api/waste-reports/{id}/`

### Get Statistics
**GET** `/api/waste-reports/statistics/`

Response:
```json
{
    "total_reports": 15,
    "pending": 5,
    "scheduled": 7,
    "completed": 3,
    "by_type": {
        "plastic": 8,
        "paper": 4,
        "e_waste": 3
    }
}
```

---

## Buyers

### List Buyers
**GET** `/api/buyers/`

Query parameters:
- `waste_type`: Filter by waste type accepted
- `city`: Filter by city

### Get Single Buyer
**GET** `/api/buyers/{id}/`

### Get Buyer Ratings
**GET** `/api/buyers/{id}/ratings/`

---

## Pickup Requests

### List Pickup Requests
**GET** `/api/pickup-requests/`

### Create Pickup Request
**POST** `/api/pickup-requests/`

Request body:
```json
{
    "waste_report": 1,
    "requested_pickup_date": "2026-01-15",
    "requested_pickup_time": "14:00:00",
    "message": "Please collect between 2-4 PM"
}
```

### Accept Pickup Request (Buyer only)
**POST** `/api/pickup-requests/{id}/accept/`

Request body:
```json
{
    "confirmed_pickup_date": "2026-01-15",
    "confirmed_pickup_time": "15:00:00",
    "confirmed_pickup_address": "123 Main Street, Delhi",
    "price_offer": 250.00
}
```

### Complete Pickup
**POST** `/api/pickup-requests/{id}/complete/`

Request body:
```json
{
    "notes": "Pickup completed successfully"
}
```

---

## Ratings

### List Ratings
**GET** `/api/ratings/`

### Create Rating
**POST** `/api/ratings/`

Request body:
```json
{
    "buyer": 1,
    "pickup_request": 5,
    "rating": 5,
    "review": "Excellent service!"
}
```

---

## Pickup History

### List Pickup History
**GET** `/api/pickup-history/`

### Get Single History Entry
**GET** `/api/pickup-history/{id}/`

---

## Error Responses

### 400 Bad Request
```json
{
    "field_name": ["Error message"]
}
```

### 401 Unauthorized
```json
{
    "detail": "Authentication credentials were not provided."
}
```

### 403 Forbidden
```json
{
    "error": "Only buyers can accept requests"
}
```

### 404 Not Found
```json
{
    "detail": "Not found."
}
```

---

## Flutter Integration Example

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  String? _token;

  // Login
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
      throw Exception('Failed to login');
    }
  }

  // Get Waste Reports
  Future<List<dynamic>> getWasteReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/waste-reports/'),
      headers: {
        'Authorization': 'Token $_token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'];
    } else {
      throw Exception('Failed to load waste reports');
    }
  }

  // Create Waste Report with Image
  Future<Map<String, dynamic>> createWasteReport(
    Map<String, dynamic> data,
    File? imageFile,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/waste-reports/'),
    );

    request.headers['Authorization'] = 'Token $_token';

    // Add fields
    data.forEach((key, value) {
      request.fields[key] = value.toString();
    });

    // Add image if present
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
      throw Exception('Failed to create waste report');
    }
  }
}
```

---

## Notes for Flutter Development

1. **Base URL**: Use `http://10.0.2.2:8000` for Android emulator (points to localhost)
2. **Base URL**: Use `http://127.0.0.1:8000` for iOS simulator
3. **Base URL**: Use actual IP address for physical devices
4. **Image Upload**: Use `MultipartRequest` for uploading images
5. **Token Storage**: Store token securely using `flutter_secure_storage`
6. **Error Handling**: Always handle network errors and API errors appropriately

---

## Testing the API

You can test the API using:
1. **Postman**: Import endpoints and test
2. **cURL**: Command line testing
3. **DRF Browsable API**: Visit endpoints in browser (when logged in)

Example cURL:
```bash
# Register
curl -X POST http://127.0.0.1:8000/api/auth/register/ \
  -H "Content-Type: application/json" \
  -d '{"username":"test","email":"test@test.com","password":"test1234","password2":"test1234"}'

# Login
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test1234"}'

# Get waste reports (with token)
curl -X GET http://127.0.0.1:8000/api/waste-reports/ \
  -H "Authorization: Token YOUR_TOKEN_HERE"
```
