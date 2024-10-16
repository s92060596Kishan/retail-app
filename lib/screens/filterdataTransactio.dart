import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/currencyget.dart';

class FilterDetailsPage extends StatefulWidget {
  final String filterValue;
  Map<String, String> dateRangeToUserId = {};

  FilterDetailsPage(
      {required this.filterValue, required this.dateRangeToUserId});

  @override
  _FilterDetailsPageState createState() => _FilterDetailsPageState();
}

class _FilterDetailsPageState extends State<FilterDetailsPage> {
  String? selectedTile; // State to keep track of the selected tile
  List<Map<String, dynamic>> dataList = [];
  bool isLoading = false;
  String errorMessage = '';
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  List<Map<String, dynamic>> departmentsList = [];
  Map<String, List<Map<String, dynamic>>> departmentItemsMap = {};
  int _selectedIndex = 0; // Track the selected index

  @override
  void initState() {
    super.initState();
    fetchTransactions(widget.filterValue);
  }

  Future<void> fetchTransactions(String userId) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      dataList.clear();
    });

    String? custId = await secureStorage.read(key: 'id');
    if (custId == null) {
      setState(() {
        errorMessage = 'Customer ID not found.';
        isLoading = false;
      });
      return;
    }

    // Fetch transactions based on user ID
    if (userId == 'All') {
      for (String id in widget.dateRangeToUserId.values.toSet()) {
        await _fetchTransactionsForUser(custId, id);
      }
    } else {
      await _fetchTransactionsForUser(custId, userId);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _fetchTransactionsForUser(String custId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse(baseURL + 'getactivesales/$custId/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        const priority = {
          'Cash': 0,
          'Card': 1,
        };
        setState(() {
          dataList.addAll(data
              .map((item) => {
                    'title': 'Transaction# ${item['transactionId'] ?? ''}',
                    'total_payable': double.tryParse(
                            item['total_payable']?.toString() ?? '') ??
                        0,
                    'cus_paid_amount': double.tryParse(
                            item['cus_paid_amount']?.toString() ?? '') ??
                        0,
                    'cus_balance': double.tryParse(
                            item['cus_balance']?.toString() ?? '') ??
                        0,
                    'transaction_date': item['transaction_date'] ?? '',
                    'type': item['type'] ?? '',
                    'method1': item['method1'] ?? '',
                    'method2': item['method2'] ?? '',
                    'user_id': item['user_id'] ?? '',
                    'item_count': item['item_count'] ?? 0,
                    'transaction_id': item['transactionId'] ?? '',
                  })
              .toList());
          // Now, sort the transactions by 'transaction_date' in descending order (latest first)
          dataList.sort((a, b) {
            DateTime dateA = DateTime.parse(a['transaction_date']);
            DateTime dateB = DateTime.parse(b['transaction_date']);
            return dateB
                .compareTo(dateA); // Reverse comparison for latest first
          });

          fetchData(dataList);
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

  Future<void> fetchData(List<Map<String, dynamic>> dataList) async {
    setState(() {
      isLoading = true; // Show loading indicator while fetching data
    });

    try {
      String? userId = await secureStorage.read(key: 'id');
      if (userId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Customer ID not found.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(baseURL + 'getalltransactionitems/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> departments = data['department'];
        final List<dynamic> items = data['items'];

        setState(() {
          departmentsList = List<Map<String, dynamic>>.from(departments);
          departmentItemsMap = {};

          final List<String> transactionIds = dataList
              .map((transaction) => transaction['transaction_id'].toString())
              .toList();

          // Filter items by extracted transaction IDs
          final filteredItems = items.where((item) {
            final itemTransactionId = item['transaction_id'].toString();
            return transactionIds.contains(itemTransactionId);
          }).toList();

          // Create a map of department ID to its filtered items
          for (var item in filteredItems) {
            final String depId = item['dep_id'].toString();
            if (departmentItemsMap[depId] == null) {
              departmentItemsMap[depId] = [];
            }
            departmentItemsMap[depId]!.add(item);
          }
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator after data is fetched
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Filter Details',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF001a1a),
              Color(0xFF005959),
              Color(0xFF0fbf7f),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 0; // Set index for Departments
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedIndex == 0 ? Colors.blueAccent : Colors.grey,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Departments',
                      style: TextStyle(
                        color:
                            _selectedIndex == 0 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1; // Set index for Transactions
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedIndex == 1 ? Colors.blueAccent : Colors.grey,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Transactions',
                      style: TextStyle(
                        color:
                            _selectedIndex == 1 ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex, // Show the selected view
                children: [
                  // Container for Departments
                  _buildDepartmentsView(),
                  // Container for Transactions
                  _buildTransactionsView(currencySymbol),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Adjusted function for building transactions view
  Widget _buildTransactionsView(String? currencySymbol) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : dataList.isEmpty
            ? Center(child: Text('No transactions available.'))
            : ListView.builder(
                physics: BouncingScrollPhysics(), // Allow scrolling
                itemCount: dataList.length,
                itemBuilder: (context, index) {
                  final transaction = dataList[index];
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListTile(
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        title: Row(
                          children: [
                            Text(
                              '${transaction['title']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[700],
                                fontSize: 14,
                              ),
                            ),
                            Spacer(),
                            Text(
                              'Total Payable: \ $currencySymbol ${transaction['total_payable'].toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Paid Amount: \ $currencySymbol ${transaction['cus_paid_amount'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color:
                                          const Color.fromARGB(255, 5, 5, 5)),
                                ),
                                Spacer(),
                                Text(
                                  'Balance: \ $currencySymbol ${transaction['cus_balance'].toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color:
                                          const Color.fromARGB(255, 9, 9, 9)),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Transaction Date: ${transaction['transaction_date']}',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 14, 13, 13)),
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  'Type: ${transaction['type']}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Spacer(),
                                Text(
                                  'Method 1: ${transaction['method1']}',
                                  style: TextStyle(
                                    color: transaction['method1'] == 'Cash'
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  'Method 2: ${transaction['method2']}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Item Count: ${transaction['item_count']}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                Spacer(),
                                Text(
                                  'User Name: ${transaction['user_id']}',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            )
                          ],
                        ),
                        // onTap: () {
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (context) => TransactionActiveDetailPage(
                        //           transactionId: transaction['transaction_id']),
                        //     ),
                        //   );
                        // },
                      ),
                    ),
                  );
                },
              );
  }

  Widget _buildDepartmentsView() {
    String? currencySymbol =
        CurrencyService().currencySymbol; // Get the currency symbol
    return isLoading
        ? Center(child: CircularProgressIndicator()) // Loading indicator
        : departmentItemsMap.isEmpty
            ? Center(
                child: Text(
                'No transactions Items available.',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ))
            : ListView(
                children: departmentsList.where((department) {
                  final String departmentId =
                      department['departments_id'].toString();
                  final List<Map<String, dynamic>> items =
                      departmentItemsMap[departmentId] ?? [];
                  // Filter items where 'fired' is 1
                  final filteredItems =
                      items.where((item) => item['fired'] == 1).toList();
                  return filteredItems
                      .isNotEmpty; // Only include departments with active items
                }).map((department) {
                  final String departmentId =
                      department['departments_id'].toString();
                  final String departmentName = department['name'];
                  final List<Map<String, dynamic>> items =
                      departmentItemsMap[departmentId] ?? [];
                  // Filter items where 'fired' is 1
                  final filteredItems =
                      items.where((item) => item['fired'] == 1).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          departmentName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      // List of items within the department
                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                            NeverScrollableScrollPhysics(), // Disable scrolling
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
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
                                  runSpacing: 10.0, // Space between the lines
                                  children: [
                                    Text(
                                      'Product: ${item['item']}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Quantity: ${item['quantity']}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      'Amount: $currencySymbol${double.tryParse(item['amount'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500),
                                    ),
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
              );
  }
}
