import 'dart:convert';
//flutter build apk --release

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseURL =
    "http://posvega-apis.com/testapp/api/"; 
    // emulator localhost
//const String baseURL = "http://192.168.231.1:8000/api/";
String? apiKey;

// Function to fetch the API key and set it
Future<void> fetchApiKey() async {
  try {
    final response = await http
        .get(Uri.parse('http://posvega-apis.com/reactnew/api/getkey'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      apiKey = data['api_key']; // Adjust according to your API response
    } else {
      throw Exception('Failed to fetch API key');
    }
  } catch (e) {
    print('Error fetching API key: $e');
  }
}

Map<String, String> get headers => {
      'Content-Type': 'application/json',
      //'Authorization': 'Bearer $apiKey', // Add your API key here
      if (apiKey != null) 'Authorization': 'Bearer $apiKey',
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
// Function to get headers with API key