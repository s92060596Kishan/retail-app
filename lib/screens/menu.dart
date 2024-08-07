import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilltest/Login/login_screen.dart';
import 'package:skilltest/models/user_model.dart';
import 'package:skilltest/screens/addrecord.dart';
import 'package:skilltest/screens/editdata.dart';
import 'package:skilltest/screens/settingScreen.dart';
import 'package:skilltest/services/baseurl.dart'; // Add your base URL import

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  User? user1;

  Future<void> _loadUserDetails() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();

    try {
      // Read token and userId from secure storage
      String? userId = await secureStorage.read(key: 'id');
      print(userId);
      if (userId != null) {
        final response = await http.get(
          Uri.parse(baseURL + 'getuser/$userId'), // Adjust URL based on route
          headers: headers,
        );

        if (response.statusCode == 200) {
          // Parse the response body to get user data
          final Map<String, dynamic> responseData = json.decode(response.body);
          final userMap = responseData['user'] as Map<String, dynamic>;

          // Parse the user ID, ensuring it is an integer
          final userId = int.tryParse(userMap['user_id'].toString());

          if (userId != null) {
            final updatedUser = User(
              id: userId,
              userName: userMap['name'] as String?,
              email: userMap['email'] as String?,
              phoneNumber: userMap['phone'] as String?,
              password: userMap['password'] as String?, // Handle this securely
            );

            setState(() {
              user1 = updatedUser;
            });

            // Update secure storage with the fetched user data
            await secureStorage.write(key: 'id', value: userId.toString());
            await secureStorage.write(
                key: 'name', value: updatedUser.userName ?? '');
            await secureStorage.write(
                key: 'phone', value: updatedUser.phoneNumber ?? '');
            await secureStorage.write(
                key: 'email', value: updatedUser.email ?? '');
            await secureStorage.write(
                key: 'password',
                value:
                    updatedUser.password ?? ''); // Update the token if needed
          } else {
            print('Failed to parse user ID.');
          }
        } else {
          // Handle error response
          print(
              'Failed to load user details. Status code: ${response.statusCode}');
        }
      } else {
        print('Token or userId not found in secure storage.');
      }
    } catch (error) {
      // Handle error
      print('Error loading user details: $error');
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Show confirmation dialog
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Confirm logout
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm logout
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.remove('isLoggedIn');
      await preferences.remove('userData');

      final FlutterSecureStorage secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll(); // Optionally clear all secure storage

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(), // Replace with your login screen
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserDetails();
  }

  void _updateUserData(User updatedUser) {
    setState(() {
      user1 = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              child: Image.asset("assets/images/guest.jpg"),
            ),
            SizedBox(height: 20),
            Text(
              '${user1?.userName ?? 'Guest'}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Email: ${user1?.email ?? 'N/A'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            Text(
              'Phone Number: ${user1?.phoneNumber ?? 'N/A'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 40),
            ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Records'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddRecordScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Edit Records'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditRecordScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(
                      onUpdateUserData: _updateUserData,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              onTap: () {
                // Handle navigation to notifications screen
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
