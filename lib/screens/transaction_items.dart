import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/currencyget.dart';
import 'package:skilltest/services/nointernet.dart';

class TransactionDetailPage extends StatefulWidget {
  final int transactionId;
  const TransactionDetailPage({Key? key, required this.transactionId})
      : super(key: key);

  @override
  _TransactionDetailPageState createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  late List<Map<String, dynamic>> transactionItems = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTransactionDetails();
  }

  Future<void> fetchTransactionDetails() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? userId = await secureStorage.read(key: 'id');
    try {
      final response = await http.get(
        Uri.parse(
            baseURL + 'gettransactionitems/${widget.transactionId}/${userId}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final List<dynamic> data = jsonDecode(response.body);

          setState(() {
            // Filter items where 'fired' is 1
            transactionItems = data
                .where((item) => item['fired'] == 0)
                .map((item) => {
                      'id': item['id'] ?? '',
                      'transaction_id': item['transaction_id'] ?? '',
                      'item': item['item'] ?? 'Unknown Item',
                      'quantity': item['quantity'] ?? 0,
                      'price': double.tryParse(item['price'] ?? '0') ?? 0.0,
                      'amount': double.tryParse(item['amount'] ?? '0') ?? 0.0,
                      'dep_id': item['dep_id'] ?? '',
                      'vat': double.tryParse(item['vat'] ?? '0') ?? 0.0,
                      'promo': item['promo'] ?? '',
                      'promo_val':
                          double.tryParse(item['promo_val'] ?? '0') ?? 0.0,
                    })
                .toList();
            isLoading = false;
          });
        } else {
          throw Exception('Invalid content type');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;
    return Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
      // Check if there is no internet connection
      if (!connectivityService.isConnected) {
        // Show the popup dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showNoInternetDialog(context);
        });
      }

      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Transaction Details',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.teal,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF001a1a), // Start color
                Color(0xFF005959), // Middle color
                Color(0xFF0fbf7f), // End color
              ],
            ),
          ),
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
                  ? Center(child: Text(errorMessage))
                  : transactionItems.isEmpty
                      ? Center(
                          child: Text('No items found for this transaction.'))
                      : Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              // Display transaction ID at the top
                              SizedBox(height: 5),
                              Text(
                                'Transaction# ${widget.transactionId}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              // List of transaction items
                              Expanded(
                                child: ListView.builder(
                                  itemCount: transactionItems.length,
                                  itemBuilder: (context, index) {
                                    final item = transactionItems[index];

                                    return Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Card(
                                        elevation: 4.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                        ),
                                        child: ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 15),
                                          title: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Product: ${item['item']}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                'Product Price: \ $currencySymbol ${item['price'].toStringAsFixed(2)}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 5),
                                              Text(
                                                'Sales Quantity: ${item['quantity']}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                'Total Amount: \ $currencySymbol ${item['amount'].toStringAsFixed(2)}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                'VAT: \ ${item['vat'].toStringAsFixed(2)}',
                                              ),
                                              SizedBox(height: 5),
                                              Text('Promo: ${item['promo']}'),
                                              SizedBox(height: 5),
                                              Text(
                                                'Promo Value: \ ${item['promo_val'].toStringAsFixed(2)}',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
        ),
      );
    });
  }
}
