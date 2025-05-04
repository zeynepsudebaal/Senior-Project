class User {
  String? id;
  String imagePath;
  String name;
  String email;
  String phone;
  String address;
  bool isDarkMode;
  String? token;
  List<Map<String, String>> relatives; // List of maps to store relatives' data

  User({
    this.id,
    required this.imagePath,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.isDarkMode,
    required this.relatives, // Initialize the relatives list
    this.token, // Token parameter added
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(), // Ensure id is converted to string
      imagePath: json['imagePath'] ??
          'https://images.unsplash.com/photo-1554151228-14d9def656e4?ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&ixlib=rb-1.2.1&auto=format&fit=crop&w=333&q=80',
      name: json['username'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      isDarkMode: json['isDarkMode'] ?? false,
      relatives: (json['relatives'] as List<dynamic>?)
              ?.map((e) => Map<String, String>.from(e))
              .toList() ??
          [],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'isDarkMode': isDarkMode,
      'relatives': relatives,
      'token': token,
    };
  }
}
