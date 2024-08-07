import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';
import 'package:skilltest/models/user_model.dart';
import 'package:skilltest/services/baseurl.dart';

class SettingsScreen extends StatefulWidget {
  final Function(User) onUpdateUserData;

  SettingsScreen({required this.onUpdateUserData});
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? user1;
  late TextEditingController _userNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _passwordController;
  bool isPasswordVisible = false;

  void _loadUserDetails() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();

    try {
      String? userId = await secureStorage.read(key: 'id');
      String? name = await secureStorage.read(key: 'name');
      String? phone = await secureStorage.read(key: 'phone');
      String? email = await secureStorage.read(key: 'email');
      String? password = await secureStorage.read(key: 'password');
      print(userId);

      if (userId != null) {
        setState(() {
          user1 = User(
              id: int.parse(userId),
              userName: name,
              phoneNumber: phone,
              password: password,
              email: email);
          _fetchUserData(user1);
        });
      }
    } catch (error) {
      // Handle error
      print('Error loading user details: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    _userNameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _passwordController = TextEditingController();
    _loadUserDetails();
  }

  void togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  Future<void> _fetchUserData(user) async {
    print(user1);
    if (user != null) {
      setState(() {
        _userNameController = TextEditingController(text: user1?.userName);
        _emailController = TextEditingController(text: user1?.email);
        _phoneNumberController =
            TextEditingController(text: user1?.phoneNumber);
        _passwordController = TextEditingController(text: user1?.password);
      });
    }
  }

  Future<void> _updateUserData() async {
    // // Prepare the updated user data
    User updatedUser = User(
      id: user1?.id,
      userName: _userNameController.text,
      email: _emailController.text,
      phoneNumber: _phoneNumberController.text,
      password: _passwordController.text,
    );
    print(user1?.id);
    // Make API request to update user data
    final response = await http.put(
      Uri.parse(baseURL + 'updateprofile/${user1?.id}'),
      // Replace with your API endpoint
      body: json.encode({
        'name': _userNameController.text,
        'email': _emailController.text,
        'phone': _phoneNumberController.text,
        'password': _passwordController.text,
      }), // Convert user object to JSON
      headers: headers,
    );
    print(response.body);
    print(response.statusCode);
    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, show success message
      MotionToast.success(
        //title: Text("Delete Successfully"),
        description: Text("User data updated successfully"),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);
      widget.onUpdateUserData(updatedUser);
      final FlutterSecureStorage secureStorage = FlutterSecureStorage();
      await secureStorage.write(key: 'name', value: _userNameController.text);
      await secureStorage.write(key: 'email', value: _emailController.text);
      await secureStorage.write(
          key: 'phone', value: _phoneNumberController.text);
      await secureStorage.write(
          key: 'password', value: _passwordController.text);
    } else {
      // If the server returns an error response, show error message
      MotionToast.error(
        //title: Text("Delete Successfully"),
        description: Text("User data updated Unsuccessfully"),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);
    }

    // Clear password fields
    // _currentPasswordController.clear();
    // _newPasswordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              TextField(
                controller: _userNameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    onPressed: togglePasswordVisibility,
                    icon: Icon(
                      isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _updateUserData,
                child: Text(
                  'Save Changes',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
