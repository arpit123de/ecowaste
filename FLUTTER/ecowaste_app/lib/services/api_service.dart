import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/user.dart';
import '../models/waste_report.dart';
import '../models/buyer.dart';

class ApiService {
  // Change based on your setup:
  // Android Emulator: http://10.0.2.2:8000
  // iOS Simulator: http://127.0.0.1:8000
  // Physical Device: http://YOUR_LOCAL_IP:8000
  // Web (Chrome): http://127.0.0.1:8000
  static const String baseUrl = 'http://127.0.0.1:8000/api';
  
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Token $_token',
  };

  // Authentication
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String password2,
    String? firstName,
    String? lastName,
    String? role,
    String? mobile,
    String? shopName,
    String? shopAddress,
    String? aadhaar,
    List<String>? wasteTypes,
    File? shopPhoto,
    File? tradeLicense,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/auth/register/'),
    );

    // Add text fields
    request.fields['username'] = username;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['password2'] = password2;
    if (firstName != null) request.fields['first_name'] = firstName;
    if (lastName != null) request.fields['last_name'] = lastName;
    if (role != null) request.fields['role'] = role;
    
    // Add buyer-specific fields
    if (role == 'buyer') {
      if (mobile != null) request.fields['mobile'] = mobile;
      if (shopName != null) request.fields['shop_name'] = shopName;
      if (shopAddress != null) request.fields['shop_address'] = shopAddress;
      if (aadhaar != null) request.fields['aadhaar'] = aadhaar;
      if (wasteTypes != null) request.fields['waste_types'] = jsonEncode(wasteTypes);
      
      // Add files
      if (shopPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'shop_photo',
          shopPhoto.path,
        ));
      }
      if (tradeLicense != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'trade_license',
          tradeLicense.path,
        ));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      return data;
    } else {
      throw Exception(jsonDecode(response.body).toString());
    }
  }

  Future<Map<String, dynamic>> registerBuyer({
    required String fullName,
    required String username,
    required String email,
    required String mobile,
    required String password,
    required String shopName,
    required String shopType,
    required String shopAddress,
    required List<String> wasteCategories,
    required String aadhaarNumber,
  }) async {
    try {
      final requestBody = {
        'role': 'buyer',
        'username': username,
        'email': email,
        'password': password,
        'password2': password, // Django requires password confirmation
        'first_name': fullName.split(' ').first,
        'last_name': fullName.split(' ').length > 1 ? fullName.split(' ').sublist(1).join(' ') : '',
        'mobile': mobile,
        'shop_name': shopName,
        'shop_type': shopType,
        'shop_address': shopAddress,
        'waste_types': jsonEncode(wasteCategories),
        'aadhaar': aadhaarNumber,
      };
      
      print('Buyer Registration Request to: $baseUrl/auth/register/');
      print('Request body: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error'] ?? errorData.toString();
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Registration error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    print('Login request to: $baseUrl/auth/login/');
    print('Username: $username');
    
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
      }),
    );

    print('Login response status: ${response.statusCode}');
    print('Login response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'];
      print('Is buyer from API: ${data['is_buyer']}');
      return data;
    } else {
      throw Exception('Invalid credentials');
    }
  }

  Future<void> logout() async {
    try {
      await http.post(
        Uri.parse('$baseUrl/auth/logout/'),
        headers: _headers,
      );
    } catch (e) {
      print('Logout error: $e');
    }
    _token = null;
  }

  Future<User> getUserProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/profile/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load profile');
    }
  }

  // Waste Reports
  Future<List<WasteReport>> getWasteReports() async {
    final response = await http.get(
      Uri.parse('$baseUrl/waste-reports/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;
      return results.map((json) => WasteReport.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load waste reports');
    }
  }

  Future<WasteReport> createWasteReport(
    WasteReport report,
    XFile? imageFile,
  ) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/waste-reports/'),
    );

    request.headers['Authorization'] = 'Token $_token';

    // Add fields
    final jsonData = report.toJson();
    jsonData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // Add image if present
    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
        ),
      );
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return WasteReport.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create waste report: ${response.body}');
    }
  }

  Future<WasteReport> getWasteReport(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/waste-reports/$id/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return WasteReport.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load waste report');
    }
  }

  Future<void> deleteWasteReport(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/waste-reports/$id/'),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete waste report');
    }
  }

  Future<Map<String, dynamic>> getStatistics() async {
    final response = await http.get(
      Uri.parse('$baseUrl/waste-reports/statistics/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load statistics');
    }
  }

  // Buyers
  Future<List<Buyer>> getBuyers({String? wasteType, String? city}) async {
    var uri = Uri.parse('$baseUrl/buyers/');
    
    if (wasteType != null || city != null) {
      uri = Uri.parse('$baseUrl/buyers/').replace(queryParameters: {
        if (wasteType != null) 'waste_type': wasteType,
        if (city != null) 'city': city,
      });
    }

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final results = data['results'] as List;
      return results.map((json) => Buyer.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load buyers');
    }
  }

  Future<Buyer> getBuyer(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/buyers/$id/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return Buyer.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load buyer');
    }
  }

  // AI Classification
  Future<Map<String, dynamic>> classifyWasteImage(XFile imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/waste-reports/classify/'),
    );

    request.headers['Authorization'] = 'Token $_token';
    
    final bytes = await imageFile.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: imageFile.name,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to classify image: ${response.body}');
    }
  }

  // Pickup Requests
  Future<void> sendPickupRequest({
    required int wasteReportId,
    required DateTime pickupDate,
    required String pickupTime,
    required double priceOffer,
    String? message,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pickup-requests/'),
      headers: _headers,
      body: jsonEncode({
        'waste_report': wasteReportId,
        'offered_price': priceOffer.toString(),
        'proposed_time_slot_1': pickupDate.toIso8601String(),
        'message': message ?? '',
      }),
    );

    if (response.statusCode != 201) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to send pickup request');
    }
  }

  // Get buyer statistics
  Future<Map<String, dynamic>> getBuyerStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/buyers/stats/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load buyer stats');
    }
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final dynamic data = jsonDecode(response.body);
      // Handle both paginated and non-paginated responses
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      } else if (data is Map && data.containsKey('results')) {
        // DRF paginated response
        final List<dynamic> results = data['results'];
        return results.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markNotificationRead(int notificationId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/$notificationId/mark_read/'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }

  Future<void> markAllNotificationsRead() async {
    final response = await http.post(
      Uri.parse('$baseUrl/notifications/mark_all_read/'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark all notifications as read');
    }
  }

  Future<int> getUnreadNotificationCount() async {
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/unread_count/'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['unread_count'] as int;
    } else {
      throw Exception('Failed to get unread count');
    }
  }

  // Approve/Reject pickup requests
  Future<void> approvePickupRequest(int requestId, String address) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pickup-requests/$requestId/approve/'),
      headers: _headers,
      body: jsonEncode({
        'confirmed_pickup_address': address,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to approve pickup request');
    }
  }

  Future<void> rejectPickupRequest(int requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/pickup-requests/$requestId/reject/'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to reject pickup request');
    }
  }
}

