import 'dart:convert';

import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';
import 'package:provider/provider.dart';
import 'package:search_choices/search_choices.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/nointernet.dart';

class Department {
  final int id;
  final String name;

  Department({
    required this.id,
    required this.name,
  });

  @override
  String toString() {
    return name;
  }
}

class VAT {
  final int id;
  final String vatValue;

  VAT({required this.id, required this.vatValue});

  @override
  String toString() {
    return vatValue;
  }
}

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController vatController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  Department? selectedDepartment;
  List<Department> departments = [];
  VAT? selectedVat;
  List<VAT> vats = [];
  bool isLoading = false; // Loading state variable
  bool isLoadingDepartments = true; // Loading state for departments
  bool isLoadingVats = true; // Loading state for VATs

  @override
  void initState() {
    super.initState();
    fetchDepartments(); // Fetch departments when the widget is created
    fetchVats();
  }

  Future<void> fetchDepartments() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? custId = await secureStorage.read(key: 'id');

    final response = await http.get(
      Uri.parse(baseURL + 'getdepartments/$custId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        departments = jsonResponse
            .map<Department>((dept) =>
                Department(id: dept['departments_id'], name: dept['name']))
            .toList();
        isLoadingDepartments = false;
      });
    } else {
      throw Exception('Failed to load departments');
    }
  }

  Future<void> fetchVats() async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? custId = await secureStorage.read(key: 'id');

    final response = await http.get(
      Uri.parse(baseURL + 'getvats/$custId'), // Adjust the endpoint as needed
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      setState(() {
        vats = jsonResponse
            .map<VAT>((vat) => VAT(id: vat['vatId'], vatValue: vat['vat']))
            .toList();
        isLoadingVats = false;
      });
    } else {
      throw Exception('Failed to load VATs');
    }
  }

  Future<void> scanBarcode() async {
    var result = await BarcodeScanner.scan();
    setState(() {
      barcodeController.text = result.rawContent;
    });
    fetchProductDetails(barcodeController.text);
  }

