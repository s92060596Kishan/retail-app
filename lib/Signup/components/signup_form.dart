import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';
import 'package:skilltest/services/baseurl.dart';

import '../../../components/already_have_an_account_acheck.dart';
import '../../../constants.dart';
import '../../Login/login_screen.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({
    Key? key,
  }) : super(key: key);

  @override
  _SignupFormState createState() => _SignupFormState();
}

class _SignupFormState extends State<SignUpForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool isPasswordVisible = false;

  void togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  // void registerUser(BuildContext context) async {
  //   if (_formKey.currentState!.validate()) {
  //     String userName = _userNameController.text.trim();
  //     String email = _emailController.text.trim();
  //     String phoneNumber = _phoneNumberController.text.trim();
  //     String password = _passwordController.text.trim();

  //     User newUser = User(
  //       userName: userName,
  //       email: email,
  //       phoneNumber: phoneNumber,
  //       password: password,
  //     );

  //     int userId = await _databaseHelper.insertUser(newUser);
  //     if (userId != -1) {
  //       Navigator.push(
  //         context,
  //         MaterialPageRoute(
  //           builder: (context) {
  //             return LoginScreen();
  //           },
  //         ),
  //       );
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(
  //           content: Text('Failed to register user. Please try again.'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }
  Future<void> registerUser(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      String userName = _userNameController.text.trim();
      String email = _emailController.text.trim();
      String phoneNumber = _phoneNumberController.text.trim();
      String password = _passwordController.text.trim();

      try {
        final response = await http.post(
          Uri.parse(baseURL + 'register'),
          headers: headers,
          body: jsonEncode({
            'name': userName,
            'email': email,
            'phone': phoneNumber,
            'password': password,
          }),
        );
        print(response.statusCode);
        print(response.body);
        if (response.statusCode == 200) {
          MotionToast.success(
            //title: Text("Delete Successfully"),
            description: Text("Register User Sucessfully"),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
          ).show(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return LoginScreen();
              },
            ),
          );
        } else {
          MotionToast.error(
            //title: Text("Delete Successfully"),
            description: Text("Failed to register user. Please try again."),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
          ).show(context);
        }
      } catch (e) {
        print('Error: $e');
        MotionToast.warning(
          //title: Text("Delete Successfully"),
          description: Text("An error occurred. Please try again later."),
          position: MotionToastPosition.top,
          animationType: AnimationType.fromTop,
        ).show(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _userNameController,
            keyboardType: TextInputType.name,
            textInputAction: TextInputAction.next,
            cursorColor: kPrimaryColor,
            decoration: InputDecoration(
              hintText: "User Name",
              prefixIcon: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.person),
              ),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your user name';
              }
              return null;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding / 2),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              cursorColor: kPrimaryColor,
              decoration: InputDecoration(
                hintText: "Email",
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.email),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter your email';
                } else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ),
          TextFormField(
            controller: _phoneNumberController,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            cursorColor: kPrimaryColor,
            decoration: InputDecoration(
              hintText: "Phone Number",
              prefixIcon: const Padding(
                padding: EdgeInsets.all(defaultPadding),
                child: Icon(Icons.phone_android),
              ),
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
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
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: defaultPadding / 4),
            child: TextFormField(
              controller: _confirmPasswordController,
              textInputAction: TextInputAction.done,
              obscureText: !isPasswordVisible,
              cursorColor: kPrimaryColor,
              decoration: InputDecoration(
                hintText: "Confirm Password",
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(defaultPadding),
                  child: Icon(Icons.lock),
                ),
                suffixIcon: IconButton(
                  onPressed: togglePasswordVisibility,
                  icon: Icon(
                    isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please confirm your password';
                } else if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: defaultPadding / 2),
          ElevatedButton(
            onPressed: () => registerUser(context),
            child: Text(
              "Sign Up".toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: defaultPadding),
          AlreadyHaveAnAccountCheck(
            login: false,
            press: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return const LoginScreen();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
