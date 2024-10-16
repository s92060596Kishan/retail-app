import 'dart:convert';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/currencyget.dart';

class Product {
  final int id;
  final String price;
  final String barcode;
  final String description;
  final String imgPath;
  final String vat;
  final String pluCode;
  final String departmentName;
  final int ageRefusal;
  final int stock;

  Product({
    required this.id,
    required this.price,
    required this.barcode,
    required this.description,
    required this.imgPath,
    required this.vat,
    required this.pluCode,
    required this.departmentName,
    required this.ageRefusal,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      price: json['price'] ?? '',
      barcode: json['barcode'] ?? '',
      description: json['description'] ?? '',
      imgPath: json['imagePath'] ?? '',
      vat: json['vat'] ?? '',
      pluCode: json['pluCode'] ?? '',
      departmentName: json['departmentName'] ?? '',
      ageRefusal: json['ageRefusal'] ?? 0,
      stock: json['stock'] ?? 0,
    );
  }
}

class ProductsScreen extends StatefulWidget {
  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  List<Product> allProducts = [];
  List<Product> searchResults = [];
  Product? selectedProduct;
  final FocusNode _searchFocusNode = FocusNode();
  bool isLoading = true; // Add a loading state
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  Future<void> fetchProducts() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? custId = await secureStorage.read(key: 'id');
    final String apiUrl = baseURL + 'getproduct/$custId';

    try {
      final response = await http.get(Uri.parse(apiUrl), headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> productData = jsonDecode(response.body);
        setState(() {
          allProducts =
              productData.map((data) => Product.fromJson(data)).toList();
          isLoading = false; // Set loading to false after fetching
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false; // Set loading to false in case of error
      });
    }
  }

  void updateSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        selectedProduct = null;
      });
      return;
    }

    final results = allProducts
        .where((product) =>
            product.description.toLowerCase().contains(query.toLowerCase()) ||
            product.barcode.toLowerCase().contains(query.toLowerCase()))
        .toList();

    setState(() {
      searchResults = results;
      selectedProduct = null;
    });
  }

  Future<void> scanBarcode() async {
    try {
      var scanResult = await BarcodeScanner.scan();
      String scannedBarcode = scanResult.rawContent;

      if (scannedBarcode.isNotEmpty) {
        final product = allProducts.firstWhere(
          (p) => p.barcode == scannedBarcode,
          orElse: () => Product(
              id: 0, // id set to 0 for non-existent products
              price: '',
              barcode: '',
              description: '',
              imgPath: '',
              vat: '',
              pluCode: '',
              departmentName: '',
              ageRefusal: 0,
              stock: 0),
        );
        setState(() {
          selectedProduct = product;
        });
      }
    } catch (e) {
      print('Error during barcode scanning: $e');
    }
  }

  void selectProduct(Product product) {
    FocusScope.of(context).unfocus();
    setState(() {
      selectedProduct = product;
      _searchController.text = product.description; // Add this line
    });
  }

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          'Products',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        ),
      ),
      body: Container(
        color: Color.fromARGB(255, 171, 206, 189),
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextField(
                controller: _searchController, // Update this line
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  labelText: 'Search Products',
                  hintText: 'Enter product name',
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  labelStyle: TextStyle(
                    color: Colors.teal,
                    fontWeight: FontWeight.bold,
                  ),
                  suffixIcon: Icon(Icons.search, color: Colors.teal),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.teal,
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(
                      color: Colors.blue,
                      width: 2.5,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14.0,
                    horizontal: 16.0,
                  ),
                ),
                style: TextStyle(color: Colors.black, fontSize: 18),
                cursorColor: Colors.blue,
                onChanged: updateSearchResults,
                onTap: () {
                  setState(() {
                    selectedProduct = null;
                  });
                },
              ),
            ),
            if (!_searchFocusNode.hasFocus)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.black,
                      thickness: 1,
                      indent: 20,
                      endIndent: 10,
                    ),
                  ),
                  Text(
                    'or',
                    style: TextStyle(color: Colors.black, fontSize: 16),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.black,
                      thickness: 1,
                      indent: 10,
                      endIndent: 20,
                    ),
                  ),
                ],
              ),
            if (!_searchFocusNode.hasFocus)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: scanBarcode,
                  icon: Icon(
                    Icons.qr_code_scanner,
                    size: 28,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Scan Product',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(
                        255, 51, 122, 53), // Use a custom color (e.g., green)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: isLoading // Check if loading
                  ? Center(
                      child:
                          CircularProgressIndicator()) // Show loading indicator
                  : selectedProduct == null
                      ? searchResults.isEmpty
                          ? Center(
                              child: Text(
                                  'Please search for products to display',
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16)))
                          : ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final product = searchResults[index];
                                return Card(
                                  elevation: 6,
                                  margin: EdgeInsets.symmetric(
                                      vertical: 6, horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      product.description,
                                      style: TextStyle(
                                          color: Colors.teal,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      '\ $currencySymbol ${product.price}',
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14),
                                    ),
                                    trailing: Icon(Icons.arrow_forward,
                                        color: Colors.teal),
                                    onTap: () {
                                      selectProduct(product);
                                    },
                                  ),
                                );
                              },
                            )
                      : ProductDetails(
                          product: selectedProduct!,
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductDetails extends StatelessWidget {
  final Product product;

  ProductDetails({required this.product});

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;
    return Center(
      child: SizedBox(
        height: 520,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: Card(
            elevation: 16,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            color: Color(0xFF80CBC4),
            child: product.id == 0
                ? Center(
                    child: Text(
                      'No product found',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (product.imgPath.isNotEmpty)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                offset: Offset(0, 6),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15.0),
                            child: Image.network(
                              product.imgPath,
                              height: 160,
                              width: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      SizedBox(height: 20),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 10),
                      Divider(
                          color: Color.fromARGB(153, 53, 52, 52),
                          thickness: 0.8),
                      SizedBox(height: 10),
                      _buildProductInfoRow('Barcode', product.barcode),
                      _buildProductInfoRow('PLU Code', product.pluCode),
                      _buildProductInfoRow(
                          'Price', ' $currencySymbol ${product.price}'),
                      _buildProductInfoRow('Stock', '${product.stock}'),
                      _buildProductInfoRow('VAT', product.vat),
                      _buildProductInfoRow(
                          'Department', product.departmentName),
                      _buildProductInfoRow(
                          'Age Restriction',
                          product.ageRefusal == 0
                              ? 'NO'
                              : '${product.ageRefusal}'),
                      SizedBox(height: 10),
                      Divider(
                          color: const Color.fromARGB(153, 53, 52, 52),
                          thickness: 0.8),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // Helper function to create a product info row with label and value
  Widget _buildProductInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
