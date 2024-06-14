import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilltest/Login/login_screen.dart';
import 'package:skilltest/models/user_model.dart';
import 'package:skilltest/screens/addrecord.dart';
import 'package:skilltest/screens/editdata.dart';
import 'package:skilltest/screens/settingScreen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  User? user1;
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
        });
      }
    } catch (error) {
      // Handle error
      print('Error loading user details: $error');
    }
  }

//   // Function to handle logout
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
                Navigator.of(context).pop(true); // Cancel logout
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );

    // If user confirms logout, navigate back to login screen
    if (confirmLogout == true) {
      // For now, let's just navigate back to the login screen
      SharedPreferences preferences = await SharedPreferences.getInstance();
      // Clear login state and user data
      await preferences.remove('isLoggedIn');
      await preferences.remove('userData');
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

  @override
  Widget build(BuildContext context) {
    //print(user);
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Screen'),
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back),
        //   onPressed: () {
        //     Navigator.pushReplacement(
        //       context,
        //       MaterialPageRoute(
        //         builder: (context) => HomeScreen(
        //           loggedInUser: user,
        //         ), // Navigate to the home screen
        //       ),
        //     );
        //   },
        // ),
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
              leading: Icon(Icons.add), // Set the icon for adding records
              title: Text('Add Records'), // Set the text for the new option
              onTap: () {
                // Navigate to screen where records can be added
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddRecordScreen(), // Replace with your screen
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit), // Set the icon for adding records
              title: Text('Edit Records'), // Set the text for the new option
              onTap: () {
                // Navigate to screen where records can be added
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EditRecordScreen(), // Replace with your screen
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Navigate to settings screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SettingsScreen(), // Navigate to the home screen
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.notifications),
              title: Text('Notifications'),
              onTap: () {
                // Navigate to notifications screen
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                // Handle logout action
                _logout(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
