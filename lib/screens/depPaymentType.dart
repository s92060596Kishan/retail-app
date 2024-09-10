import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/services/baseurl.dart';

class DepartmentDetailsPayTypePage extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const DepartmentDetailsPayTypePage({
    required this.transactions,
    Key? key,
  }) : super(key: key);

  @override
  _DepartmentDetailsPageState createState() => _DepartmentDetailsPageState();
}

class _DepartmentDetailsPageState extends State<DepartmentDetailsPayTypePage> {
  Map<String, List<Map<String, dynamic>>> departmentItemsMap = {};
  List<Map<String, dynamic>> departmentsList = [];
  bool isLoading = true; // Loading indicator state
  final FlutterSecureStorage secureStorage =
      FlutterSecureStorage(); // Secure storage instance

  @override
  void initState() {
    super.initState();
    fetchData(); // Initial data fetch
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true; // Show loading indicator while fetching data
    });

    try {
      String? userId = await secureStorage.read(key: 'id');

      final response = await http.get(
        Uri.parse(baseURL + 'getalltransactionitems/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> departments = data['department'];
        final List<dynamic> items = data['items'];
        print('items : $items');
        print('department : $departments');

        // Extract transaction IDs from the transactions list
        final List<String> transactionIds = widget.transactions
            .map((transaction) => transaction['transactionId'].toString())
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
      // You can show a snackbar or any other error message to the user here
    } finally {
      setState(() {
        isLoading = false; // Hide loading indicator after data is fetched
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Department Details'),
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
            colors: [Color(0xFF001a1a), Color(0xFF005959), Color(0xFF0fbf7f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(16.0),
        child: isLoading // Show loading indicator while loading data
            ? Center(
                child: CircularProgressIndicator(), // Loading indicator
              )
            : RefreshIndicator(
                onRefresh: fetchData, // Refresh data on pull down
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
                                    runSpacing: 10.0, // Space between the lines
                                    children: [
                                      Text('Product: ${item['item']}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      Text('Quantity: ${item['quantity']}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w500)),
                                      Text(
                                          'Amount: \$${double.tryParse(item['amount'].toString())?.toStringAsFixed(2) ?? '0.00'}',
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
      ),
    );
  }
}
