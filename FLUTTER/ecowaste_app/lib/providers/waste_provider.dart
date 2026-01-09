import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/waste_report.dart';
import '../models/buyer.dart';
import '../services/api_service.dart';

class WasteProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<WasteReport> _wasteReports = [];
  List<Buyer> _buyers = [];
  List<dynamic>? _buyerOrders = [];
  Map<String, dynamic>? _statistics;
  bool _isLoading = false;
  String? _error;

  List<WasteReport> get wasteReports => _wasteReports;
  List<Buyer> get buyers => _buyers;
  List<dynamic>? get buyerOrders => _buyerOrders;
  Map<String, dynamic>? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setApiToken(String token) {
    _apiService.setToken(token);
  }

  Future<void> loadWasteReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _wasteReports = await _apiService.getWasteReports();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createWasteReport(WasteReport report, XFile? imageFile) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newReport = await _apiService.createWasteReport(report, imageFile);
      _wasteReports.insert(0, newReport);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteWasteReport(int id) async {
    try {
      await _apiService.deleteWasteReport(id);
      _wasteReports.removeWhere((report) => report.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> loadStatistics() async {
    try {
      _statistics = await _apiService.getStatistics();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadBuyers({String? wasteType, String? city}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _buyers = await _apiService.getBuyers(wasteType: wasteType, city: city);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> classifyWasteImage(XFile imageFile) async {
    try {
      return await _apiService.classifyWasteImage(imageFile);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> fetchWasteReports() async {
    await loadWasteReports();
  }

  Future<void> loadAvailableWaste() async {
    await loadWasteReports();
  }

  Future<void> loadBuyerOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Mock implementation - replace with actual API call
      _buyerOrders = [];
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getBuyerStats() async {
    try {
      return await _apiService.getBuyerStats();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendPickupRequest({
    required int wasteReportId,
    required DateTime pickupDate,
    required String pickupTime,
    required double priceOffer,
    String? message,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _apiService.sendPickupRequest(
        wasteReportId: wasteReportId,
        pickupDate: pickupDate,
        pickupTime: pickupTime,
        priceOffer: priceOffer,
        message: message,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      return await _apiService.getNotifications();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markNotificationRead(int notificationId) async {
    try {
      await _apiService.markNotificationRead(notificationId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _apiService.markAllNotificationsRead();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getUnreadNotificationCount() async {
    try {
      return await _apiService.getUnreadNotificationCount();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approvePickupRequest(int requestId, String address) async {
    try {
      await _apiService.approvePickupRequest(requestId, address);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectPickupRequest(int requestId) async {
    try {
      await _apiService.rejectPickupRequest(requestId);
    } catch (e) {
      rethrow;
    }
  }
}

