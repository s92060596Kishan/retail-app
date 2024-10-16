import 'dart:convert';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/screens/selected_products_screen.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/currencyget.dart';

class ScanProductScreen extends StatefulWidget {
  @override
  _ScanProductScreenState createState() => _ScanProductScreenState();
}

class _ScanProductScreenState extends State<ScanProductScreen> {
  String scannedBarcode = "";
  Map<String, dynamic>? productDetails;
  bool isLoading = false;
  List<Map<String, dynamic>> selectedProducts = [];
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  // Move stock variables outside the method to retain values
  int rawStock = 0; // For raw stock
  int caseStock = 0; // For case stock
// Declare TextEditingControllers
  final TextEditingController rawStockController = TextEditingController();
  final TextEditingController caseStockController = TextEditingController();

  @override
  void initState() {
    super.initState();
    rawStockController.text = rawStock.toString();
    caseStockController.text = caseStock.toString();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadSelectedProducts(); // Load selected products every time dependencies change
  }

  Future<void> fetchProductDetails(String barcode) async {
    String? custId = await secureStorage.read(key: 'id');
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
          Uri.parse(baseURL + 'scanproducts/$custId/$barcode'),
          headers: headers);

      if (response.statusCode == 200) {
        print(response.body);
        setState(() {
          productDetails = json.decode(response.body);
          rawStock = 0;
          caseStock = 0;
          rawStockController.text = rawStock.toString();
          caseStockController.text = caseStock.toString();
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Product not found.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching product details.")));
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> scanBarcode() async {
    var result = await BarcodeScanner.scan();
    setState(() {
      scannedBarcode = result.rawContent;
      if (scannedBarcode.isNotEmpty) {
        fetchProductDetails(scannedBarcode);
      }
    });
  }

  void selectProduct() async {
    if (productDetails != null) {
      // Check if the product is already in the list
      final existingProductIndex = selectedProducts.indexWhere((prod) =>
          prod['productId'] ==
          productDetails![
              'productId']); // Assuming 'id' is the unique product identifier

      // If the product exists, you can choose to update the quantity or just return
      if (existingProductIndex != -1) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Product already in the selected list.")));
        return;
      }

      // Add new product with stock quantities
      final selectedProduct = {
        ...productDetails!,
        'rawStock': rawStock,
        'caseStock': caseStock,
      };

      setState(() {
        selectedProducts.add(selectedProduct);
      });

      await secureStorage.write(
        key: 'selectedProducts',
        value: jsonEncode(selectedProducts),
      );

      setState(() {
        productDetails = null; // Reset product details after adding
        rawStock = 0;
        caseStock = 0;
        rawStockController.text = rawStock.toString();
        caseStockController.text = caseStock.toString();
      });
    }
  }

  Future<void> loadSelectedProducts() async {
    String? storedProducts = await secureStorage.read(key: 'selectedProducts');
    print(storedProducts);
    if (storedProducts != null) {
      setState(() {
        selectedProducts =
            List<Map<String, dynamic>>.from(jsonDecode(storedProducts));
      });
    } else {
      setState(() {
        selectedProducts = []; // Initialize if no stored products
      });
    }
  }

  void showSelectedProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectedProductsScreen(
            // initialSelectedProducts: selectedProducts,
            // onUpdate: (updatedProducts) {
            //   setState(() {
            //     selectedProducts = updatedProducts; // Update selectedProducts
            //   });
            // }
            ),
      ),
    );
  }

  Future<void> _refresh() async {
    await loadSelectedProducts(); // Ensure to await this call
    initState(); // Ensure the state is updated to refresh the UI
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    rawStockController.dispose();
    caseStockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Add this line
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          "Scan Product",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                tooltip: 'Selected Products',
                onPressed: showSelectedProducts,
              ),
              if (selectedProducts.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      selectedProducts.length.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh, // Call refresh method on pull-to-refresh
        child: Container(
          // Use Container for the entire body
          height: MediaQuery.of(context).size.height, // Full height
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF001a1a),
                Color(0xFF005959),
                Color(0xFF0fbf7f),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            // Wrap with SingleChildScrollView for scrolling
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconButton(
                  icon:
                      Icon(Icons.barcode_reader, size: 70, color: Colors.white),
                  onPressed: scanBarcode,
                  tooltip: "Scan Barcode",
                ),
                SizedBox(height: 20),
                InkWell(
                  onTap: scanBarcode,
                  child: Text(
                    "Click to Scan Product",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                if (isLoading)
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                else
                  buildProductDetails(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildProductDetails() {
    String? currencySymbol = CurrencyService().currencySymbol;
    if (productDetails == null) return Container();

    return Card(
      margin: EdgeInsets.symmetric(vertical: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Product Name: ${productDetails!['description']}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Price: $currencySymbol ${productDetails!['price']}",
              style: TextStyle(fontSize: 18),
            ),
            Text(
              "Current Stock :  ${productDetails!['stock']}",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),

            // Raw Stock Section
            Text(
              "Raw Stock:",
              style: TextStyle(fontSize: 18),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (rawStock > 0)
                        rawStock--; // Decrement raw stock if greater than 0
                      rawStockController.text = rawStock.toString();
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: rawStockController, // Use existing controller
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        rawStock = int.tryParse(value) ??
                            0; // Update raw stock from input
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      rawStock++; // Increment raw stock
                      rawStockController.text = rawStock.toString();
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // Case Stock Section
            Text(
              "Case Stock:",
              style: TextStyle(fontSize: 18),
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    setState(() {
                      if (caseStock > 0)
                        caseStock--; // Decrement case stock if greater than 0
                      caseStockController.text = caseStock.toString();
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: caseStockController, // Use existing controller
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        caseStock = int.tryParse(value) ??
                            0; // Update case stock from input
                      });
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      caseStock++; // Increment case stock
                      caseStockController.text = caseStock.toString();
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: 20),

            // Row for selecting the product
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        selectProduct, // Pass rawStock and caseStock to the selectProduct method
                    icon: Icon(Icons.check, color: Colors.white),
                    label: Text(
                      "Select",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        productDetails = null; // Reset product details
                      });
                    },
                    icon: Icon(Icons.cancel, color: Colors.white),
                    label: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
