import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';
import 'package:skilltest/services/baseurl.dart';

class ProfileManagementScreen extends StatefulWidget {
  @override
  _ProfileManagementScreenState createState() =>
      _ProfileManagementScreenState();
}

class _ProfileManagementScreenState extends State<ProfileManagementScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  Map<String, dynamic>? _userData; // To store fetched user data
  bool _isLoading = true; // For loading state

  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the screen initializes
  }

  Future<void> changePassword() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? custId = await secureStorage.read(key: 'id');

    // Check if new password and confirm password match
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('New password and confirm password do not match'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final url = baseURL + 'changepassword/$custId';

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: json.encode({
        'current_password': _currentPasswordController.text,
        'new_password': _newPasswordController.text,
      }),
    );
    if (response.statusCode == 200) {
      // Clear the text fields after successful password change
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      MotionToast.success(
        description: Text("Password Changed successfully."),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);
    } else {
      // Handle the error response
      final Map<String, dynamic> errorResponse = json.decode(response.body);
      String errorMessage = errorResponse['error'] ?? 'An error occurred';

      MotionToast.error(
        description: Text(errorMessage),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);
    }
  }

  // Function to fetch user data from the API
  Future<void> _fetchUserData() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? custId = await secureStorage.read(key: 'id');
    final String apiUrl =
        baseURL + 'getmobileuser/$custId'; // Your API endpoint

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        setState(() {
          _userData = json.decode(response.body); // Parse JSON data
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load user data');
      }
    } catch (error) {
      print('Error fetching user data: $error');
      setState(() {
        _isLoading = false; // Stop loading even if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.teal,
        title: Text(
          'Profile Management',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.purpleAccent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isLoading
                    ? Center(
                        child:
                            CircularProgressIndicator()) // Show loader while fetching data
                    : _buildProfileCard(), // Show profile card once data is fetched
                SizedBox(height: 20),
                Text(
                  'Change Password',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 10),
                _buildPasswordField(
                    'Current Password', _currentPasswordController),
                SizedBox(height: 10),
                _buildPasswordField('New Password', _newPasswordController),
                SizedBox(height: 10),
                _buildPasswordField(
                    'Confirm New Password', _confirmPasswordController),
                SizedBox(height: 30),
                _buildSaveChangesButton(),
                SizedBox(height: 30),
                Center(
                  child: Text(
                    'Need to update your information? Please contact customer support.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget to display the user info card
  Widget _buildProfileCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo('Name', _userData?['name'] ?? 'N/A'),
            _buildUserInfo('Email', _userData?['email'] ?? 'N/A'),
            _buildUserInfo('Phone', _userData?['phone'] ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  // Widget to display read-only user information
  Widget _buildUserInfo(String label, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          SizedBox(height: 5),
          Text(info, style: TextStyle(fontSize: 18, color: Colors.grey[800])),
          Divider(),
        ],
      ),
    );
  }

  // Widget to build password fields
  Widget _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: !_isPasswordVisible,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        suffixIcon: IconButton(
          icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  // Save Changes Button Widget
  Widget _buildSaveChangesButton() {
    return Center(
      child: ElevatedButton(
        onPressed: changePassword,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(horizontal: 60, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          backgroundColor: Colors.deepPurpleAccent,
          elevation: 5,
        ),
        child: Text(
          'Save',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      ),
    );
  }
}
