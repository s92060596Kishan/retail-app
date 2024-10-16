import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/screens/selectItemeditscreen.dart';
import 'package:skilltest/services/baseurl.dart';

class DepartmentsEditScreen extends StatefulWidget {
  final String filterValue;
  Map<String, String> dateRangeToUserId = {};

  DepartmentsEditScreen(
      {required this.filterValue, required this.dateRangeToUserId});

  @override
  _DepartmentsEditScreenState createState() => _DepartmentsEditScreenState();
}

class _DepartmentsEditScreenState extends State<DepartmentsEditScreen> {
  DateTime? startDate;
  DateTime? endDate;
  List<String> userIds = [];
  String? selectedUserId;
  String? selectedTile; // State to keep track of the selected tile
  List<Map<String, dynamic>> dataList = [];
  bool isLoading = false;
  String errorMessage = '';
  List<String> dateRanges = [];
  Map<String, String> dateRangeToUserId = {};
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool isSearchExpanded = true; // New state to control expansion
  Map<String, List<Map<String, dynamic>>> departmentItemsMap = {};
  List<Map<String, dynamic>> departmentsList = [];

  @override
  void initState() {
    super.initState();
    fetchTransactions(widget.filterValue);
  }

  Future<void> fetchTransactions(String userId) async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      dataList.clear(); // Clear previous transactions before fetching new ones
    });

    String? custId = await secureStorage.read(key: 'id');
    if (custId == null) {
      setState(() {
        errorMessage = 'Customer ID not found.';
        isLoading = false;
      });
      return;
    }

    try {
      if (userId == 'All') {
        // Fetch transactions for all user IDs
        for (String id in widget.dateRangeToUserId.values.toSet()) {
          await _fetchTransactionsForUser(custId, id);
        }
      } else {
        await _fetchTransactionsForUser(custId, userId);
      }

      setState(() {
        isLoading = false; // Hide loading indicator once data is fetched
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _fetchTransactionsForUser(String custId, String userId) async {
    try {
      final response = await http.get(
        Uri.parse(baseURL + 'getactivesales/$custId/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Check if data is as expected
        print('Fetched data: $data');

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
                    'transaction_id':
                        item['transactionId'] ?? '', // Include transactionId
                  })
              .toList());

          // Debug print statement to check dataList content
          print('dataList after adding transactions: $dataList');

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

        // Debug print statements
        print('Departments: $departments');
        print('Items: $items');

        // Extract transaction IDs from the transactions list
        final List<String> transactionIds = dataList
            .map((transaction) => transaction['transaction_id'].toString())
            .toList();

        print('transactionIds: $transactionIds');

        // Filter items by extracted transaction IDs
        final filteredItems = items.where((item) {
          final itemTransactionId = item['transaction_id'].toString();
          print('Checking item with transaction_id: $itemTransactionId');
          return transactionIds.contains(itemTransactionId);
        }).toList();

        print('filteredItems: $filteredItems');

        setState(() {
          departmentsList = List<Map<String, dynamic>>.from(departments);

          // Clear previous mapping
          departmentItemsMap = {};

          // Create a map of department ID to its filtered items
          for (var item in filteredItems) {
            final String depId = item['dep_id'].toString();
            if (departmentItemsMap[depId] == null) {
              departmentItemsMap[depId] = [];
            }
            departmentItemsMap[depId]!.add(item);
          }
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    } finally {
      setState(() {
        // Hide loading indicator after data is fetched
      });
    }
  }

  void _navigateToTransactionScreen(
      int departmentId, String departmentName, department) {
    print(userIds);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionItemsScreen(
          departmentId: departmentId,
          departmentName: departmentName,
          items: departmentItemsMap[departmentId.toString()] ?? [],
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh or update data
        // fetchTransactions(
        //     selectedUserId ?? 'All'); // Or however you fetch the data
      }
    });
  }

  Widget _buildDepartmentsView() {
    // Filter departmentsList to only include departments with related items
    final filteredDepartments = departmentsList.where((department) {
      final String departmentId = department['departments_id'].toString();
      return departmentItemsMap.containsKey(departmentId) &&
          departmentItemsMap[departmentId]!.isNotEmpty;
    }).toList();

    return isLoading
        ? Center(
            child: CircularProgressIndicator(), // Loading indicator
          )
        : filteredDepartments.isEmpty
            ? Center(
                child: Text(
                  'No departments with transactions found.',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
            : GridView.builder(
                padding: EdgeInsets.all(8),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: filteredDepartments.length,
                itemBuilder: (context, index) {
                  final department = filteredDepartments[index];
                  final int departmentId = department['departments_id'];
                  final String departmentName = department['name'];

                  return GestureDetector(
                    onTap: () {
                      _navigateToTransactionScreen(
                          departmentId, departmentName, department);
                    },
                    child: Card(
                      color: Colors.teal[100],
                      elevation: 4.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Center(
                        child: Text(
                          departmentName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Departments',
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
        child: _buildDepartmentsView(), // Your GridView or body content
      ),
    );
  }
}
