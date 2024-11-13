import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:skilltest/screens/selectItemeditscreen.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/currencyget.dart';
import 'package:skilltest/services/nointernet.dart';

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
  bool isLoading = true;
  String errorMessage = '';
  List<String> dateRanges = [];
  Map<String, String> dateRangeToUserId = {};
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  bool isSearchExpanded = true; // New state to control expansion
  Map<String, List<Map<String, dynamic>>> departmentItemsMap = {};
  List<Map<String, dynamic>> departmentsList = [];
  List<Map<String, dynamic>> filteredDepartments = []; // Class-level variable
  double totalSalesAmount = 0.0;
  int totalSalesCount = 0;
  int totalDepartments = 0;
  @override
  void initState() {
    super.initState();
    // Delay for 10 seconds before updating isLoading to false
    Future.delayed(Duration(seconds: 5), () {
      setState(() {
        isLoading = false;
      });
    });
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

      // setState(() {
      //   isLoading = false; // Hide loading indicator once data is fetched
      // });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }

  Future<void> _fetchTransactionsForUser(String custId, String userId) async {
    setState(() {
      isLoading = true;
    });
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
          return transactionIds.contains(itemTransactionId) &&
              (item['dep_id'] != 0);
        }).toList();

        print('filteredItems: $filteredItems');

        setState(() {
          departmentsList = List<Map<String, dynamic>>.from(departments);

          // Clear previous mapping
          departmentItemsMap = {};
          totalSalesAmount = 0.0;
          totalSalesCount = 0;
          // Create a map of department ID to its filtered items
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
          fetchAndCalculateData();
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
    }
  }

// Start loading before fetching data
  void fetchAndCalculateData() async {
    try {
      setState(() {
        isLoading = true;
        // Filter departmentsList
        filteredDepartments = departmentsList.where((department) {
          final String departmentId = department['departments_id'].toString();
          return departmentItemsMap.containsKey(departmentId) &&
              departmentItemsMap[departmentId]!.isNotEmpty;
        }).toList();

        // Debug statement to check filtered count
        print('Filtered Departments Count: ${filteredDepartments.length}');

        totalDepartments = filteredDepartments.length;
        totalSalesAmount = filteredDepartments.fold(0.0, (sum, department) {
          final String departmentId = department['departments_id'].toString();
          final List<Map<String, dynamic>> items =
              departmentItemsMap[departmentId] ?? [];
          return sum +
              items.fold(0.0, (deptSum, item) {
                return deptSum +
                    (double.tryParse(item['amount'].toString()) ?? 0);
              });
        });
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    } finally {
      setState(() {
        isLoading = false;
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
        // Refresh your data here
        print(widget.filterValue);
        fetchTransactions(widget.filterValue);
      }
    });
  }

  // void _refreshDepartments() async {
  //   fetchTransactions(widget.filterValue); // Your fetching logic
  // }

  Widget _buildDepartmentsView() {
    String? currencySymbol =
        CurrencyService().currencySymbol; // Get the currency symbol

    return isLoading
        ? Center(
            child: CircularProgressIndicator(), // Loading indicator
          )
        : Column(
            children: [
              // Fixed Container for Total Departments and Total Sales Amount
              Container(
                width: double.infinity, // Makes the container take full width
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.teal, // Background color
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(10)), // Rounded corners
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment
                          .spaceBetween, // Use space between for distribution
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.store,
                              size: 30, // Icon size
                              color: Colors.white,
                            ),
                            SizedBox(
                                width: 10), // Spacing between icon and text
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Departments',
                                  style: TextStyle(
                                    fontSize: 16, // Font size
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${filteredDepartments.length}',
                                  style: TextStyle(
                                    fontSize: 24, // Font size for the number
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Optionally, you can add a SizedBox for spacing between rows
                        SizedBox(width: 20), // Add spacing between rows
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Sales Amount',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '$currencySymbol ${totalSalesAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20, // Font size for the amount
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filteredDepartments.isEmpty
                    ? (isLoading
                        ? Center(
                            child: CircularProgressIndicator(),
                          )
                        : Center(
                            child: Text(
                                "No Departments,Transactions are  Available",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ))
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
                          final List<Map<String, dynamic>> items =
                              departmentItemsMap[departmentId.toString()] ?? [];

                          // Calculate total sales for the current department
                          double departmentTotal = items.fold(0.0, (sum, item) {
                            return sum +
                                (double.tryParse(item['amount'].toString()) ??
                                    0);
                          });
                          int departmentSalesCount = items.length;

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
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      departmentName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Sales: $currencySymbol ${departmentTotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Items Sold: $departmentSalesCount',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
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
          );
  }

  @override
  Widget build(BuildContext context) {
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
    });
  }
}
