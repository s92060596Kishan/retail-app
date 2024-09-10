import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/services/baseurl.dart';

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
            transactionItems = data
                .map((item) => {
                      'id': item['id'],
                      'transaction_id': item['transaction_id'],
                      'item': item['item'],
                      'quantity': item['quantity'],
                      'price': double.tryParse(item['price']) ?? 0,
                      'amount': double.tryParse(item['amount']) ?? 0,
                      'dep_id': item['dep_id'],
                      'vat': double.tryParse(item['vat']) ?? 0,
                      'promo': item['promo'] ?? '',
                      'promo_val': double.tryParse(item['promo_val']) ?? 0,
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
    return Scaffold(
        appBar: AppBar(
          title: Text('Transaction Details'),
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
                                ' Transaction# ${widget.transactionId}',
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
                                          title: Row(children: [
                                            Text('Product: ${item['item']}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Spacer(),
                                            Text(
                                                'Product Price: \$${item['price'].toStringAsFixed(2)}',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                          ]),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 5),
                                              Row(children: [
                                                Text(
                                                    'Sales Quantity: ${item['quantity']}',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500)),
                                                Spacer(),
                                                Text(
                                                    'Total Amount: \$${item['amount'].toStringAsFixed(2)}',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w500)),
                                              ]),
                                              SizedBox(height: 5),
                                              Text(
                                                  'VAT: \$${item['vat'].toStringAsFixed(2)}'),
                                              SizedBox(height: 5),
                                              Row(children: [
                                                Text('Promo: ${item['promo']}'),
                                                Spacer(),
                                                Text(
                                                    'Promo Value: \$${item['promo_val'].toStringAsFixed(2)}'),
                                              ])
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
        ));
  }
}
