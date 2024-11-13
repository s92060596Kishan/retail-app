import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:skilltest/screens/stockScan.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/nointernet.dart';

class SelectedProductsScreen extends StatefulWidget {
  // final List<Map<String, dynamic>> initialSelectedProducts;
  // final ValueChanged<List<Map<String, dynamic>>> onUpdate;

  // SelectedProductsScreen({
  //   required this.initialSelectedProducts,
  //   required this.onUpdate,
  // });

  @override
  _SelectedProductsScreenState createState() => _SelectedProductsScreenState();
}

class _SelectedProductsScreenState extends State<SelectedProductsScreen> {
  List<Map<String, dynamic>> productsWithQuantity = [];
  List<TextEditingController> rawStockControllers = [];
  List<TextEditingController> caseStockControllers = [];
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    String? storedProducts = await secureStorage.read(key: 'selectedProducts');

    if (storedProducts != null) {
      productsWithQuantity =
          List<Map<String, dynamic>>.from(json.decode(storedProducts));
    } else {
      //productsWithQuantity = widget.initialSelectedProducts;
    }

    // Initialize controllers with current values
    for (var product in productsWithQuantity) {
      rawStockControllers.add(TextEditingController(
        text: (product['rawStock'] ?? 0).toString(),
      ));
      caseStockControllers.add(TextEditingController(
        text: (product['caseStock'] ?? 0).toString(),
      ));
    }

