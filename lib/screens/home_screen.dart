// import 'dart:convert';
//php artisan serve --host=192.168.231.1 --port=8000
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:skilltest/screens/detail_screen.dart';
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
        Uri.parse(baseURL + 'get/${userId}'),
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.headers['content-type']?.contains('application/json') ??
            false) {
          final data = jsonDecode(response.body) as List<dynamic>;

          double totalSales = 0;
          double profit = 0;
          double cost = 0;

          List<Map<String, dynamic>> dataList = [];

          data.forEach((item) {
            totalSales += double.tryParse(item['sales']) ?? 0;
            profit += double.tryParse(item['profit']) ?? 0;
            cost += double.tryParse(item['cost']) ?? 0;

            dataList.add({
              'title': item['title'],
              'sales': double.tryParse(item['sales']) ?? 0,
              'cost': double.tryParse(item['cost']) ?? 0,
              'profit': double.tryParse(item['profit']) ?? 0,
              'created_at': item['timestamp'],
            });
          });

          setState(() {
            this.totalSales = totalSales;
            this.profit = profit;
            this.cost = cost;
            this.dataList = dataList;
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

  void showDetailModel(BuildContext context, String dataType) {
    String? columnTitle;
    List<Map<String, dynamic>> filteredData = [];

    switch (dataType) {
      case 'sales':
        columnTitle = 'Sales';
        filteredData = dataList.map((item) {
          return {
            'title': item['title'],
            'value': item['sales'],
            'date': formatDate(item['created_at'])
          };
        }).toList();
        break;
      case 'cost':
        columnTitle = 'Cost';
        filteredData = dataList.map((item) {
          return {
            'title': item['title'],
            'value': item['cost'],
            'date': formatDate(item['created_at'])
          };
        }).toList();
        break;
      case 'profit':
        columnTitle = 'Profit';
        filteredData = dataList.map((item) {
          return {
            'title': item['title'],
            'value': item['profit'],
            'date': formatDate(item['created_at'])
          };
        }).toList();
        break;
      default:
        break;
    }

    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsScreen(
        filteredData: filteredData,
        columnTitle: columnTitle!,
      ),
    ));
  }

  String formatDate(String? dateString) {
    if (dateString != null && dateString.isNotEmpty) {
      try {
        DateTime dateTime = DateTime.parse(dateString);
        return DateFormat('yyyy-MM-dd').format(dateTime);
      } catch (e) {
        print('Error parsing date: $e');
        return 'Unknown';
      }
    } else {
      return 'Unknown';
    }
  }

  void navigateToWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 132, 177, 255),
        title: Text('Main Screen'),
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
      body: RefreshIndicator(
        onRefresh: refreshData,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            AnimatedTileCard(
              title: 'Total Sales',
              icon: Icons.attach_money,
              gradient: LinearGradient(
                colors: [Colors.green, Colors.lightGreen],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                showDetailModel(context, 'sales');
              },
              amount: '\$${totalSales.toStringAsFixed(2)}',
            ),
            SizedBox(height: 20),
            AnimatedTileCard(
              title: 'Profit',
              icon: Icons.trending_up,
              gradient: LinearGradient(
                colors: [Colors.orange, Colors.deepOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                showDetailModel(context, 'profit');
              },
              amount: '\$${profit.toStringAsFixed(2)}',
            ),
            SizedBox(height: 20),
            AnimatedTileCard(
              title: 'Cost',
              icon: Icons.money_off,
              gradient: LinearGradient(
                colors: [Colors.red, Colors.deepPurple],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () {
                showDetailModel(context, 'cost');
              },
              amount: '\$${cost.toStringAsFixed(2)}',
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                navigateToWebView(context);
              },
              child: Hero(
                tag: 'visitWebPage',
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 10),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      'Visit Webpage',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedTileCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onTap;
  final String amount;

  const AnimatedTileCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    required this.amount,
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
