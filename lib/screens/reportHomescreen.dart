//import 'dart:convert';
//php artisan serve --host=192.168.242.1 --port=8000
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:skilltest/screens/filterdataTransactio.dart';
import 'package:skilltest/screens/posrecordstiles.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/currencyget.dart';
import 'package:skilltest/services/nointernet.dart';

class ReportHomeScreen extends StatefulWidget {
  final String filterValue;
  Map<String, String> dateRangeToUserId = {};

  ReportHomeScreen(
      {required this.filterValue, required this.dateRangeToUserId});

  @override
  _ReportHomeScreenState createState() => _ReportHomeScreenState();
}

class _ReportHomeScreenState extends State<ReportHomeScreen> {
  late double totalSales = 0;
  late double profit = 0;
  late double cost = 0;
  late List<Map<String, dynamic>> dataList = [];
  late List<Map<String, dynamic>> dataList1 = [];
  double totalSalesAmount = 0.0;

  Map<String, int> transactionTypeCounts = {}; // Add this line for counts
  Map<String, double> transactionTypeTotals =
      {}; // To store totals for each type
  Map<String, List<Map<String, dynamic>>> transactionsByType =
      {}; // To store transactions by type
  bool isLoading = true;
  String errorMessage = '';
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
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
        await fetchTransactionsForUser(id);
        await fetchPOSRecords(id);
      }
    } else {
      await fetchTransactionsForUser(userId);
      await fetchPOSRecords(userId);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchPOSRecords(String logId) async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? Cust_id = await secureStorage.read(key: 'id'); // Fetch customer ID

    if (Cust_id == null) {
      setState(() {
        errorMessage = 'Customer ID not found.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(baseURL + 'getposrecord/$Cust_id/$logId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> posRecords = jsonDecode(response.body);
        print('Transactions for logId $logId: $posRecords');
        setState(() {
          dataList1.addAll(posRecords
              .map((item) => {
                    'Rec_Id': 'Records# ${item['Rec_Id'] ?? ''}',
                    'Rec_Type': item['Rec_Type'] ?? '',
                    'Rec_Date': item['Rec_Date'] ?? '',
                    'Record': item['Record'] ?? '',
                    'LogId': item['LogId'] ?? 0,
                    'Rec_Item': item['Rec_Item'] ?? '',
                    'reason': item['reason'] ?? '',
                    'Userid': item['userName'] ?? '',
                  })
              .toList());
        });
      } else {
        throw Exception(
            'Failed to load POS records. Status Code: ${response.body}');
      }
      print(response.statusCode);
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching POS records: $e';
      });
      print(errorMessage);
    }
  }

  Future<void> fetchTransactionsForUser(String userId) async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? Cust_id = await secureStorage.read(key: 'id'); // Fetch customer ID

    if (Cust_id == null) {
      setState(() {
        errorMessage = 'Customer ID not found.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(baseURL + 'getactivesales/$Cust_id/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final List<dynamic> transactions = jsonDecode(response.body);
          print('Transactions for UserId $userId: $transactions');

          setState(() {
            dataList.addAll(transactions
                .map((item) => {
                      'title': 'Transaction# ${item['transactionId'] ?? ''}',
                      'total_payable':
                          double.tryParse(item['total_payable'].toString()) ??
                              0,
                      'cus_paid_amount':
                          double.tryParse(item['cus_paid_amount'].toString()) ??
                              0,
                      'cus_balance':
                          double.tryParse(item['cus_balance'].toString()) ?? 0,
                      'transaction_date': item['transaction_date'] ?? '',
                      'type': item['type'] ?? '',
                      'method1':
                          double.tryParse(item['method1'].toString()) ?? 0,
                      'method2':
                          double.tryParse(item['method2'].toString()) ?? 0,
                      'user_id': item['user_id'] ?? '',
                      'item_count': item['item_count'] ?? 0,
                      'transaction_id': item['transactionId'] ?? '',
                    })
                .toList());

            // Group transactions by type
            transactionsByType.clear();
            for (var item in dataList) {
              final type = item['type'] as String? ?? 'Unknown';
              if (!transactionsByType.containsKey(type)) {
                transactionsByType[type] = [];
              }
              transactionsByType[type]!.add(item);
            }

            // Clear previous totals and counts
            transactionTypeTotals.clear();
            transactionTypeCounts.clear();
            double totalActiveSalesAmount = 0;
            double totalMethod1Sum = 0; // Sum of method1 (PartPay only)
            double totalMethod2Sum = 0; // Sum of method2 (PartPay only)
            double totalPayforPart = 0;
            transactionsByType.forEach((type, transactions) {
              double totalPayable = 0;
              int count = transactions.length;

              if (type == 'PartPay') {
                // Sum the method1 and method2 values separately for "PartPay" transactions
                for (var item in transactions) {
                  totalMethod1Sum +=
                      double.tryParse(item['method1'].toString()) ?? 0;
                  totalMethod2Sum +=
                      double.tryParse(item['method2'].toString()) ?? 0;
                  totalPayforPart +=
                      double.tryParse(item['total_payable'].toString()) ?? 0;
                }
                totalPayable = transactions.fold(0, (sum, item) {
                  double payable = item['total_payable'] as double? ?? 0;
                  print(
                      "Transaction for type $type has total_payable: $payable"); // Debugging
                  return sum + payable;
                });
              } else {
                // For all other transaction types, calculate total payable normally
                totalPayable = transactions.fold(0, (sum, item) {
                  double payable = item['total_payable'] as double? ?? 0;
                  print(
                      "Transaction for type $type has total_payable: $payable"); // Debugging
                  return sum + payable;
                });
                totalActiveSalesAmount += totalPayable;
                // Now handle the case for "Cash" and "Card"
                if (type == 'Cash') {
                  // Add totalMethod1Sum for Cash transactions
                  totalPayable += totalMethod1Sum;
                } else if (type == 'Card') {
                  // Add totalMethod2Sum for Card transactions
                  totalPayable += totalMethod2Sum;
                }
              }

              // Store totals and counts for each type
              transactionTypeTotals[type] = totalPayable;
              transactionTypeCounts[type] = count;
            });

            // Update state with the calculated sums
            setState(() {
              for (var type in ['Cash', 'Card', 'PartPay']) {
                transactionTypeTotals[type] = transactionTypeTotals[type] ?? 0;
                transactionTypeCounts[type] = transactionTypeCounts[type] ?? 0;
              }

              // Handling "Cash"
              if (transactionTypeTotals['Cash'] == 0) {
                // If there are no "Cash" transactions, just show totalMethod1Sum (which may still have a value)
                transactionTypeTotals['Cash'] = totalMethod1Sum;
              }

              // Handling "Card"
              if (transactionTypeTotals['Card'] == 0) {
                // If there are no "Card" transactions, just show totalMethod2Sum (which may still have a value)
                transactionTypeTotals['Card'] = totalMethod2Sum;
              }

              totalSalesAmount = totalActiveSalesAmount + totalPayforPart;
            });
          });
        } else {
          throw Exception('Invalid content type received');
        }
      } else {
        throw Exception(
            'Failed to load transactions. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching transactions: $e';
      });
    }
  }

  Future<void> refreshData() async {
    dataList.clear();
    dataList1.clear();
    await fetchTransactions(widget.filterValue);
  }

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;

    // Define the order of transaction types
    final List<String> orderedTransactionTypes = ['Cash', 'Card', 'PartPay'];

    // Create a list of all transaction types (e.g., Cash, Card, PartPay, etc.)
    final List<String> allTransactionTypes = transactionsByType.keys.toList();

    // Identify and collect "Other" transaction types (those not in the ordered list)
    final List<String> otherTransactionTypes = allTransactionTypes
        .where((type) => !orderedTransactionTypes.contains(type))
        .toList();

    // Combine the ordered transaction types and the "Other" transaction types
    final List<String> transactionDisplayOrder = [
      ...orderedTransactionTypes,
      ...otherTransactionTypes
    ];
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
          // flexibleSpace: Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       colors: [Colors.teal, Colors.blueAccent],
          //       begin: Alignment.topLeft,
          //       end: Alignment.bottomRight,
          //     ),
          //   ),
          // ),
          backgroundColor: Color.fromARGB(255, 0, 173, 156),
          title: Text(
            'Reports Menu',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: isLoading
            ? Container(
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
                child: Center(child: CircularProgressIndicator()))
            : Container(
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
                child: RefreshIndicator(
                  onRefresh: refreshData,
                  child: ListView(
                    children: [
                      // Show total sales
                      AnimatedTileCard(
                        title: 'Total Sales',
                        icon: Icons.receipt,
                        count: '${dataList.length} Sales',
                        amount:
                            '\ $currencySymbol ${totalSalesAmount.toStringAsFixed(2)}',
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 30), // Add trailing icon
                        //color: Color(0xFF17876D),
                        color: Color(0xFF26A69A),
                        // gradient: LinearGradient(
                        //   colors: [
                        //     Color(0xFF1D976C),
                        //     Color(
                        //         0xFF93F9B9), // Blue color// Repeated blue color for a single color gradient
                        //   ],
                        //   begin: Alignment.topLeft,
                        //   end: Alignment.bottomRight,
                        // ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => FilterDetailsPage(
                                    filterValue: widget.filterValue,
                                    dateRangeToUserId:
                                        widget.dateRangeToUserId)),
                          );
                        },
                      ),
                      AnimatedTileCard(
                        title: 'Exceptions',
                        icon: Icons.info_outline,
                        //color: Color(0xFF095544),
                        color: Color(0xFF4DB6AC),
                        onTap: () {
                          // showDetailModel(context, 'profit');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PosrecordsPage(records: dataList1),
                            ),
                          );
                        },
                        count:
                            '${dataList1.length} ', // Show profit as the sum of total_payable
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 30), // Add trailing icon
                      ),
                      // Show transactions by type
                      ...transactionDisplayOrder
                          .where((type) =>
                              (transactionTypeTotals[type] ?? 0) > 0 ||
                              (transactionTypeCounts[type] ?? 0) > 0)
                          .map((type) {
                        double totalAmount = transactionTypeTotals[type] ??
                            0; // Get total payable for the type
                        int transactionCount = transactionTypeCounts[type] ??
                            0; // Get count of transactions for the type
                        return AnimatedTileCard(
                          title: '$type Transactions',
                          icon: Icons.monetization_on,
                          count: '${transactionCount ?? 0}',
                          amount:
                              '\ $currencySymbol ${totalAmount.toStringAsFixed(2)}',
                          //color: Color(0xFF08453A),
                          color: Color(0xFF80CBC4),
                          // gradient: LinearGradient(
                          //   colors: [
                          //     // Color(0xFF3c1053), // Light lavender color
                          //     // Color(0xFFad5389), // Light sky blue color
                          //     Color(0xFF11998e),
                          //     Color(0xFF38ef7d),
                          //   ],
                          //   begin: Alignment.topLeft,
                          //   end: Alignment.bottomRight,
                          // ),
                          onTap: () {},
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
      );
    });
  }
}

class AnimatedTileCard extends StatefulWidget {
  final String title;
  final IconData icon;
  //final Gradient gradient;
  final Color color;
  final VoidCallback onTap;
  final String count;
  final String? amount;
  final Widget? trailing;

  const AnimatedTileCard({
    required this.title,
    required this.icon,
    //required this.gradient,
    required this.color,
    required this.onTap,
    required this.count,
    this.amount,
    this.trailing,
  });

  @override
  _AnimatedTileCardState createState() => _AnimatedTileCardState();
}

class _AnimatedTileCardState extends State<AnimatedTileCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: widget.color,
        boxShadow: [
          BoxShadow(
            color:
                Color.fromARGB(255, 7, 7, 7).withOpacity(0.2), // Light shadow
            spreadRadius: 2,
            blurRadius: 6,
            offset: const Offset(0, 3), // Shadow position
          ),
        ],
      ),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (value) {
          setState(() {
            _isHovered = value;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                widget.icon,
                color: Colors.black,
                size: 40,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Total Count: ${widget.count}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    if (widget.amount != null)
                      Text(
                        'Total Amount: ${widget.amount}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 18.0),
                  child: widget.trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
