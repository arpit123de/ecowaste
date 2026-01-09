import 'dart:io';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  
  bool _isAuthenticated = false;
  User? _user;
  bool _isLoading = false;
  bool _isBuyer = false;

  bool get isAuthenticated => _isAuthenticated;
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isBuyer => _isBuyer;
  String? get token => _apiService.token;

  Future<void> register({
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
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.register(
        username: username,
        email: email,
        password: password,
        password2: password2,
        firstName: firstName,
        lastName: lastName,
        role: role,
        mobile: mobile,
        shopName: shopName,
        shopAddress: shopAddress,
        aadhaar: aadhaar,
        wasteTypes: wasteTypes,
        shopPhoto: shopPhoto,
        tradeLicense: tradeLicense,
      );
      
      _isAuthenticated = true;
      _user = User.fromJson(data['user']);
      _isBuyer = true;
      
      await _storageService.saveToken(data['token']);
      await _storageService.saveUserId(_user!.id);
      await _storageService.saveUsername(_user!.username);
      await _storageService.saveBuyerStatus(true);
      
      _apiService.setToken(data['token']);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.login(username, password);
      _isAuthenticated = true;
      _user = User.fromJson(data['user']);
      _isBuyer = data['is_buyer'] ?? false;
      
      print('Auth Provider - Is Buyer: $_isBuyer');
      print('Auth Provider - User: ${_user?.username}');
      
      await _storageService.saveToken(data['token']);
      await _storageService.saveUserId(_user!.id);
      await _storageService.saveUsername(_user!.username);
      await _storageService.saveBuyerStatus(_isBuyer);
      
      _apiService.setToken(data['token']);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> registerBuyer({
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
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.registerBuyer(
        fullName: fullName,
        username: username,
        email: email,
        mobile: mobile,
        password: password,
        shopName: shopName,
        shopType: shopType,
        shopAddress: shopAddress,
        wasteCategories: wasteCategories,
        aadhaarNumber: aadhaarNumber,
      );
      
      _isAuthenticated = true;
      _user = User.fromJson(data['user']);
      _isBuyer = true;
      
      await _storageService.saveToken(data['token']);
      await _storageService.saveUserId(_user!.id);
      await _storageService.saveUsername(_user!.username);
      await _storageService.saveBuyerStatus(true);
      
      _apiService.setToken(data['token']);
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.logout();
      _isAuthenticated = false;
      _user = null;
      _isBuyer = false;
      await _storageService.clearAll();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkAuth() async {
    final token = await _storageService.getToken();
    if (token != null) {
      _apiService.setToken(token);
      try {
        _user = await _apiService.getUserProfile();
        _isBuyer = await _storageService.getBuyerStatus();
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } catch (e) {
        await _storageService.clearAll();
        _isAuthenticated = false;
        _isBuyer = false;
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<void> loadUserProfile() async {
    try {
      _user = await _apiService.getUserProfile();
      notifyListeners();
    } catch (e) {
      print('Failed to load user profile: $e');
    }
  }
}
