class User {
  int? id;
  String? userName;
  String? email;
  String? phoneNumber;
  String? password;

  User({
    this.id,
    required this.userName,
    required this.email,
    required this.phoneNumber,
    required this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      userName: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone'] ?? '',
      password: json['password'] ?? '',
    );
  }
}
