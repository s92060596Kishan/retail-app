import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/models/navigationBar.dart'; // Ensure this path is correct
import 'package:skilltest/services/baseurl.dart'; // Ensure this path is correct

class ShopDetailsScreen extends StatefulWidget {
  @override
  _ShopDetailsScreenState createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  late Future<List<dynamic>> shopListFuture; // Future to fetch shop list

  @override
  void initState() {
    super.initState();
    shopListFuture = fetchShopDetails(); // Initialize the fetch operation
  }

  Future<List<dynamic>> fetchShopDetails() async {
    String? id = await secureStorage.read(key: 'user_id');
    String? shopIdsString = await secureStorage.read(key: 'shop_ids');
    try {
      final response = await http.get(
        Uri.parse(baseURL + 'getMobileshop'), // Replace with your API endpoint
        headers: headers, // Ensure you have the headers defined
      );

      if (response.statusCode == 200) {
        print('Response: ${response.body}');
        print('Status code: ${response.statusCode}');
        List<dynamic> data = jsonDecode(response.body);
        // Filter shops based on shopIds
        List<dynamic> filteredShops = data.where((shop) {
          return shopIdsString?.contains(shop['cust_id'].toString()) ??
              false; // Compare as strings
        }).toList();

        return filteredShops;
      } else {
        throw Exception('Failed to load shop details');
      }
    } catch (e) {
      print('Error: $e');
      return []; // Return an empty list in case of error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Select Your Shop',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: Colors.teal,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF001a1a), Color(0xFF005959), Color(0xFF0fbf7f)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: FutureBuilder<List<dynamic>>(
            future: shopListFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors
                        .teal, // Match loading indicator color with app bar
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: ${snapshot.error}',
                    style: TextStyle(
                        color: Colors.redAccent), // Style error message
                  ),
                );
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text(
                    'No shops available',
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600]), // Style empty state message
                  ),
                );
              }

              final shopList = snapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: shopList.length,
                itemBuilder: (context, index) {
                  final shop = shopList[index];
                  return Card(
                    elevation: 8.0, // Add elevation for shadow
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.0), // Rounded corners
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      contentPadding:
                          EdgeInsets.all(16.0), // Add padding inside the tile
                      leading: CircleAvatar(
                        backgroundColor: Colors
                            .teal.shade100, // Background color for the avatar
                        child: Icon(Icons.store,
                            color: Colors.teal), // Icon representing the shop
                      ),
                      title: Text(
                        shop['shopname'], // Display shop name
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.arrow_forward_ios, color: Colors.teal),
                        onPressed: () async {
                          // Save selected shop cust_id to secure storage
                          await secureStorage.write(
                            key: 'id',
                            value: shop['cust_id'].toString(),
                          );

                          // Navigate to Navigation Bar Screen
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MyNavigationBar(),
                            ),
                          );
                        },
                      ),
                      onTap: () async {
                        // Optional: Handle tap event if needed
                        // Save selected shop cust_id to secure storage
                        await secureStorage.write(
                          key: 'id',
                          value: shop['cust_id'].toString(),
                        );
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyNavigationBar(),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ));
  }
}
