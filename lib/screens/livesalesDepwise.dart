import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/currencyget.dart';

class DepartmentDetailslivesalesPage extends StatefulWidget {
  @override
  _DepartmentDetailslivesalesPageState createState() =>
      _DepartmentDetailslivesalesPageState();
}

class _DepartmentDetailslivesalesPageState
    extends State<DepartmentDetailslivesalesPage> {
  List<Map<String, dynamic>> dataList = [];
  bool isLoading = true;
  String errorMessage = '';
  Map<String, List<Map<String, dynamic>>> departmentItemsMap = {};
  List<Map<String, dynamic>> departmentsList = [];
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    fetchLog();
  }

  Future<void> fetchLog() async {
    String? custId = await secureStorage.read(key: 'id');

    if (custId == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Customer ID not found.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(baseURL + 'getLogs/$custId'),
        headers: headers,
      );

      if (response.statusCode == 200 &&
          response.headers['content-type']?.contains('application/json') ==
              true) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> activeLogs = data['active_logs'];

        if (activeLogs.isNotEmpty) {
          List<String> userIds = [];
          for (var log in activeLogs) {
            userIds.add(log['LogId'].toString());
          }

          for (String userId in userIds) {
            await fetchTransactionsForUser(userId);
          }
        } else {
          setState(() {
            errorMessage = 'No logs found';
            isLoading = false;
          });
        }
      } else {
        throw Exception('Invalid content type or failed to load data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> fetchTransactionsForUser(String userId) async {
    try {
      String? custId = await secureStorage.read(key: 'id');
      if (custId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Customer ID not found.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(baseURL + 'getactivesales/$custId/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200 &&
          response.headers['content-type']?.contains('application/json') ==
              true) {
        final List<dynamic> transactions = jsonDecode(response.body);
        print('Transactions for user $userId: $transactions'); // Debug print
        setState(() {
          dataList.addAll(transactions
              .map((item) => {
                    'title': 'Transaction# ${item['transactionId'] ?? ''}',
                    'total_payable':
                        double.tryParse(item['total_payable']) ?? 0,
                    'cus_paid_amount':
                        double.tryParse(item['cus_paid_amount']) ?? 0,
                    'cus_balance': double.tryParse(item['cus_balance']) ?? 0,
                    'transaction_date': item['transaction_date'] ?? '',
                    'type': item['type'] ?? '',
                    'method1': item['method1'] ?? '',
                    'method2': item['method2'] ?? '',
                    'user_id': item['user_id'] ?? '',
                    'item_count': item['item_count'] ?? 0,
                    'transaction_id': item['transactionId'] ?? '',
                  })
              .toList());
          fetchData();
        });
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      String? userId = await secureStorage.read(key: 'id');
      if (userId == null) {
        throw Exception('Customer ID not found.');
      }

      final response = await http.get(
        Uri.parse(baseURL + 'getalltransactionitems/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200 &&
          response.headers['content-type']?.contains('application/json') ==
              true) {
        final data = jsonDecode(response.body);
        print('Data: $data'); // Debug print
        final List<dynamic> departments = data['department'];
        final List<dynamic> items = data['items'];

        final List<String> transactionIds = dataList
            .map((transaction) => transaction['transaction_id'].toString())
            .toList();
        print('Transaction IDs: $transactionIds');

        final filteredItems = items.where((item) {
          return transactionIds.contains(item['transaction_id'].toString());
        }).toList();
        print('Filtered Items: $filteredItems');

        setState(() {
          departmentsList = List<Map<String, dynamic>>.from(departments);
          departmentItemsMap = {};

          for (var item in filteredItems) {
            final String depId = item['dep_id'].toString();
            if (departmentItemsMap[depId] == null) {
              departmentItemsMap[depId] = [];
            }
            departmentItemsMap[depId]!.add(item);
          }
        });
      } else {
        throw Exception('Failed to load transaction items');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Department Details',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF001a1a), Color(0xFF005959), Color(0xFF0fbf7f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(
                    child:
                        Text(errorMessage, style: TextStyle(color: Colors.red)),
                  )
                : ListView(
                    children: departmentsList.where((department) {
                      final String departmentId =
                          department['departments_id'].toString();
                      final List<Map<String, dynamic>> items =
                          departmentItemsMap[departmentId] ?? [];
                      return items.isNotEmpty;
                    }).map((department) {
                      final String departmentId =
                          department['departments_id'].toString();
                      final String departmentName = department['name'];
                      final List<Map<String, dynamic>> items =
                          departmentItemsMap[departmentId] ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            departmentName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Card(
                                  elevation: 4.0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10, horizontal: 15),
                                    child: Wrap(
                                      spacing: 20.0, // Space between the items
                                      runSpacing:
                                          10.0, // Space between the lines
                                      children: [
                                        Text('Product: ${item['item']}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text('Quantity: ${item['quantity']}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500)),
                                        Text(
                                            'Amount: \ $currencySymbol ${double.tryParse(item['amount'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: 16),
                        ],
                      );
                    }).toList(),
                  ),
      ),
    );
  }
}
