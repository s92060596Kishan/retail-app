import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/screens/editQuantity.dart';
import 'package:skilltest/services/baseurl.dart';

class TransactionActiveDetailPage extends StatefulWidget {
  final int transactionId;
  const TransactionActiveDetailPage({Key? key, required this.transactionId})
      : super(key: key);

  @override
  _TransactionDetailPageState createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionActiveDetailPage> {
  late List<Map<String, dynamic>> transactionItems = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchTransactionDetails();
  }

  void _navigateToEditPage(Map<String, dynamic> item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditQuantityPage(item: item),
      ),
    );

    if (result != null) {
      // Update the state with the new quantity and amount
      int index = transactionItems
          .indexWhere((element) => element['id'] == result['id']);
      if (index != -1) {
        setState(() {
          transactionItems[index]['quantity'] = result['quantity'];
          transactionItems[index]['amount'] = result['amount'];
        });
      }
    }
  }

  Future<void> fetchTransactionDetails() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? userId = await secureStorage.read(key: 'id');
    print(widget.transactionId);
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
          print(data);
          setState(() {
            transactionItems = data
                .map((item) => {
                      'id': item['id'] ?? 0,
                      'cust_id': item['cust_id'] ?? 0,
                      'transaction_itemsId': item['transaction_itemsId'] ?? 0,
                      'transaction_id': item['transaction_id'] ?? 0,
                      'item': item['item'] ?? '',
                      'quantity': item['quantity'] ?? 0,
                      'price': (item['price'] != null)
                          ? double.tryParse(item['price'].toString()) ?? 0.0
                          : 0.0,
                      'amount': (item['amount'] != null)
                          ? double.tryParse(item['amount'].toString()) ?? 0.0
                          : 0.0,
                      'dep_id': item['dep_id'] ?? 0,
                      'vat': (item['vat'] != null)
                          ? double.tryParse(item['vat'].toString()) ?? 0.0
                          : 0.0,
                      'promo': item['promo'] ?? '',
                      'promo_val': (item['promo_val'] != null)
                          ? double.tryParse(item['promo_val'].toString()) ?? 0.0
                          : 0.0,
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
                                          ]),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(height: 5),
                                              Text(
                                                  'Product Price: \$${item['price'].toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold)),
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
                                              ]),
                                              SizedBox(height: 16),
                                              Center(
                                                child: Row(
                                                  mainAxisSize: MainAxisSize
                                                      .min, // Ensures Row only takes up needed space
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(
                                                        Icons.edit,
                                                        color: const Color
                                                            .fromARGB(
                                                            255,
                                                            16,
                                                            16,
                                                            16), // Explicitly set icon color
                                                      ),
                                                      onPressed: () {
                                                        _navigateToEditPage(
                                                            item);
                                                      },
                                                    ),
                                                    Text(
                                                      'Edit Quantity',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .black, // Set text color
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
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
        ));
  }
}
