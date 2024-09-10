import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/screens/transaction_items.dart'; // Assuming this is where you want to show transaction details
import 'package:skilltest/services/baseurl.dart';

class DateRangeLogScreen extends StatefulWidget {
  const DateRangeLogScreen({Key? key}) : super(key: key);

  @override
  _DateRangeLogScreenState createState() => _DateRangeLogScreenState();
}

class _DateRangeLogScreenState extends State<DateRangeLogScreen> {
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
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool isSearchExpanded = true; // New state to control expansion
  Map<String, List<Map<String, dynamic>>> departmentItemsMap = {};
  List<Map<String, dynamic>> departmentsList = [];

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quick Reports'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Collapsible Search and Dropdown Section
            ExpansionTile(
              title: Text('Quick Filters'),
              initiallyExpanded: isSearchExpanded,
              onExpansionChanged: (bool expanded) {
                setState(() => isSearchExpanded = expanded);
              },
              children: [
                SizedBox(height: 10),
                TextFormField(
                  controller: _startDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Start Date',
                    hintText: 'Select Start Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDate(context, isStartDate: true),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: _endDateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'End Date',
                    hintText: 'Select End Date',
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () => _selectDate(context, isStartDate: false),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: 150,
                  child: ElevatedButton(
                    onPressed: fetchLogDetails,
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.green),
                      padding: MaterialStateProperty.all<EdgeInsets>(
                          EdgeInsets.symmetric(vertical: 15)),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      textStyle: MaterialStateProperty.all<TextStyle>(
                        TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                    child: Text('Find',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                ),
                SizedBox(height: 20),
                DropdownButton<String>(
                  isExpanded: true,
                  hint: Text('Select Date Range'),
                  value: selectedUserId,
                  items: ['All', ...dateRanges].map((String dateRange) {
                    return DropdownMenuItem<String>(
                      value: dateRange,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width - 60,
                        ),
                        child: Text(
                          dateRange,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedUserId = value;
                      isSearchExpanded = false; // Collapse on selection
                      selectedTile = null; // Reset tile selection
                    });
                    if (value != null) {
                      if (value == 'All') {
                        fetchTransactions('All');
                      } else {
                        final userId = dateRangeToUserId[value];
                        if (userId != null) {
                          fetchTransactions(userId);
                        }
                      }
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 10),
            if (selectedUserId != null)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          selectedTile = 'Departments';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedTile == 'Departments'
                            ? Colors.blueAccent
                            : Colors
                                .grey, // Change background color when active
                        padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16), // Make it more compact
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                        ),
                      ),
                      child: Text(
                        'Departments',
                        style: TextStyle(
                          color: selectedTile == 'Departments'
                              ? Colors.white
                              : Colors.black, // Change text color when active
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
                          selectedTile = 'Transactions';
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedTile == 'Transactions'
                            ? Colors.blueAccent
                            : Colors
                                .grey, // Change background color when active
                        padding: EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16), // Make it more compact
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12), // Rounded corners
                        ),
                      ),
                      child: Text(
                        'Transactions',
                        style: TextStyle(
                          color: selectedTile == 'Transactions'
                              ? Colors.white
                              : Colors.black, // Change text color when active
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 10),
            if (selectedTile == 'Departments')
              Expanded(
                  child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF001a1a),
                            Color(0xFF005959),
                            Color(0xFF0fbf7f)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: _buildDepartmentsView())),
            if (selectedTile == 'Transactions')
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF001a1a),
                        Color(0xFF005959),
                        Color(0xFF0fbf7f)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: dataList.isEmpty
                      ? Center(child: Text('No transactions available.'))
                      : ListView.builder(
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
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 15),
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
                                        'Total Payable: \$${transaction['total_payable'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            'Paid Amount: \$${transaction['cus_paid_amount'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                                color: const Color.fromARGB(
                                                    255, 5, 5, 5)),
                                          ),
                                          Spacer(),
                                          Text(
                                            'Balance: \$${transaction['cus_balance'].toStringAsFixed(2)}',
                                            style: TextStyle(
                                                color: const Color.fromARGB(
                                                    255, 9, 9, 9)),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        'Transaction Date: ${transaction['transaction_date']}',
                                        style: TextStyle(
                                            color: const Color.fromARGB(
                                                255, 14, 13, 13)),
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Text(
                                            'Type: ${transaction['type']}',
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                          Spacer(),
                                          Text(
                                            'Method 1: ${transaction['method1']}',
                                            style: TextStyle(
                                              color: transaction['method1'] ==
                                                      'Cash'
                                                  ? Colors.green
                                                  : Colors.orange,
                                            ),
                                          ),
                                          Spacer(),
                                          Text(
                                            'Method 2: ${transaction['method2']}',
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Text(
                                            'Item Count: ${transaction['item_count']}',
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                          Spacer(),
                                          Text(
                                            'User ID: ${transaction['user_id']}',
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            TransactionDetailPage(
                                                transactionId: transaction[
                                                    'transaction_id']),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          _startDateController.text = picked.toString().split(' ')[0];
        } else {
          endDate = picked;
          _endDateController.text = picked.toString().split(' ')[0];
        }
        isSearchExpanded = false; // Collapse on date selection
      });
    }
  }

  Future<void> fetchLogDetails() async {
    if (startDate == null || endDate == null) {
      setState(() {
        errorMessage = 'Please select both start and end dates.';
      });
      return;
    }

    String? custId = await secureStorage.read(key: 'id');
    if (custId == null) {
      setState(() {
        errorMessage = 'Customer ID not found.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      dateRanges.clear();
      dateRangeToUserId.clear();
      dataList.clear();
    });

    try {
      final response = await http.get(
        Uri.parse(baseURL +
            'filterLogs/$custId/${startDate!.toIso8601String()}/${endDate!.toIso8601String()}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(data);
        setState(() {
          dateRangeToUserId = {
            for (var log in data)
              '${DateTime.parse(log['ShiftStarted']).toLocal()} - ${log['ShiftEnd'] != null ? DateTime.parse(log['ShiftEnd']).toLocal() : 'Ongoing'}':
                  log['Userid'].toString()
          };
          dateRanges = dateRangeToUserId.keys.toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load logs');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
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

    if (userId == 'All') {
      // Fetch transactions for all user IDs
      for (String id in dateRangeToUserId.values.toSet()) {
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
        isLoading = false; // Hide loading indicator after data is fetched
      });
    }
  }

  Widget _buildDepartmentsView() {
    return isLoading
        ? Center(
            child: CircularProgressIndicator(), // Loading indicator
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
                                Text('Product: ${item['item']}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('Quantity: ${item['quantity']}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
                                Text(
                                    'Amount: \$${double.tryParse(item['amount'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w500)),
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
