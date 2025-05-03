import '../models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserData {
  static final _storage = FlutterSecureStorage();
  static var myUser = User(
    id: null,
    imagePath:
        'https://images.unsplash.com/photo-1554151228-14d9def656e4?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=333&q=80',
    name: 'Sarah Abs',
    email: 'sarah.abs@gmail.com',
    phone: '0000 0000',
    address: '123 Main Street, Springfield, IL, 62701, USA',
    isDarkMode: false,
    relatives: [
      {
        "name": "John Doe",
        "phone": "1111111111",
        "email": "john.doe@example.com",
      },
      {
        "name": "Jane Smith",
        "phone": "2222222222",
        "email": "jane.smith@example.com",
      },
    ],
  );

  static Future<void> updateUser(Map<String, dynamic> data) async {
    try {
      print('Updating user with data: $data');

      if (data == null) {
        print('Data is null');
        return;
      }

      final userData = data['user'];
      if (userData == null) {
        print('User data is null');
        return;
      }

      print('User data: $userData');

      myUser = User(
        id: userData['id']?.toString(),
        email: userData['email']?.toString() ?? '',
        name: userData['username']?.toString() ?? '',
        token: data['token']?.toString(),
        imagePath:
            'https://images.unsplash.com/photo-1554151228-14d9def656e4?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=333&q=80',
        phone: '',
        address: '',
        isDarkMode: false,
        relatives: [],
      );

      if (data['token'] != null) {
        await _storage.write(key: 'token', value: data['token']);
      }
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
    myUser = User(
      id: null,
      imagePath: myUser.imagePath,
      name: myUser.name,
      email: myUser.email,
      phone: myUser.phone,
      address: myUser.address,
      isDarkMode: myUser.isDarkMode,
      relatives: myUser.relatives,
    );
  }
}
