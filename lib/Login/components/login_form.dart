import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilltest/models/user_model.dart';
import 'package:skilltest/screens/shopNavigation.dart';
import 'package:skilltest/services/baseurl.dart';

import '../../../constants.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    Key? key,
  }) : super(key: key);

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isPasswordVisible = false;
  late SharedPreferences _preferences;
  bool _isLoading = false; // New variable to track loading state
  void togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    _initPreferences();
  }

  void _initPreferences() async {
    _preferences = await SharedPreferences.getInstance();
    // Check if user is already logged in
    final bool isLoggedIn = _preferences.getBool('isLoggedIn') ?? false;
    print(isLoggedIn);
    if (isLoggedIn) {
      // If logged in, navigate to home page
      final dynamic userData = _preferences.getString('userData');
      print(userData);

      User user = User.fromJson(jsonDecode(userData));
      _navigateToHome(user);
    }
  }

  Future<void> _loginUser() async {
    setState(() {
      _isLoading = true; // Start loading
    });
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse(baseURL + 'mobile/login'),
        headers: headers,
        body: jsonEncode(<String, String>{
          'email': email,
          'password': password,
        }),
      );
      print(response.body);
      print(response.statusCode);
      if (response.statusCode == 200) {
        final Map<String, dynamic>? responseData = jsonDecode(response.body);
        final dynamic userData = responseData?['user'];
        final dynamic shopData = responseData?['shop'];

        // await secureStorage.write(
        //   key: 'id',
        //   value: userId.toString(),
        // );
        await secureStorage.write(
            key: 'user_id', value: responseData?['user']?['id'].toString());
        await secureStorage.write(
            key: 'name', value: responseData?['user']?['name']);
        await secureStorage.write(
            key: 'phone', value: responseData?['user']?['phone']);
        await secureStorage.write(
            key: 'email', value: responseData?['user']?['email']);
        await secureStorage.write(
            key: 'password', value: responseData?['user']?['password']);
        await secureStorage.write(
            key: 'customerID',
            value: responseData?['user']?['cust_id'].toString());
        if (userData != null) {
          User user = User.fromJson(userData);

          // Save login state in shared preferences
          _preferences.setBool('isLoggedIn', true);
          _preferences.setString(
              'userData', jsonEncode(userData)); // Save user data
          MotionToast.success(
            description: Text("Login Successfully"),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
          ).show(context);
          // Navigate to ShopDetailsScreen with shop data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ShopDetailsScreen(),
            ),
          );
        } else {
          MotionToast.error(
            description: Text("User data not found"),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
          ).show(context);
        }
      } else if (response.statusCode == 403) {
        // Decode the response body to access the error message
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        MotionToast.warning(
          description: Text(responseData['error']),
          position: MotionToastPosition.top,
          animationType: AnimationType.fromTop,
        ).show(context);
      } else {
        MotionToast.warning(
          description: Text("Incorrect Email or Password"),
          position: MotionToastPosition.top,
          animationType: AnimationType.fromTop,
        ).show(context);
      }
    } catch (e) {
      print('Error: $e');
      MotionToast.error(
        description: Text("Server Error Try again later"),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);
    } finally {
      setState(() {
        _isLoading = false; // Stop loading after request completes
      });
    }
  }

  void _navigateToHome(user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ShopDetailsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        child: Column(
          children: [
            TextFormField(
              controller: _emailController,
              textInputAction: TextInputAction.next,
              cursorColor: kPrimaryColor,
              onSaved: (phone) {},
              decoration: const InputDecoration(
                hintText: "Your Email Number",
                prefixIcon: Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.email),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
              child: TextFormField(
                controller: _passwordController,
                textInputAction: TextInputAction.done,
                obscureText: !isPasswordVisible,
                cursorColor: kPrimaryColor,
                decoration: InputDecoration(
                  hintText: "Your password",
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(defaultPadding),
                    child: Icon(Icons.lock),
                  ),
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
            ),
            const SizedBox(height: 20),
            _isLoading // Show loading indicator if loading
                ? CircularProgressIndicator() // Show loader during login
                : Hero(
                    tag: "login_btn",
                    child: ElevatedButton(
                      onPressed: _loginUser,
                      child: Text(
                        "Login".toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
            const SizedBox(height: defaultPadding),
          ],
        ),
      ),
    );
  }
}
