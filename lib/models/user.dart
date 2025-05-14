class User {
  String imagePath;
  String name;
  String surname;
  String email;
  String phone;
  String address;
  bool isDarkMode;
  List<Map<String, String>> relatives; // List of maps to store relatives' data

  User({
    required this.imagePath,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.address,
    required this.isDarkMode,
    required this.relatives, // Initialize the relatives list
  });
}
