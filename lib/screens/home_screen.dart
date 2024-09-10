// import 'dart:convert';
//php artisan serve --host=192.168.231.1 --port=8000
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/screens/category.dart';
import 'package:skilltest/screens/categorypaymentType.dart';
import 'package:skilltest/screens/shopNavigation.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:webview_flutter/webview_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late double totalSales = 0;
  late double profit = 0;
  late double cost = 0;
  late List<Map<String, dynamic>> dataList = [];
  Map<String, double> transactionTypeTotals =
      {}; // To store totals for each type

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? userId = await secureStorage.read(key: 'id');
    print(userId);
    try {
      var response = await http.get(
        Uri.parse(baseURL + 'getsales/${userId}'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final data = jsonDecode(response.body) as List<dynamic>;
          int totalSalesCount = 0;
          double totalProfit = 0;

          List<Map<String, dynamic>> dataList = [];
          Map<String, double> tempTypeTotals =
              {}; // To store totals for each type

          data.forEach((item) {
            totalSalesCount += 1; // Increment sales count for each entity
            totalProfit += double.tryParse(item['total_payable']) ?? 0;

            String type = item['type'] ?? 'Unknown';

            // Calculate the total payable for each transaction type
            tempTypeTotals[type] = (tempTypeTotals[type] ?? 0) +
                (double.tryParse(item['total_payable']) ?? 0);

            dataList.add({
              'title': 'Transaction ${item['transactionId'] ?? ''}',
              'total_payable': double.tryParse(item['total_payable']) ?? 0,
              'cus_paid_amount': double.tryParse(item['cus_paid_amount']) ?? 0,
              'cus_balance': double.tryParse(item['cus_balance']) ?? 0,
              'transaction_date': item['transaction_date'] ?? '',
              'type': type,
              'method1': item['method1'] ?? '',
              'method2': item['method2'],
              'user_id': item['user_id'],
              'item_count': item['item_count'],
              'transactionId': item['transactionId'] ?? '',
            });
          });

          setState(() {
            this.totalSales = totalSalesCount.toDouble();
            this.profit = totalProfit;
            this.dataList = dataList;
            this.transactionTypeTotals =
                tempTypeTotals; // Update the state with transaction type totals
          });
        } else {
          throw Exception('Invalid content type');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error: $e');
      // Handle error appropriately in your app, e.g., show a snackbar or dialog
    }
  }

  Future<void> refreshData() async {
    await fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Text(
            'Posvega-Retails',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            // Add a back icon button
            icon: Icon(
              Icons.arrow_back, // Use an arrow back icon
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ShopDetailsScreen(), // Navigate to ShopDetails
                ),
              );
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.account_circle,
                color: Colors.black,
              ),
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //       builder: (context) =>
                //           MenuScreen(user:loggedInUser)),
                // );
              },
            ),
          ],
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF001a1a), Color(0xFF005959), Color(0xFF0fbf7f)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: RefreshIndicator(
            onRefresh: refreshData,
            child: ListView(
              padding: EdgeInsets.all(20),
              children: [
                AnimatedTileCard(
                  title: 'Total Sales',
                  icon: Icons.receipt,
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 247, 149, 69),
                      Color(0xFF0033CC)
                    ], // Cyan green to deep blue
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CategoriesPage()),
                    );
                  },
                  trailing: Icon(Icons.arrow_forward_ios,
                      color: Colors.white, size: 30), // Add trailing icon
                  amount:
                      '${totalSales.toInt()} Sales', // Show total sales as transaction count
                ),
                SizedBox(height: 20),
                AnimatedTileCard(
                  title: 'Total Sales Amount',
                  icon: Icons.attach_money,
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF50C878),
                      Color(0xFF008080)
                    ], // Mint green to teal blue
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),

                  onTap: () {
                    // showDetailModel(context, 'profit');
                  },
                  amount:
                      '\$${profit.toStringAsFixed(2)}', // Show profit as the sum of total_payable
                ),
                SizedBox(height: 20),

                // Dynamically generate tiles for each transaction type
                ...transactionTypeTotals.keys.map((type) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: AnimatedTileCard(
                      title: '$type Transactions',
                      icon: Icons.monetization_on,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF1E88E5),
                          Color(0xFF0D47A1)
                        ], // Royal blue shades
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),

                      onTap: () {
                        // Filter the transactions for this type
                        final filteredTransactions = dataList
                            .where((transaction) => transaction['type'] == type)
                            .toList();
                        // Navigate to the transaction details page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoriesTypePage(
                              transactionType: type,
                              transactions: filteredTransactions,
                            ),
                          ),
                        );
                      },
                      amount:
                          '\$${transactionTypeTotals[type]?.toStringAsFixed(2) ?? '0.00'}',
                      trailing: Icon(Icons.arrow_forward_ios,
                          color: Colors.white, size: 30), // Add trailing icon
                    ),
                  );
                }).toList(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ));
  }
}

class AnimatedTileCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final String amount;
  final Widget? trailing;

  const AnimatedTileCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    required this.amount,
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
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
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
            children: [
              Icon(
                widget.icon,
                color: Colors.white,
                size: 40,
              ),
              SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Total Amount: ${widget.amount}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (widget.trailing != null)
                Padding(
                  padding: const EdgeInsets.only(
                      left:
                          18.0), // Adjust this padding to move the trailing widget right
                  child: widget.trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DataTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> filteredData;
  final String columnTitle;

  const DataTableWidget({
    required this.filteredData,
    required this.columnTitle,
  });

  @override
  Widget build(BuildContext context) {
    return DataTable(
      columns: [
        DataColumn(label: Text('Title')),
        DataColumn(label: Text(columnTitle)),
        DataColumn(label: Text('Date')), // New DataColumn
      ],
      rows: filteredData.map((item) {
        return DataRow(cells: [
          DataCell(Text(item['title'])),
          DataCell(Text('${item['value'].toStringAsFixed(2)}')),
          DataCell(Text(item['date'] ??
              '')), // Display formatted date or empty string if null
        ]);
      }).toList(),
    );
  }
}

class WebViewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Web View'),
      ),
      body: WebView(
        initialUrl: 'https://posvega.com/',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
