import '../models/user.dart';

class UserData {
  static var myUser = User(
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
        "email": "john.doe@example.com"
      },
      {
        "name": "Jane Smith",
        "phone": "2222222222",
        "email": "jane.smith@example.com"
      }
    ],
  );
}