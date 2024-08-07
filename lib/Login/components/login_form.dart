import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skilltest/models/navigationBar.dart';
import 'package:skilltest/models/user_model.dart';
import 'package:skilltest/services/baseurl.dart';

import '../../../components/already_have_an_account_acheck.dart';
import '../../../constants.dart';
import '../../Signup/signup_screen.dart';

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
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      final response = await http.post(
        Uri.parse(baseURL + 'login'),
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
        final dynamic userId = responseData?['user']?['user_id'];

        if (userId == null) {
          // User ID is null, cannot log in
          MotionToast.warning(
            description: Text("Please wait for admin verification"),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
          ).show(context);
          return; // Exit the method without navigating
        }

        await secureStorage.write(
          key: 'id',
          value: userId.toString(),
        );
        await secureStorage.write(
            key: 'name', value: responseData?['user']?['name']);
        await secureStorage.write(
            key: 'phone', value: responseData?['user']?['phone']);
        await secureStorage.write(
            key: 'email', value: responseData?['user']?['email']);
        await secureStorage.write(
            key: 'password', value: responseData?['user']?['password']);
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
          _navigateToHome(user);
        } else {
          MotionToast.error(
            description: Text("User data not found"),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
          ).show(context);
        }
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
    }
  }

  void _navigateToHome(user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MyNavigationBar(loggedInUser: user),
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: defaultPadding / 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Add your logic for the "Forgot Password?" action here
                  },
                  child: const Text(
                    "Forgot Password?",
                    style: TextStyle(color: kPrimaryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: defaultPadding / 8),
            Hero(
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
            AlreadyHaveAnAccountCheck(
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) {
                      return const SignUpScreen();
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