// Fetch product details by barcode
  Future<void> fetchProductDetails(String barcode) async {
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? custId = await secureStorage.read(key: 'id');
    // Create the JSON body
    final body = jsonEncode({
      'barcode': barcode,
      'cust_id': custId,
    });
    print(custId);
    final response = await http.post(Uri.parse(CrmURL + 'productFind'),
        headers: headers, body: body);

    if (response.statusCode == 200) {
      Map<String, dynamic> productData = json.decode(response.body);
      showProductDialog(productData);
    }
  }

  // Show dialog for product options (auto-fill or manual)
  void showProductDialog(Map<String, dynamic> productData) {
    print("Showing product dialog"); // Debugging
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Product Found"),
          content: Text(
              "Do you want to auto-fill the product details or manually edit?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Auto-fill the product details
                setState(() {
                  barcodeController.text = productData['barcode'].toString();
                  descriptionController.text = productData['description'];
                  priceController.text = productData['price'].toString();
                });
                Navigator.pop(context);
              },
              child: Text("Auto-fill"),
            ),
            TextButton(
              onPressed: () {
                // Keep barcode but allow manual input for other fields
                Navigator.pop(context);
              },
              child: Text("Manual"),
            ),
          ],
        );
      },
    );
  }

  Future<void> addProduct() async {
    setState(() {
      isLoading = true; // Set loading to true
    });

    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? custId = await secureStorage.read(key: 'id');

    final productData = {
      'description': descriptionController.text,
      'barcode': barcodeController.text,
      'price': priceController.text,
      'departmentId': selectedDepartment?.id,
      'vat': selectedVat?.vatValue,
      'stock': stockController.text
    };

    final response = await http.post(
      Uri.parse(baseURL + 'addProduct/$custId'),
      headers: headers,
      body: json.encode(productData),
    );

    setState(() {
      isLoading = false; // Reset loading state after response
    });

    if (response.statusCode == 201) {
      MotionToast.success(
        description: Text("Product Added successfully."),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);

      // Clear the form fields
      descriptionController.clear();
      barcodeController.clear();
      priceController.clear();
      vatController.clear();
      stockController.clear();
      setState(() {
        selectedDepartment = null; // Clear the selected department
      });

      Navigator.pop(context);
    } else {
      print(response.statusCode);
      MotionToast.error(
        description: Text("Failed to add Product.Barcode already exist"),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);
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

      return Scaffold(
        appBar: AppBar(
          //
          backgroundColor: Colors.teal,
          title: Text(
            'Add Product',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          centerTitle: true,

          elevation: 4,
          shadowColor: Colors.grey.withOpacity(0.3),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
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
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildTextField('Product Description', descriptionController,
                    TextInputType.text),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: buildTextField('Barcode', barcodeController,
                          TextInputType.number, true),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 25.0),
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt_outlined,
                          color: Color.fromARGB(255, 35, 139, 230),
                        ),
                        onPressed: scanBarcode,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                buildTextField('Price', priceController, TextInputType.number),
                SizedBox(height: 16),
                Text('Department',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 80),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child:
                      isLoadingDepartments // Check loading state for departments
                          ? Center(child: CircularProgressIndicator())
                          : SearchChoices.single(
                              items: departments
                                  .map((dept) => DropdownMenuItem<Department>(
                                        value: dept,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
                                                blurRadius: 5,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            dept.name,
                                            style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              value: selectedDepartment,
                              hint: Text(
                                "Select a Department",
                                style: TextStyle(color: Colors.white),
                              ),
                              searchHint: "Select Department",
                              onChanged: (value) {
                                setState(() {
                                  selectedDepartment = value as Department?;
                                });
                              },
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Colors.white),
                              clearIcon: Icon(Icons.clear, color: Colors.white),
                              style: TextStyle(color: Colors.white),
                              searchFn: (String keyword,
                                  List<DropdownMenuItem<Department>> items) {
                                List<int> filteredIndexes = [];
                                for (int i = 0; i < items.length; i++) {
                                  if (items[i]
                                      .value!
                                      .name
                                      .toLowerCase()
                                      .contains(keyword.toLowerCase())) {
                                    filteredIndexes.add(i);
                                  }
                                }
                                return filteredIndexes;
                              },
                            ),
                ),
                SizedBox(height: 16),
                Text('VAT',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white)),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 80),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blueAccent),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: isLoadingVats // Check loading state for departments
                      ? Center(child: CircularProgressIndicator())
                      : SearchChoices.single(
                          items: vats
                              .map((vat) => DropdownMenuItem<VAT>(
                                    value: vat,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.2),
                                            blurRadius: 5,
                                            offset: Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        vat.vatValue,
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ))
                              .toList(),
                          value: selectedVat,
                          hint: Text(
                            "Select VAT",
                            style: TextStyle(color: Colors.white),
                          ),
                          searchHint: "Select VAT",
                          onChanged: (value) {
                            setState(() {
                              selectedVat = value as VAT?;
                            });
                          },
                          isExpanded: true,
                          icon:
                              Icon(Icons.arrow_drop_down, color: Colors.white),
                          clearIcon: Icon(Icons.clear, color: Colors.white),
                          style: TextStyle(color: Colors.white),
                          searchFn: (String keyword,
                              List<DropdownMenuItem<VAT>> items) {
                            List<int> filteredIndexes = [];
                            for (int i = 0; i < items.length; i++) {
                              if (items[i]
                                  .value!
                                  .vatValue
                                  .toLowerCase()
                                  .contains(keyword.toLowerCase())) {
                                filteredIndexes.add(i);
                              }
                            }
                            return filteredIndexes;
                          },
                        ),
                ),
                buildTextField(
                    'Initial Stock', stockController, TextInputType.number),
                SizedBox(height: 30),
                isLoading // Show loading state
                    ? Center(
                        child: CircularProgressIndicator()) // Loading indicator
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: addProduct,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 8,
                          ),
                          child: Text(
                            'Add Product',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget buildTextField(String labelText, TextEditingController controller,
      TextInputType inputType,
      [bool readOnly = false]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            readOnly: readOnly,
            decoration: InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(vertical: 15, horizontal: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blueAccent),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blueAccent, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
