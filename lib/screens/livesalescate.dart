import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skilltest/screens/livesalesDepwise.dart';
import 'package:skilltest/screens/transactionPage.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/nointernet.dart';

class livesalesCategoriesPage extends StatelessWidget {
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
          backgroundColor: Colors.teal,
          title: Text(
            'Live sales Category',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
                          builder: (context) =>
                              DepartmentDetailslivesalesPage()),
                    );
                  },
                ),
                onTap: () {
                  // Navigate to Departments page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DepartmentDetailslivesalesPage()),
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
                          builder: (context) => TransactionListPage()),
                    );
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => TransactionListPage()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    });
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
