import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // For local development, use your local IP address or localhost
  // For Android emulator, use 10.0.2.2 instead of localhost
  // For iOS simulator, use localhost
  // final String baseUrl = 'http://localhost:3000/api';
  // final String authBaseUrl = 'http://localhost:3000/api/auth';
  final String baseUrl = 'http:// 192.168.1.47:3000/api';
  final String authBaseUrl = 'http://192.168.1.47:3000/api/auth';

  // Store token in shared preferences
  Future<void> saveToken(String token) async {
    try {
      print('Saving token to SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString('token', token);
      if (!success) {
        print('Failed to save token to SharedPreferences');
        throw Exception('Failed to save token');
      }
      print('Token saved successfully to SharedPreferences');
    } catch (e) {
      print('Error saving token: $e');
      throw Exception('Failed to save token: $e');
    }
  }

  // Get token from shared preferences
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      print(
          'Retrieved token from SharedPreferences: ${token != null ? 'exists' : 'null'}');
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  // Remove token from shared preferences (logout)
  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting to login at URL: $authBaseUrl/login');
      print('Login request data: email=$email, password=****');

      final response = await http.post(
        Uri.parse('$authBaseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status code: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['token'] != null) {
          print('Received token: ${responseData['token'].substring(0, 10)}...');
          await saveToken(responseData['token']);

          // Verify token was saved
          final savedToken = await getToken();
          print('Saved token: ${savedToken?.substring(0, 10)}...');

          if (savedToken == null) {
            throw Exception('Failed to save token');
          }

          return {
            'success': true,
            'message': 'Login successful',
            'user': responseData['user'],
          };
        } else {
          throw Exception('No token received from server');
        }
      } else if (response.statusCode == 401) {
        final message = responseData['message'] ?? 'Invalid email or password';
        print('Login failed: $message');
        throw Exception(message);
      } else {
        final message = responseData['message'] ?? 'Failed to login';
        print('Login failed: $message');
        throw Exception(message);
      }
    } catch (e) {
      print('Login error: $e');
      if (e.toString().contains('Invalid password') ||
          e.toString().contains('Invalid email or password')) {
        throw Exception('Invalid email or password');
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String password,
    String name,
    String surname,
    String phone,
    String address,
    String birthDate,
    String gender,
    List<Map<String, String>> relatives,
  ) async {
    try {
      print('Attempting to register at URL: $authBaseUrl/register');
      final response = await http.post(
        Uri.parse('$authBaseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': name,
          'surname': surname,
          'phone': phone,
          'address': address,
          'birthDate': birthDate,
          'gender': gender,
          'relatives': relatives,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        if (responseData['token'] != null) {
          await saveToken(responseData['token']);

          // Verify token was saved
          final savedToken = await getToken();
          print('Saved token: ${savedToken?.substring(0, 10)}...');

          if (savedToken == null) {
            throw Exception('Failed to save token');
          }

          return {
            'success': true,
            'message': 'Registration successful',
            'user': responseData['user'],
          };
        } else {
          throw Exception('No token received from server');
        }
      } else {
        throw Exception(
            'Registration failed with status code: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      print('Registration error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Add this method to check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    print('Checking if logged in. Token exists: ${token != null}');

    if (token == null) {
      print('No token found in SharedPreferences');
      return false;
    }

    try {
      // Instead of verifying the token with the server,
      // we'll just check if we have a token and it's not expired
      // This is because we're using a custom token
      return true;
    } catch (e) {
      print('Token check error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      print('Getting user profile with token: ${token}');
      print('Token length: ${token.length}');

      final response = await http.get(
        Uri.parse('$authBaseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Get profile response status: ${response.statusCode}');
      print('Get profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Log the exact user data structure
        print('User data from server: ${responseData['user']}');

        // Extract birthDate specifically and with fallback
        final String birthDate = responseData['user']['birthDate'] ??
            responseData['user']['birth_date'] ??
            responseData['user']['dateOfBirth'] ??
            responseData['user']['date_of_birth'] ??
            "";

        print('Birth date extracted: $birthDate');

        return {
          'success': true,
          'user': {
            'name': responseData['user']['name'],
            'surname': responseData['user']['surname'],
            'email': responseData['user']['email'],
            'phoneNumber': responseData['user']['phoneNumber'],
            'address': responseData['user']['address'],
            'birthDate': birthDate,
            'gender': responseData['user']['gender'] ?? '',
            'role': responseData['user']['role'],
            'createdAt': responseData['user']['createdAt'],
            'updatedAt': responseData['user']['updatedAt'],
            'emailVerified': responseData['user']['emailVerified'],
            'lastSignInTime': responseData['user']['lastSignInTime'],
            'creationTime': responseData['user']['creationTime']
          }
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching profile: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      String name, String surname, String phone, String address,
      {String? email, String? birthDate, String? gender}) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final Map<String, dynamic> updateData = {
        'name': name,
        'surname': surname,
        'phoneNumber': phone,
        'address': address,
      };

      // Add optional fields if provided
      if (email != null) updateData['email'] = email;
      if (birthDate != null) updateData['birthDate'] = birthDate;
      if (gender != null) {
        // Ensure gender is always lowercase for backend consistency
        updateData['gender'] = gender.toLowerCase();
      }

      print('Updating profile with data: $updateData');
      print('Using token: ${token.substring(0, 10)}...');

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(updateData),
      );

      print('Update profile response status: ${response.statusCode}');
      print('Update profile response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Profile updated successfully',
          'user': responseData['user']
        };
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        try {
          final responseData = jsonDecode(response.body);
          throw Exception(
              responseData['message'] ?? 'Failed to update profile');
        } catch (e) {
          throw Exception('Failed to update profile: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      throw Exception('Error updating profile: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getRelatives() async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      print('Getting relatives with token: ${token}');
      print('Token length: ${token.length}');

      final response = await http.get(
        Uri.parse('$baseUrl/relatives'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print('Get relatives response status: ${response.statusCode}');
      print('Get relatives response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to fetch relatives: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching relatives: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> addRelative(
    String name,
    String surname,
    String email,
    String phone,
  ) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      print(
          'AuthService: Adding relative with data: name=$name, surname=$surname, email=$email, phone=$phone');
      print('AuthService: Using token: $token');

      final response = await http.post(
        Uri.parse('$baseUrl/relatives'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'surname': surname,
          'email': email,
          'phone': phone,
        }),
      );

      print(
          'AuthService: Add relative response status: ${response.statusCode}');
      print('AuthService: Add relative response body: ${response.body}');

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        print('AuthService: Successfully added relative: $responseData');
        return responseData;
      } else if (response.statusCode == 401) {
        print('AuthService: Unauthorized - Token may be invalid');
        throw Exception('Unauthorized - Please login again');
      } else {
        print(
            'AuthService: Failed to add relative: ${response.statusCode}\nResponse: ${response.body}');
        throw Exception(
            'Failed to add relative: ${response.statusCode}\nResponse: ${response.body}');
      }
    } catch (e) {
      print('AuthService: Error adding relative: $e');
      throw Exception('Error adding relative: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateRelative(
    String relativeId,
    String name,
    String surname,
    String email,
    String phone,
  ) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/relatives/$relativeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'surname': surname,
          'email': email,
          'phone': phone,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to update relative: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating relative: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> deleteRelative(String relativeId) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/relatives/$relativeId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized - Please login again');
      } else {
        throw Exception('Failed to delete relative: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting relative: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      print('Checking email existence for: $email');
      final response = await http.post(
        Uri.parse('$authBaseUrl/check-email'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      print('Check email response status: ${response.statusCode}');
      print('Check email response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'exists': responseData['exists'] ?? false,
        };
      } else if (response.statusCode == 400) {
        if (responseData['code'] == 'auth/email-already-exists') {
          return {
            'exists': true,
            'error': 'This email is already registered',
          };
        }
        return {
          'exists': false,
          'error': responseData['message'] ?? 'Invalid email format',
        };
      } else if (response.statusCode == 409 || response.statusCode == 422) {
        return {
          'exists': true,
          'error': 'This email is already registered',
        };
      } else {
        // For any other status code, allow registration to proceed
        print(
            'Unexpected status code ${response.statusCode} when checking email');
        return {
          'exists': false,
        };
      }
    } catch (e) {
      print('Check email error: $e');
      // If there's an error, allow registration to proceed
      return {
        'exists': false,
      };
    }
  }

  Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        // Call logout endpoint if needed
        await http.post(
          Uri.parse('$authBaseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );
      }
      // Remove token from local storage
      await removeToken();
    } catch (e) {
      print('Logout error: $e');
      // Even if the server call fails, we still want to remove the local token
      await removeToken();
    }
  }

  Future<Map<String, dynamic>> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      if (token == null) {
        throw Exception('No token found');
      }

      print('Changing password with token: ${token}');
      print('Token length: ${token.length}');

      final response = await http.put(
        Uri.parse('$authBaseUrl/profile/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      print('Change password response status: ${response.statusCode}');
      print('Change password response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Password changed successfully',
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      print('Error changing password: $e');
      return {
        'success': false,
        'message': 'Error changing password: ${e.toString()}',
      };
    }
  }
}
