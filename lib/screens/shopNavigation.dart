import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:skilltest/models/navigationBar.dart'; // Ensure this path is correct
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/nointernet.dart'; // Ensure this path is correct

class ShopDetailsScreen extends StatefulWidget {
  @override
  _ShopDetailsScreenState createState() => _ShopDetailsScreenState();
}

class _ShopDetailsScreenState extends State<ShopDetailsScreen> {
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();
  late Future<List<dynamic>> shopListFuture;

  @override
  void initState() {
    super.initState();
    shopListFuture = fetchShopDetails();
  }

  Future<List<dynamic>> fetchShopDetails() async {
    String? id = await secureStorage.read(key: 'user_id');
    String? shopIdsString = await secureStorage.read(key: 'shop_ids');
    try {
      final response = await http.get(
        Uri.parse(baseURL + 'getMobileshop'),
        headers: headers, // Ensure you have the headers defined
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<dynamic> filteredShops = data.where((shop) {
          return shopIdsString?.contains(shop['cust_id'].toString()) ?? false;
        }).toList();

        return filteredShops;
      } else {
        throw Exception('Failed to load shop details');
      }
    } catch (e) {
      print('Error: $e');
      return [];
    }
  }

  Future<void> _refreshShopList() async {
    setState(() {
      shopListFuture = fetchShopDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
        builder: (context, connectivityService, child) {
      if (!connectivityService.isConnected) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showNoInternetDialog(context);
        });
      }

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
          child: RefreshIndicator(
            onRefresh: _refreshShopList,
            child: FutureBuilder<List<dynamic>>(
              future: shopListFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: Colors.teal,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshShopList,
                          child: Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'No shops available',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey[600]),
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _refreshShopList,
                          child: Text(
                            'Refresh',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.teal,
                          ),
                        ),
                      ],
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
                      elevation: 8.0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16.0),
                        leading: CircleAvatar(
                          backgroundColor: Colors.teal.shade100,
                          child: Icon(Icons.store, color: Colors.teal),
                        ),
                        title: Text(
                          shop['shopname'],
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: IconButton(
                          icon:
                              Icon(Icons.arrow_forward_ios, color: Colors.teal),
                          onPressed: () async {
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
                        onTap: () async {
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
          ),
        ),
      );
    });
  }
}
