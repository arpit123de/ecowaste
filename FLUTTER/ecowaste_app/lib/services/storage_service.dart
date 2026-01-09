import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userIdKey = 'user_id';
  static const _usernameKey = 'username';
  static const _isBuyerKey = 'is_buyer';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUserId(int userId) async {
    await _storage.write(key: _userIdKey, value: userId.toString());
  }

  Future<int?> getUserId() async {
    final id = await _storage.read(key: _userIdKey);
    return id != null ? int.tryParse(id) : null;
  }

  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  Future<void> saveBuyerStatus(bool isBuyer) async {
    await _storage.write(key: _isBuyerKey, value: isBuyer.toString());
  }

  Future<bool> getBuyerStatus() async {
    final status = await _storage.read(key: _isBuyerKey);
    return status == 'true';
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
