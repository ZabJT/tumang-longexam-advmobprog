import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';

class UserService {
  Map<String, dynamic> data = {};

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    print('Attempting login with host: $host');
    print('Full URL: $host/api/users/login');

    final response = await http.post(
      Uri.parse('$host/api/users/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 401 || response.statusCode == 404) {
      // For security, always show the same message for invalid credentials
      // Whether email doesn't exist (404) or password is wrong (401)
      throw Exception('Invalid email or password');
    } else {
      throw Exception('Login failed. Please try again');
    }
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('firstName', userData['firstName'] ?? '');
    await prefs.setString('token', userData['token'] ?? '');
    await prefs.setString('type', userData['type'] ?? '');
  }

  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'firstName': prefs.getString('firstName') ?? '',
      'token': prefs.getString('token') ?? '',
      'type': prefs.getString('type') ?? '',
    };
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<Map<String, dynamic>> getPendingUsers({
    int page = 1,
    int limit = 10,
  }) async {
    final response = await http.get(
      Uri.parse('$host/api/users/pending?page=$page&limit=$limit'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {
        'success': true,
        'users': responseData['users'] ?? [],
        'total': responseData['total'] ?? 0,
        'page': responseData['page'] ?? page,
        'totalPages': responseData['totalPages'] ?? 1,
      };
    } else {
      throw Exception('Failed to load pending users: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> approveUser(String userId) async {
    final response = await http.patch(
      Uri.parse('$host/api/users/$userId/approve'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to approve user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> rejectUser(String userId) async {
    final response = await http.patch(
      Uri.parse('$host/api/users/$userId/reject'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reject user: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final userData = await getUserData();
    final token = userData['token'];

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found. Please login again.');
    }

    final response = await http.get(
      Uri.parse('$host/api/users/me'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      // Token expired or invalid - clear stored data and redirect to login
      await logout();
      throw Exception('Session expired. Please login again.');
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> userData,
  ) async {
    final response = await http.post(
      Uri.parse('$host/api/users'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(userData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 400) {
      final body = jsonDecode(response.body);
      if (body['message']?.toString().toLowerCase().contains('email') == true) {
        throw Exception('Email already registered');
      }
      if (body['message']?.toString().toLowerCase().contains('username') ==
          true) {
        throw Exception('Username already taken');
      }
      throw Exception('Invalid information. Please check your details');
    } else {
      throw Exception('Registration failed. Please try again');
    }
  }
}
