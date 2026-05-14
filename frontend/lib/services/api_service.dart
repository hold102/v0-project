import 'dart:convert';
import 'dart:io';
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
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  // Change this to your Mac's local IP when testing from a phone
  static const String _hostIp = '192.168.100.179';

  String get _baseUrl {
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    if (kIsWeb && !_isLocalhost) return 'http://$_hostIp:3000/api';
    return 'http://localhost:3000/api';
  }

  bool get _isLocalhost {
    try {
      return Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1';
    } catch (_) {
      return true;
    }
  }

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
    String? category,
    String? date,
  }) async {
    final body = <String, dynamic>{};
    if (description != null) body['description'] = description;
    if (amount != null) body['amount'] = amount;
    if (paidBy != null) body['paidBy'] = paidBy;
    if (splitBetween != null) body['splitBetween'] = splitBetween;
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
    required String from,
    required String to,
    required double amount,
    String? groupId,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/settlements'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'from': from,
        'to': to,
        'amount': amount,
        'groupId': groupId ?? 'g1',
      }),
    );
    return jsonDecode(res.body);
  }
}
