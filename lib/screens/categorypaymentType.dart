import 'package:flutter/material.dart';
import 'package:skilltest/screens/TransacationTypewise.dart';
import 'package:skilltest/screens/alltransactionitems.dart';
import 'package:skilltest/screens/depPaymentType.dart';

class CategoriesTypePage extends StatelessWidget {
  final String transactionType;
  final List<Map<String, dynamic>> transactions;

  const CategoriesTypePage({
    required this.transactionType,
    required this.transactions,
    Key? key,
  }) : super(key: key);

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
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
        child: ListView(
          children: [
            CategoryTile(
              title: 'Departments',
              icon: Icons.business,
              color: Colors.blueAccent,
              trailing: IconButton(
                icon: Icon(Icons.arrow_forward_ios, color: Colors.black),
                onPressed: () async {
                  // Save selected shop cust_id to secure storage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DepartmentDetailsPayTypePage(
                          transactions:transactions
                        )),
                  );
                },
              ),
              onTap: () {
                // Navigate to Departments page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DepartmentDetailsPayTypePage(
                        transactions: transactions,
                      )),
                );
              },
            ),
            SizedBox(height: 16), // Space between tiles
            CategoryTile(
              title: 'All Transactions',
              icon: Icons.account_balance_wallet,
              color: Color.fromARGB(255, 7, 111, 176),
              trailing: IconButton(
                icon: Icon(Icons.arrow_forward_ios, color: Colors.black),
                onPressed: () async {
                  // Save selected shop cust_id to secure storage
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TransactionTypewisePage(
                              transactionType: transactionType,
                              transactions: transactions,
                            )),
                  );
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TransactionTypewisePage(
                            transactionType: transactionType,
                            transactions: transactions,
                          )),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  CategoryTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: color,
        child: SizedBox(
          width: double.infinity,
          height: 100, // Set a fixed height for the tiles
          child: Row(
            children: [
              SizedBox(width: 16), // Space between left edge and icon
              Icon(
                icon,
                size: 60,
                color: Colors.white,
              ),
              SizedBox(width: 16), // Space between icon and text
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!, // Show trailing widget if provided
              SizedBox(width: 16), // Space between text and trailing widget
            ],
          ),
        ),
      ),
    );
  }
}
