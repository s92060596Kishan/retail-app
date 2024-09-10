import 'package:flutter/material.dart';

class TransactionTypewisePage extends StatelessWidget {
  final String transactionType;
  final List<Map<String, dynamic>> transactions;

  const TransactionTypewisePage({
    required this.transactionType,
    required this.transactions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('$transactionType Transactions'),
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
          child: ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];

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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Paid Amount: \$${transaction['cus_paid_amount'].toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 5, 5, 5)),
                            ),
                            Spacer(),
                            Text(
                              'Balance: \$${transaction['cus_balance'].toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 9, 9, 9)),
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
                              'User ID: ${transaction['user_id']}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        )
                      ],
                    ),
                    onTap: () {
                      // Navigator.push(
                      //   context,
                      //   MaterialPageRoute(
                      //     builder: (context) =>
                      //         TransactionDetailPage(
                      //             transactionId: transaction[
                      //                 'transaction_id']),
                      //   ),
                      // );
                    },
                  ),
                ),
              );
            },
          ),
        ));
  }
}
