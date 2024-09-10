import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilltest/Login/login_screen.dart';
import 'package:skilltest/models/user_model.dart';
import 'package:skilltest/services/baseurl.dart';

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
      String? userId = await secureStorage.read(key: 'id');
      if (userId != null) {
        final response = await http.get(
          Uri.parse(baseURL + 'getmobileuser/$userId'),
          headers: headers,
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = json.decode(response.body);
          final userMap = responseData as Map<String, dynamic>;
          final userId = int.tryParse(userMap['cust_id'].toString());

          if (userId != null) {
            final updatedUser = User(
              id: userId,
              userName: userMap['name'] as String?,
              email: userMap['email'] as String?,
              phoneNumber: userMap['phone'] as String?,
              password: userMap['password'] as String?,
            );

            setState(() {
              user1 = updatedUser;
            });

            await secureStorage.write(key: 'id', value: userId.toString());
            await secureStorage.write(
                key: 'name', value: updatedUser.userName ?? '');
            await secureStorage.write(
                key: 'phone', value: updatedUser.phoneNumber ?? '');
            await secureStorage.write(
                key: 'email', value: updatedUser.email ?? '');
            await secureStorage.write(
                key: 'password', value: updatedUser.password ?? '');
          } else {
            print('Failed to parse user ID.');
          }
        } else {
          print(
              'Failed to load user details. Status code: ${response.statusCode}');
        }
      } else {
        print('Token or userId not found in secure storage.');
      }
    } catch (error) {
      print('Error loading user details: $error');
    }
  }

  Future<void> _logout(BuildContext context) async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('No'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
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
      await secureStorage.deleteAll();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
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
        title: Text('Profile Screen', style: TextStyle(fontSize: 22)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001a1a), Color(0xFF005959), Color(0xFF0fbf7f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage("assets/images/guest.jpg"),
                backgroundColor: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.teal, width: 2),
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Text(
                '${user1?.userName ?? 'Guest'}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: Text(
                'Email: ${user1?.email ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[200],
                ),
              ),
            ),
            Center(
              child: Text(
                'Phone Number: ${user1?.phoneNumber ?? 'N/A'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[300],
                ),
              ),
            ),
            SizedBox(height: 40),
            Expanded(
              child: ListView(
                children: [
                  // _buildMenuItem(Icons.receipt_long, 'All Transactions', () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => QuickTransactionListPage(),
                  //     ),
                  //   );
                  // }),
                  // _buildMenuItem(Icons.point_of_sale_sharp, 'Active Sales', () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => TransactionListPage(),
                  //     ),
                  //   );
                  // }),
                  _buildMenuItem(Icons.settings, 'Profile Settings', () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (context) => DateRangeLogScreen(),
                    //   ),
                    // );
                  }),
                  _buildMenuItem(Icons.logout, 'Logout', () {
                    _logout(context);
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent, size: 28),
        title: Text(
          title,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        trailing:
            Icon(Icons.arrow_forward_ios, color: Colors.blueAccent, size: 20),
        onTap: onTap,
      ),
    );
  }
}