    setState(() {});
  }

  @override
  void dispose() {
    for (var controller in rawStockControllers) {
      controller.dispose();
    }
    for (var controller in caseStockControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void removeProduct(int index) async {
    setState(() {
      // Log the current state before removal
      print("Products before removal: $productsWithQuantity");

      // Remove the product at the specified index
      productsWithQuantity.removeAt(index);
      rawStockControllers.removeAt(index);
      caseStockControllers.removeAt(index);

      // Log the state after removal
      print("Products after removal: $productsWithQuantity");
    });

    // Create a list of products without the controllers for saving
    List<Map<String, dynamic>> productsToSave =
        productsWithQuantity.map((product) {
      return {
        'description': product['description'],
        'productId': product['productId'],
        'rawStock': product['rawStock'],
        'caseStock': product['caseStock'],
      };
    }).toList();

    // Save the updated list back to secure storage
    await secureStorage.write(
      key: 'selectedProducts',
      value: jsonEncode(productsToSave), // Save the serializable products
    );

    // Check the contents of storage after saving
    String? storedProducts = await secureStorage.read(key: 'selectedProducts');
    print("Current stored products after removal: $storedProducts");

    // Notify the parent widget of the update
    // widget.onUpdate(productsWithQuantity);
  }

  void updateQuantityType(int index, String? value) {
    setState(() {
      productsWithQuantity[index]['quantityType'] = value;
    });
  }

  void updateQuantity(int index, String value) {
    setState(() {
      productsWithQuantity[index]['quantity'] = int.tryParse(value) ?? 1;
    });
  }

  void incrementStock(int index, bool isRawStock) {
    setState(() {
      if (isRawStock) {
        productsWithQuantity[index]['rawStock']++;
      } else {
        productsWithQuantity[index]['caseStock']++;
      }
      rawStockControllers[index].text =
          productsWithQuantity[index]['rawStock'].toString();
      caseStockControllers[index].text =
          productsWithQuantity[index]['caseStock'].toString();
    });
  }

  void decrementStock(int index, bool isRawStock) {
    setState(() {
      if (isRawStock && productsWithQuantity[index]['rawStock'] > 0) {
        productsWithQuantity[index]['rawStock']--;
      } else if (!isRawStock && productsWithQuantity[index]['caseStock'] > 0) {
        productsWithQuantity[index]['caseStock']--;
      }
      rawStockControllers[index].text =
          productsWithQuantity[index]['rawStock'].toString();
      caseStockControllers[index].text =
          productsWithQuantity[index]['caseStock'].toString();
    });
  }

  void updateStockCount(int index, String value, bool isRawStock) {
    setState(() {
      if (isRawStock) {
        productsWithQuantity[index]['rawStock'] = int.tryParse(value) ?? 0;
      } else {
        productsWithQuantity[index]['caseStock'] = int.tryParse(value) ?? 0;
      }
    });
  }

  Future<void> _saveProducts() async {
    String? custId = await secureStorage.read(key: 'id');
    final url = baseURL + 'savescanProducts/$custId';

    // Create a list of products without the controllers for saving
    List<Map<String, dynamic>> productsToSave =
        productsWithQuantity.map((product) {
      return {
        'description': product['description'],
        'productId': product['productId'],
        'rawStock': product['rawStock'],
        'caseStock': product['caseStock'],
        // Add other product fields here, but exclude 'controller', 'rawStockController', 'caseStockController'
      };
    }).toList();

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(productsToSave), // Use the modified list for saving
    );

    if (response.statusCode == 200) {
      print(response.body);
      // Clear the stored products after successful save
      await secureStorage.delete(key: 'selectedProducts');

      // Clear the list of products
      setState(() {
        productsWithQuantity.clear();
        rawStockControllers.clear();
        caseStockControllers.clear();
      });
      //widget.onUpdate(productsWithQuantity);
      // Navigate back to the previous screen
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Products saved successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save products: ${response.body}")),
      );
    }
  }

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

      return WillPopScope(
          onWillPop: () async {
            // Navigate to ScanProductScreen when back button is pressed
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => ScanProductScreen()),
            );
            return false; // Returning false to prevent default back navigation
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                "Selected Products",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              backgroundColor: Colors.teal,
            ),
            body: Container(
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
              child: Column(
                children: [
                  Expanded(
                    child: productsWithQuantity.isEmpty
                        ? Center(child: Text("No products selected"))
                        : ListView.builder(
                            itemCount: productsWithQuantity.length,
                            itemBuilder: (context, index) {
                              final product = productsWithQuantity[index];
                              return Card(
                                margin: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                color: Color.fromARGB(255, 97, 97, 97),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product['description'] ??
                                            'Unknown Product',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      // Raw Stock and Case Stock Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Raw Stock
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  "Raw Stock:",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.remove,
                                                          color: Colors.white),
                                                      onPressed: () {
                                                        decrementStock(
                                                            index, true);
                                                      },
                                                    ),
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            rawStockControllers[
                                                                index],
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          10),
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        onChanged: (value) {
                                                          updateStockCount(
                                                              index,
                                                              value,
                                                              true);
                                                        },
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.add,
                                                          color: Colors.white),
                                                      onPressed: () {
                                                        incrementStock(
                                                            index, true);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          // Case Stock
                                          Expanded(
                                            child: Column(
                                              children: [
                                                Text(
                                                  "Case Stock:",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colors.white),
                                                ),
                                                Row(
                                                  children: [
                                                    IconButton(
                                                      icon: Icon(Icons.remove,
                                                          color: Colors.white),
                                                      onPressed: () {
                                                        decrementStock(
                                                            index, false);
                                                      },
                                                    ),
                                                    Expanded(
                                                      child: TextField(
                                                        controller:
                                                            caseStockControllers[
                                                                index],
                                                        decoration:
                                                            InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          contentPadding:
                                                              EdgeInsets
                                                                  .symmetric(
                                                                      horizontal:
                                                                          10),
                                                        ),
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        onChanged: (value) {
                                                          updateStockCount(
                                                              index,
                                                              value,
                                                              false);
                                                        },
                                                      ),
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.add,
                                                          color: Colors.white),
                                                      onPressed: () {
                                                        incrementStock(
                                                            index, false);
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      // Remove Button
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            removeProduct(index);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  // Save Button
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      onPressed: _saveProducts,
                      child: Text("Save Products"),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ));
    });
  }
}
