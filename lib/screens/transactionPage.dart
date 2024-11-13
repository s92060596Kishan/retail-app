import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:skilltest/screens/transaction_activeitems.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/currencyget.dart';
import 'package:skilltest/services/nointernet.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({Key? key}) : super(key: key);

  @override
  _TransactionListPageState createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  List<Map<String, dynamic>> dataList = [];
  bool isLoading = true;
  String errorMessage = '';

  List<Map<String, dynamic>> filteredDataList = [];
  Map<String, String> userIdToLogIdMap =
      {}; // Map to store user_id and LogId association
  List<String> userIdOptions = ['All'];
  String selectedUserId = 'All';

  @override
  void initState() {
    super.initState();
    fetchLog();
  }

  Future<void> fetchLog() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? Cust_id = await secureStorage.read(key: 'id');

    if (Cust_id == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Customer ID not found.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(baseURL + 'getLogs/$Cust_id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final Map<String, dynamic> data = jsonDecode(response.body);
          final List<dynamic> activeLogs = data['active_logs'];
          if (activeLogs.isNotEmpty) {
            // Populate the userIdToLogIdMap and userIdOptions
            activeLogs.forEach((log) {
              final String logId = log['LogId'].toString();
              final String userId = log['user_id'].toString();
              userIdToLogIdMap[userId] = logId; // Map user_id to LogId
            });

            // Adding unique user_ids to the dropdown options
            userIdOptions = ['All', ...userIdToLogIdMap.keys.toSet().toList()];
            await fetchAllTransactions(); // Fetch all transactions on init
          } else {
            setState(() {
              errorMessage = 'No logs found';
              isLoading = false;
            });
          }
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

  Future<void> fetchAllTransactions() async {
    await Future.wait([
      ...userIdToLogIdMap.values
          .map((logId) => fetchTransactionsForUser(logId)),
    ]);
    applyFilter();
  }

  Future<void> fetchTransactionsForUser(String logId) async {
    try {
      final FlutterSecureStorage secureStorage = FlutterSecureStorage();
      String? Cust_id = await secureStorage.read(key: 'id');

      if (Cust_id == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'User ID not found.';
        });
        return;
      }

      final response = await http.get(
        Uri.parse(baseURL + 'getactivesales/$Cust_id/$logId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final List<dynamic> transactions = jsonDecode(response.body);

          setState(() {
            // Prevent duplicates by checking if a transaction is already in dataList
            for (var item in transactions) {
              final transactionId = item['transactionId'];
              if (!dataList.any((existingItem) =>
                  existingItem['transaction_id'] == transactionId)) {
                dataList.add({
                  'title': 'Transaction# ${item['transactionId'] ?? ''}',
                  'total_payable': double.tryParse(item['total_payable']) ?? 0,
                  'cus_paid_amount':
                      double.tryParse(item['cus_paid_amount']) ?? 0,
                  'cus_balance': double.tryParse(item['cus_balance']) ?? 0,
                  'transaction_date': item['transaction_date'] ?? '',
                  'type': item['type'] ?? '',
                  'method1': item['method1'] ?? '',
                  'method2': item['method2'] ?? '',
                  'user_id': item['user_id'] ?? '',
                  'item_count': item['item_count'] ?? 0,
                  'transaction_id': transactionId ?? '',
                });
              }
            }

            // Sort transactions by date
            dataList.sort((a, b) {
              DateTime dateA = DateTime.parse(a['transaction_date']);
              DateTime dateB = DateTime.parse(b['transaction_date']);
              return dateB.compareTo(dateA);
            });
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
        errorMessage = 'Error: $e';
      });
    }
  }

  void applyFilter() {
    setState(() {
      if (selectedUserId == 'All') {
        filteredDataList = List.from(dataList);
      } else {
        filteredDataList = dataList
            .where((item) => item['user_id'] == selectedUserId)
            .toList();
      }
    });
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
      dataList.clear();
    });
    await fetchLog();
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
            'Live Sales Transactions',
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
                Color(0xFF001a1a),
                Color(0xFF005959),
                Color(0xFF0fbf7f),
              ],
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: selectedUserId,
                  items: userIdOptions.map((userId) {
                    return DropdownMenuItem(
                      value: userId,
                      child: Text(
                        userId == 'All'
                            ? 'All Transactions'
                            : 'User ID: $userId',
                        style: TextStyle(
                          color:
                              Colors.white, // Set your desired text color here
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) async {
                    setState(() {
                      selectedUserId = newValue!;
                      isLoading = true; // Start loading
                    });

                    if (newValue != 'All') {
                      await fetchTransactionsForUser(
                          userIdToLogIdMap[newValue]!);
                    }

                    applyFilter();

                    setState(() {
                      isLoading = false; // End loading
                    });
                  },
                  dropdownColor:
                      Colors.black, // Set the background color of the dropdown
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: refreshData,
                  child: isLoading
                      ? Center(child: CircularProgressIndicator())
                      : errorMessage.isNotEmpty
                          ? Center(child: Text(errorMessage))
                          : filteredDataList.isEmpty
                              ? Center(
                                  child: Text(
                                  'No transactions available for the selected user.',
                                  style: TextStyle(color: Colors.white),
                                ))
                              : ListView.builder(
                                  itemCount: filteredDataList.length,
                                  itemBuilder: (context, index) {
                                    final transaction = filteredDataList[index];

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
                                                'Total Payable: $currencySymbol ${transaction['total_payable'].toStringAsFixed(2)}',
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
                                                      'Paid Amount: $currencySymbol ${transaction['cus_paid_amount'].toStringAsFixed(2)}'),
                                                  Spacer(),
                                                  Text(
                                                      'Balance: $currencySymbol ${transaction['cus_balance'].toStringAsFixed(2)}'),
                                                ],
                                              ),
                                              SizedBox(height: 5),
                                              Text(
                                                  'Transaction Date: ${transaction['transaction_date']}'),
                                              SizedBox(height: 5),
                                              Row(
                                                children: [
                                                  Text(
                                                      'Type: ${transaction['type']}'),
                                                  Spacer(),
                                                  Text(
                                                      'Method 1: ${transaction['method1']}'),
                                                  Spacer(),
                                                  Text(
                                                      'Method 2: ${transaction['method2']}'),
                                                ],
                                              ),
                                              SizedBox(height: 10),
                                              Row(
                                                children: [
                                                  Text(
                                                      'Item Count: ${transaction['item_count']}'),
                                                  Spacer(),
                                                  Text(
                                                      'User ID: ${transaction['user_id']}'),
                                                ],
                                              ),
                                            ],
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TransactionActiveDetailPage(
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
    });
  }
}
