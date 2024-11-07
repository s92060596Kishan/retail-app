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
  double totalSalesAmount = 0.0;
  int totalSalesCount = 0;

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
        print('Transactions for user $userId: $transactions');
        setState(() {
          dataList.addAll(transactions
              .where((item) => item['type'] != 'Refund')
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
        print('Data: $data');
        final List<dynamic> departments = data['department'];
        final List<dynamic> items = data['items'];

        final List<String> transactionIds = dataList
            .map((transaction) => transaction['transaction_id'].toString())
            .toList();
        print('Transaction IDs: $transactionIds');

        final filteredItems = items.where((item) {
          return transactionIds.contains(item['transaction_id'].toString()) &&
              item['dep_id'] != 0 &&
              item['fired'] != 1;
        }).toList();

        setState(() {
          departmentsList = List<Map<String, dynamic>>.from(departments);
          departmentItemsMap = {};
          totalSalesAmount = 0.0;
          totalSalesCount = 0;

          for (var item in filteredItems) {
            final String depId = item['dep_id'].toString();
            if (departmentItemsMap[depId] == null) {
              departmentItemsMap[depId] = [];
            }
            departmentItemsMap[depId]!.add(item);

            // Summing up total sales amount and sales count per department
            totalSalesAmount += double.tryParse(item['amount'].toString()) ?? 0;
            totalSalesCount += 1;
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
    int totalDepartments = departmentItemsMap.keys.length;

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
                : Column(
                    children: [
                      Expanded(
                        child: ListView(
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

                            // Calculate total sales and count for each department
                            double departmentTotalAmount =
                                items.fold(0.0, (sum, item) {
                              return sum +
                                  (double.tryParse(item['amount'].toString()) ??
                                      0);
                            });
                            int departmentSalesCount = items.length;

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
                                SizedBox(height: 10),
                                Text(
                                  'Sales Count: $departmentSalesCount',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Total Sales: $currencySymbol ${departmentTotalAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                Divider(
                                  color: Colors.white70,
                                  thickness: 1,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                      Container(
                        width: double.infinity, // Full width
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0), // Padding
                        decoration: BoxDecoration(
                          color: Colors.teal, // Background color
                          borderRadius:
                              BorderRadius.circular(10), // Rounded corners
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // First row with the department icon, label, and value
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  Icons.store,
                                  size: 30, // Icon size
                                  color: Colors.white,
                                ),
                                SizedBox(
                                    width: 10), // Spacing between icon and text
                                Text(
                                  'Total Departments',
                                  style: TextStyle(
                                    fontSize: 16, // Font size
                                    color: Colors.white,
                                  ),
                                ),
                                Spacer(), // Pushes the value to the right
                                Text(
                                  '$totalDepartments',
                                  style: TextStyle(
                                    fontSize: 24, // Larger font for the value
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10), // Spacing between rows
                            // Second row with the total sales label and value
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Sales Amount',
                                  style: TextStyle(
                                    fontSize: 16, // Font size
                                    color: Colors.white,
                                  ),
                                ),
                                Spacer(), // Pushes the value to the right
                                Text(
                                  '$currencySymbol ${totalSalesAmount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 24, // Larger font for the value
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
      ),
    );
  }
}
