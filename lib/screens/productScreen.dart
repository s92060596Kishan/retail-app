import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skilltest/screens/addproduct.dart';
import 'package:skilltest/screens/searchProduct.dart';
import 'package:skilltest/screens/stockScan.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/nointernet.dart';

class ProductScreen extends StatelessWidget {
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
            'App Features',
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.count(
              crossAxisCount: 2, // 2 tiles in a row
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: <Widget>[
                ProductTile(
                  title: 'Add Products',
                  icon: Icons.add_box_outlined, // Add icon
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AddProductScreen()),
                    );
                  },
                  gradientColors: [Color(0xFFff9a9e), Color(0xFFfad0c4)],
                ),
                ProductTile(
                  title: 'Find Product',
                  icon: Icons.search, // Search icon
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProductsScreen()),
                    );
                  },
                  gradientColors: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
                ),
                ProductTile(
                  title: 'Stock In',
                  icon: Icons.inventory, // Inventory icon
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ScanProductScreen()),
                    );
                  },
                  gradientColors: [Color(0xFFfbc2eb), Color(0xFFa6c1ee)],
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

class ProductTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final List<Color> gradientColors;

  const ProductTile({
    required this.title,
    required this.icon, // Accepting the icon as a parameter
    required this.onTap,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 2,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.black,
              ), // Display the icon
              SizedBox(height: 10), // Space between icon and text
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
