// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:skilltest/services/baseurl.dart';
// import 'package:skilltest/services/currencyget.dart';

// class QuickTransactionListPage extends StatefulWidget {
//   const QuickTransactionListPage({Key? key}) : super(key: key);

//   @override
//   _TransactionListPageState createState() => _TransactionListPageState();
// }

// class _TransactionListPageState extends State<QuickTransactionListPage> {
//   late List<Map<String, dynamic>> dataList = [];
//   bool isLoading = true;
//   String errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     fetchData();
//   }

//   Future<void> fetchData() async {
//     final FlutterSecureStorage secureStorage = FlutterSecureStorage();
//     String? userId = await secureStorage.read(key: 'id');

//     if (userId == null) {
//       setState(() {
//         isLoading = false;
//         errorMessage = 'User ID not found.';
//       });
//       return;
//     }

//     try {
//       final response = await http.get(
//         Uri.parse(baseURL + 'getsales/$userId'),
//         headers: headers,
//       );

//       if (response.statusCode == 200) {
//         if (response.headers['content-type']?.contains('application/json') ??
//             false) {
//           final List<dynamic> data = jsonDecode(response.body);

//           setState(() {
//             dataList = data
//                 .map((item) => {
//                       'title': 'Transaction# ${item['transactionId'] ?? ''}',
//                       'total_payable':
//                           double.tryParse(item['total_payable']) ?? 0,
//                       'cus_paid_amount':
//                           double.tryParse(item['cus_paid_amount']) ?? 0,
//                       'cus_balance': double.tryParse(item['cus_balance']) ?? 0,
//                       'transaction_date': item['transaction_date'] ?? '',
//                       'type': item['type'] ?? '',
//                       'method1': item['method1'] ?? '',
//                       'method2': item['method2'] ?? '',
//                       'user_id': item['user_id'] ?? '',
//                       'item_count': item['item_count'] ?? 0,
//                       'transaction_id':
//                           item['transactionId'] ?? '', // Include transactionId
//                     })
//                 .toList();
//             isLoading = false;
//           });
//         } else {
//           throw Exception('Invalid content type');
//         }
//       } else {
//         throw Exception('Failed to load data');
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//         errorMessage = 'Error: $e';
//       });
//     }
//   }

//   Future<void> refreshData() async {
//     setState(() {
//       isLoading = true;
//     });
//     await fetchData();
//   }

//   @override
//   Widget build(BuildContext context) {
//     String? currencySymbol = CurrencyService().currencySymbol;
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('All Transactions'),
//         flexibleSpace: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               colors: [Colors.teal, Colors.blueAccent],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//       ),
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Color(0xFF001a1a), // Start color
//               Color(0xFF005959), // Middle color
//               Color(0xFF0fbf7f), // End color
//             ],
//           ),
//         ),
//         child: RefreshIndicator(
//           onRefresh: refreshData,
//           child: isLoading
//               ? Center(child: CircularProgressIndicator())
//               : errorMessage.isNotEmpty
//                   ? Center(child: Text(errorMessage))
//                   : dataList.isEmpty
//                       ? Center(child: Text('No transactions available.'))
//                       : ListView.builder(
//                           itemCount: dataList.length,
//                           itemBuilder: (context, index) {
//                             final transaction = dataList[index];

//                             return Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: Card(
//                                 elevation: 4.0,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10.0),
//                                 ),
//                                 child: ListTile(
//                                   contentPadding: EdgeInsets.symmetric(
//                                       vertical: 10, horizontal: 15),
//                                   title: Row(
//                                     children: [
//                                       Text(
//                                         '${transaction['title']}',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.blueGrey[700],
//                                           fontSize: 14,
//                                         ),
//                                       ),
//                                       Spacer(),
//                                       Text(
//                                         'Total Payable: \ $currencySymbol ${transaction['total_payable'].toStringAsFixed(2)}',
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.blueAccent,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   subtitle: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Text(
//                                             'Paid Amount: \ $currencySymbol ${transaction['cus_paid_amount'].toStringAsFixed(2)}',
//                                             style: TextStyle(
//                                                 color: const Color.fromARGB(
//                                                     255, 5, 5, 5)),
//                                           ),
//                                           Spacer(),
//                                           Text(
//                                             'Balance: \ $currencySymbol ${transaction['cus_balance'].toStringAsFixed(2)}',
//                                             style: TextStyle(
//                                                 color: const Color.fromARGB(
//                                                     255, 9, 9, 9)),
//                                           ),
//                                         ],
//                                       ),
//                                       SizedBox(height: 5),
//                                       Text(
//                                         'Transaction Date: ${transaction['transaction_date']}',
//                                         style: TextStyle(
//                                             color: const Color.fromARGB(
//                                                 255, 14, 13, 13)),
//                                       ),
//                                       SizedBox(height: 5),
//                                       Row(
//                                         children: [
//                                           Text(
//                                             'Type: ${transaction['type']}',
//                                             style: TextStyle(
//                                                 color: Colors.grey[600]),
//                                           ),
//                                           Spacer(),
//                                           Text(
//                                             'Method 1: ${transaction['method1']}',
//                                             style: TextStyle(
//                                               color: transaction['method1'] ==
//                                                       'Cash'
//                                                   ? Colors.green
//                                                   : Colors.orange,
//                                             ),
//                                           ),
//                                           Spacer(),
//                                           Text(
//                                             'Method 2: ${transaction['method2']}',
//                                             style: TextStyle(
//                                                 color: Colors.grey[600]),
//                                           ),
//                                         ],
//                                       ),
//                                       SizedBox(height: 10),
//                                       Row(
//                                         children: [
//                                           Text(
//                                             'Item Count: ${transaction['item_count']}',
//                                             style: TextStyle(
//                                                 color: Colors.grey[600]),
//                                           ),
//                                           Spacer(),
//                                           Text(
//                                             'User ID: ${transaction['user_id']}',
//                                             style: TextStyle(
//                                                 color: Colors.grey[600]),
//                                           ),
//                                         ],
//                                       )
//                                     ],
//                                   ),
//                                   onTap: () {
//                                     // Navigator.push(
//                                     //   context,
//                                     //   MaterialPageRoute(
//                                     //     builder: (context) =>
//                                     //         TransactionDetailPage(
//                                     //             transactionId: transaction[
//                                     //                 'transaction_id']),
//                                     //   ),
//                                     // );
//                                   },
//                                 ),
//                               ),
//                             );
//                           },
//                         ),
//         ),
//       ),
//     );
//   }
// }
