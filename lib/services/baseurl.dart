import 'package:flutter/material.dart';

const String baseURL = "http://192.168.169.1:8000/api/"; // emulator localhost
const String apiKey = 'ABC123';

Map<String, String> get headers => {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey', // Add your API key here
    };
// Function to show error snackbar
void errorSnackBar(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: Colors.red,
      content: Text(text),
      duration: const Duration(seconds: 1),
    ),
  );
}
