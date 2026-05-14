/*
 * api_service.dart — HTTP client for the Express backend
 *
 * Singleton (one instance shared app-wide). Base URL resolution:
 *   1. If --dart-define=API_BASE_URL=... is provided at build time, use it verbatim.
 *   2. Otherwise pick a default per platform:
 *        - Web -> http://<page host>:5001/api  (uses the URL the page was served from,
 *          so localhost, 127.0.0.1, AND LAN IPs all work with no config)
 *        - Android emulator -> http://10.0.2.2:5001/api  (maps to host machine)
 *        - iOS simulator / desktop -> http://localhost:5001/api
 *        - Real mobile device -> --dart-define=API_BASE_URL=http://<mac-lan-ip>:5001/api
 *
 * Every method returns parsed model objects. On error, throws ApiException.
 */
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:splitease/models/user.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/models/expense.dart';
import 'package:splitease/models/balance.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiService {
  // Singleton pattern: one shared instance, lazy-initialised
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  // Optional full override — set with `flutter run --dart-define=API_BASE_URL=...`
  static const String _baseUrlOverride =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  String get _baseUrl {
    if (_baseUrlOverride.isNotEmpty) return _baseUrlOverride;
    if (kIsWeb) {
      // Use whatever host served the page — localhost, 127.0.0.1, or LAN IP all work.
      final host = _webHost();
      return 'http://$host:5001/api';
    }
    if (Platform.isAndroid) return 'http://10.0.2.2:5001/api';  // Android emulator
    return 'http://localhost:5001/api';  // iOS simulator / desktop
  }

  String _webHost() {
    try {
      final host = Uri.base.host;
      return host.isEmpty ? 'localhost' : host;
    } catch (_) {
      return 'localhost';
    }
  }

  // Decode a JSON object response, throw ApiException on non-2xx status
  Map<String, dynamic> _decodeObjectResponse(http.Response res) {
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message =
          decoded is Map<String, dynamic> ? decoded['error'] as String? : null;
      throw ApiException(message ?? 'Request failed.', res.statusCode);
    }
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Unexpected API response.');
    }
    return decoded;
  }

  // Decode a JSON array response
  List<dynamic> _decodeListResponse(http.Response res) {
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message =
          decoded is Map<String, dynamic> ? decoded['error'] as String? : null;
      throw ApiException(message ?? 'Request failed.', res.statusCode);
    }
    if (decoded is! List<dynamic>) {
      throw const ApiException('Unexpected API response.');
    }
    return decoded;
  }

  Group _groupFromResponse(http.Response res) {
    final json = _decodeObjectResponse(res);
    final group = json['group'];
    return Group.fromJson(
      group is Map<String, dynamic> ? group : json,
    );
  }

  Expense _expenseFromResponse(http.Response res) {
    final json = _decodeObjectResponse(res);
    final expense = json['expense'];
    return Expense.fromJson(
      expense is Map<String, dynamic> ? expense : json,
    );
  }

  Future<void> _expectSuccess(http.Response res) async {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    final message =
        decoded is Map<String, dynamic> ? decoded['error'] as String? : null;
    throw ApiException(message ?? 'Request failed.', res.statusCode);
  }

  Future<User> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    final json = _decodeObjectResponse(res);
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<User> register({
    required String name,
    required String email,
    required String password,
    String avatar = '👤',
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'avatar': avatar,
      }),
    );
    final json = _decodeObjectResponse(res);
    return User.fromJson(json['user'] as Map<String, dynamic>);
  }

  Future<List<User>> getUsers() async {
    final res = await http.get(Uri.parse('$_baseUrl/users'));
    final list = _decodeListResponse(res);
    return list.map((j) => User.fromJson(j)).toList();
  }

  // Returns the backend's canonical app state; we only need currentUserId here
  // so the Flutter "current user" matches what the backend enforces.
  Future<String?> getCurrentUserId() async {
    final res = await http.get(Uri.parse('$_baseUrl/app-state'));
    final json = _decodeObjectResponse(res);
    final id = json['currentUserId'];
    return id is String ? id : null;
  }

  Future<User> getUserById(String id) async {
    final res = await http.get(Uri.parse('$_baseUrl/users/$id'));
    return User.fromJson(_decodeObjectResponse(res));
  }

  Future<List<Group>> getGroups() async {
    final res = await http.get(Uri.parse('$_baseUrl/groups'));
    final list = _decodeListResponse(res);
    return list.map((j) => Group.fromJson(j)).toList();
  }

  Future<Group> getGroupById(String id) async {
    final res = await http.get(Uri.parse('$_baseUrl/groups/$id'));
    return _groupFromResponse(res);
  }

  Future<Group> createGroup(String name, String emoji, List<String> memberIds,
      {String? id}) async {
    final body = <String, dynamic>{
      'name': name,
      'emoji': emoji,
      'memberIds': memberIds,
    };
    if (id != null) body['id'] = id;
    final res = await http.post(
      Uri.parse('$_baseUrl/groups'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _groupFromResponse(res);
  }

  Future<Group> updateGroup({
    required String groupId,
    String? name,
    String? emoji,
    List<String>? memberIds,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (emoji != null) body['emoji'] = emoji;
    if (memberIds != null) body['memberIds'] = memberIds;

    final res = await http.put(
      Uri.parse('$_baseUrl/groups/$groupId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _groupFromResponse(res);
  }

  Future<void> deleteGroup(String id) async {
    final res = await http.delete(Uri.parse('$_baseUrl/groups/$id'));
    await _expectSuccess(res);
  }

  Future<Expense> addExpense({
    required String groupId,
    required String description,
    required double amount,
    required String paidBy,
    required List<String> splitBetween,
    required String category,
    Map<String, double>? splitAmounts,
    String? date,
    String? id,
  }) async {
    final body = <String, dynamic>{
      'description': description,
      'amount': amount,
      'paidBy': paidBy,
      'splitBetween': splitBetween,
      'category': category,
      'date': date ?? DateTime.now().toIso8601String().split('T')[0],
    };
    if (splitAmounts != null && splitAmounts.isNotEmpty) {
      body['splitAmounts'] = splitAmounts;
    }
    if (id != null) body['id'] = id;
    final res = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/expenses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _expenseFromResponse(res);
  }

  Future<void> deleteExpense(String groupId, String expenseId) async {
    final res = await http
        .delete(Uri.parse('$_baseUrl/groups/$groupId/expenses/$expenseId'));
    await _expectSuccess(res);
  }

  Future<List<Balance>> getBalances(String groupId) async {
    final res = await http.get(Uri.parse('$_baseUrl/groups/$groupId/balances'));
    final list = _decodeListResponse(res);
    return list.map((j) => Balance.fromJson(j)).toList();
  }

  Future<Map<String, dynamic>> getSummary() async {
    final res = await http.get(Uri.parse('$_baseUrl/summary'));
    return jsonDecode(res.body);
  }

  Future<Expense> updateExpense({
    required String groupId,
    required String expenseId,
    String? description,
    double? amount,
    String? paidBy,
    List<String>? splitBetween,
    Map<String, double>? splitAmounts,
    String? category,
    String? date,
  }) async {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (amount != null) body['amount'] = amount;
    if (paidBy != null) body['paidBy'] = paidBy;
    if (splitBetween != null) body['splitBetween'] = splitBetween;
    if (splitAmounts != null) body['splitAmounts'] = splitAmounts;
    if (category != null) body['category'] = category;
    if (date != null) body['date'] = date;

    final res = await http.put(
      Uri.parse('$_baseUrl/groups/$groupId/expenses/$expenseId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    return _expenseFromResponse(res);
  }

  Future<Map<String, dynamic>> recordSettlement({
    required String groupId,
    required String from,
    required String to,
    required double amount,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/groups/$groupId/settlements'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'from': from,
        'to': to,
        'amount': amount,
      }),
    );
    return jsonDecode(res.body);
  }
}
