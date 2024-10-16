import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:skilltest/services/baseurl.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();

  factory CurrencyService() {
    return _instance;
  }

  CurrencyService._internal();

  String? _currencyCode; // Store the currency code like 'fr-CH'
  String? _currencySymbol;
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  // Fetch currency value and locale
  Future<void> fetchCurrencyValue() async {
    String? custId = await secureStorage.read(key: 'id');
    try {
      final response = await http
          .get(Uri.parse(baseURL + 'getcurrency/$custId'), headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currencyCode = data; // Update according to API response
        // _currencyCode = 'en-US';
        // Set the currency symbol based on locale (e.g., 'fr-CH')
        setCurrencySymbol();
      } else {
        throw Exception('Failed to fetch currency');
      }
    } catch (e) {
      print('Error fetching currency: $e');
    }
  }

  // Method to set currency symbol using the locale
  void setCurrencySymbol() {
    if (_currencyCode != null) {
      // Example: 'fr-CH' for Swiss Franc in French-speaking Switzerland
      var format = NumberFormat.simpleCurrency(locale: _currencyCode);
      _currencySymbol = format.currencySymbol;
    }
  }

  // Getter for currency symbol
  String? get currencySymbol => _currencySymbol;
}
