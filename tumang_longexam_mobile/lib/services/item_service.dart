import '../constants.dart';
import 'dart:convert';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inquiry_model.dart';

class ItemService {
  Map<dynamic, dynamic> mapData = {};

  Future<Map> getAllItem({
    int page = 1,
    int limit = 10,
    bool activeOnly = false,
    bool inactiveOnly = false,
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
    String search = '',
  }) async {
    String queryParams =
        'page=$page&limit=$limit&sortBy=$sortBy&sortOrder=$sortOrder';
    if (search.isNotEmpty) {
      queryParams += '&search=${Uri.encodeComponent(search)}';
    }
    String endpoint = '/api/items';

    print('ItemService Debug - Query params: $queryParams');

    if (activeOnly) {
      queryParams += '&active=true';
    } else if (inactiveOnly) {
      // Use the protected archived endpoint for inactive items
      endpoint = '/api/items/archived';
      queryParams += '&inactive=true';
    }

    final uri = Uri.parse('$host$endpoint?$queryParams');

    // Add authentication headers for archived items
    Map<String, String> headers = {};
    if (inactiveOnly) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }

    final response = await get(uri, headers: headers);
    if (response.statusCode == 200) {
      mapData = jsonDecode(response.body);
      // Transform the response to match expected format
      return {
        'success': true,
        'items': mapData['items'] ?? [],
        'total': mapData['total'] ?? 0,
        'page': mapData['page'] ?? page,
        'totalPages': mapData['totalPages'] ?? 1,
      };
    } else {
      throw Exception('Unable to load items');
    }
  }

  Future<Map> createItem(dynamic article) async {
    // Get user token for authentication
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await post(
      Uri.parse('$host/api/items'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(article),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception('Unable to create item');
    }
  }

  Future<Map> updateItem(String id, dynamic article) async {
    // Get user token for authentication
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    print('Updating item with ID: $id');
    print('Update data: ${jsonEncode(article)}');
    print('Full URL: $host/api/items/$id');

    final response = await put(
      Uri.parse('$host/api/items/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(article),
    );

    print('Update response status: ${response.statusCode}');
    print('Update response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception('Unable to update item');
    }
  }

  Future<Map> deleteItem(String id, dynamic article) async {
    // Get user token for authentication
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('User not authenticated');
    }

    final response = await delete(
      Uri.parse('$host/api/items/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(article),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      mapData = jsonDecode(response.body);
      return mapData;
    } else {
      throw Exception('Unable to delete item');
    }
  }

  // Wishlist methods - Temporary local storage implementation
  Future<Map> addToWishlist(String itemId) async {
    try {
      // Get user token for authentication
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Try backend first
      final response = await post(
        Uri.parse('$host/api/items/wishlist/add'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'itemId': itemId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        mapData = jsonDecode(response.body);
        return mapData;
      }
    } catch (e) {
      // Backend not available, use local storage
      print('Backend wishlist not available, using local storage: $e');
    }

    // Local storage fallback
    final prefs = await SharedPreferences.getInstance();
    final wishlist = prefs.getStringList('wishlist') ?? [];
    if (!wishlist.contains(itemId)) {
      wishlist.add(itemId);
      await prefs.setStringList('wishlist', wishlist);
    }

    return {'success': true, 'message': 'Added to wishlist', 'data': wishlist};
  }

  Future<Map> removeFromWishlist(String itemId) async {
    try {
      // Get user token for authentication
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Try backend first
      final response = await post(
        Uri.parse('$host/api/items/wishlist/remove'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'itemId': itemId}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        mapData = jsonDecode(response.body);
        return mapData;
      }
    } catch (e) {
      // Backend not available, use local storage
      print('Backend wishlist not available, using local storage: $e');
    }

    // Local storage fallback
    final prefs = await SharedPreferences.getInstance();
    final wishlist = prefs.getStringList('wishlist') ?? [];
    wishlist.remove(itemId);
    await prefs.setStringList('wishlist', wishlist);

    return {
      'success': true,
      'message': 'Removed from wishlist',
      'data': wishlist,
    };
  }

  Future<Map> getWishlist({int page = 1, int limit = 10}) async {
    try {
      // Get user token for authentication
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Try backend first
      final response = await get(
        Uri.parse('$host/api/items/wishlist?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        mapData = jsonDecode(response.body);
        return {
          'success': true,
          'data': mapData['data'] ?? [],
          'total': mapData['total'] ?? 0,
          'page': mapData['page'] ?? page,
          'totalPages': mapData['totalPages'] ?? 1,
        };
      }
    } catch (e) {
      // Backend not available, use local storage
      print('Backend wishlist not available, using local storage: $e');
    }

    // Local storage fallback - get wishlist item IDs and fetch full item data
    final prefs = await SharedPreferences.getInstance();
    final wishlistIds = prefs.getStringList('wishlist') ?? [];

    if (wishlistIds.isEmpty) {
      return {'success': true, 'data': []};
    }

    // Get all items and filter by wishlist IDs
    final allItemsResponse = await getAllItem();
    final allItems = (allItemsResponse['items'] ?? allItemsResponse) as dynamic;
    final List data = allItems is List ? allItems : (allItems['data'] ?? []);

    final wishlistItems = data.where((item) {
      final itemId = item['_id']?.toString() ?? '';
      return wishlistIds.contains(itemId);
    }).toList();

    return {'success': true, 'data': wishlistItems};
  }

  // Inquiry methods - Temporary local storage implementation
  Future<Map> createInquiry(Inquiry inquiry) async {
    try {
      // Get user token for authentication
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await post(
        Uri.parse('$host/api/inquiries'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'itemId': inquiry.itemId,
          'userMessage': inquiry.message,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to create inquiry');
      }
    } catch (e) {
      print('Create inquiry error: $e');
      rethrow;
    }
  }

  Future<Map> getUserInquiries({int page = 1, int limit = 10}) async {
    try {
      // Get user token for authentication
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await get(
        Uri.parse('$host/api/inquiries/user?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'inquiries': responseData['inquiries'] ?? [],
          'total': responseData['total'] ?? 0,
          'page': responseData['page'] ?? page,
          'totalPages': responseData['totalPages'] ?? 1,
        };
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to get inquiries');
      }
    } catch (e) {
      print('Get user inquiries error: $e');
      rethrow;
    }
  }

  // Get all inquiries (Admin/Editor only)
  Future<Map> getAllInquiries({int page = 1, int limit = 10}) async {
    try {
      // Get user token for authentication
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await get(
        Uri.parse('$host/api/inquiries/all?page=$page&limit=$limit'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'inquiries': responseData['inquiries'] ?? [],
          'total': responseData['total'] ?? 0,
          'page': responseData['page'] ?? page,
          'totalPages': responseData['totalPages'] ?? 1,
        };
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to get all inquiries');
      }
    } catch (e) {
      print('Get all inquiries error: $e');
      rethrow;
    }
  }

  // Reply to inquiry (Admin/Editor only)
  Future<Map> replyToInquiry(
    String inquiryId,
    String adminReply,
    String status,
  ) async {
    try {
      // Get user token for authentication
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await post(
        Uri.parse('$host/api/inquiries/$inquiryId/reply'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'adminReply': adminReply, 'status': status}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to submit reply');
      }
    } catch (e) {
      print('Reply to inquiry error: $e');
      rethrow;
    }
  }
}
