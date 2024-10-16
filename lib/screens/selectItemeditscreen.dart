import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/currencyget.dart'; // For JSON encoding

class TransactionItemsScreen extends StatefulWidget {
  final int departmentId;
  final String departmentName;
  final List<Map<String, dynamic>> items;

  const TransactionItemsScreen({
    Key? key,
    required this.departmentId,
    required this.departmentName,
    required this.items,
  }) : super(key: key);

  @override
  _TransactionItemsScreenState createState() => _TransactionItemsScreenState();
}

class _TransactionItemsScreenState extends State<TransactionItemsScreen> {
  List<bool> selectedItems = [];
  double totalAmount = 0.0;
  List<Map<String, dynamic>> departmentItems = [];
  bool isLoading = false; // Add this variable to track loading state

  @override
  void initState() {
    super.initState();
    departmentItems = widget.items;
    departmentItems =
        departmentItems.where((item) => item['fired'] == 1).toList();
    selectedItems = List<bool>.filled(departmentItems.length, false);
  }

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        title: Text(
          '${widget.departmentName} - Items',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        // backgroundColor: Colors.teal, // Customize color
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF001a1a), // Start color
              Color(0xFF005959), // Middle color
              Color(0xFF0fbf7f), // End color
            ],
          ),
        ),
        padding: const EdgeInsets.all(16.0), // Add padding around the body
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: departmentItems.length,
                itemBuilder: (context, index) {
                  final item = departmentItems[index];
                  final transactionId = item['transaction_id'] ?? 'N/A';
                  final quantity = item['quantity'] ?? 0;
                  final amount =
                      (double.tryParse(item['amount'].toString()) ?? 0.0);

                  return Card(
                    elevation: 5.0, // Add shadow effect
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0), // Space between cards
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12.0), // Rounded corners
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        item['item'] ?? 'Unknown Item',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal, // Customize text color
                        ),
                      ),
                      subtitle: Text(
                        'Transaction ID: $transactionId\n'
                        'Quantity: $quantity\n'
                        'Total Amount: \ $currencySymbol ${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[700], // Customize text color
                        ),
                      ),
                      value: selectedItems[index],
                      onChanged: (bool? value) {
                        setState(() {
                          selectedItems[index] = value ?? false;
                          _calculateTotalAmount();
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Total Amount: \ $currencySymbol ${totalAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Customize text color
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : _confirmSelection, // Disable button while loading
                style: ElevatedButton.styleFrom(
                  primary: Color.fromARGB(
                      255, 94, 197, 245), // Customize button color
                  padding: EdgeInsets.symmetric(
                      vertical: 12.0, horizontal: 20.0), // Customize padding
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(10.0), // Rounded corners
                  ),
                ),
                child: isLoading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white), // Loading indicator color
                      )
                    : const Text(
                        'Confirm Selection',
                        style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.black), // Customize text size
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _calculateTotalAmount() {
    totalAmount = 0.0;
    for (int i = 0; i < departmentItems.length; i++) {
      if (selectedItems[i]) {
        final amount =
            double.tryParse(departmentItems[i]['amount'].toString()) ?? 0.0;
        totalAmount += amount;
      }
    }
  }

  Future<void> _confirmSelection() async {
    List<Map<String, dynamic>> selectedItemsList = [];
    for (int i = 0; i < departmentItems.length; i++) {
      if (selectedItems[i]) {
        selectedItemsList.add(departmentItems[i]);
      }
    }

    // Debug print for confirmation
    print('Selected Items: $selectedItemsList');

    setState(() {
      isLoading = true; // Start loading
    });

    // Make API call to update the database
    final success = await _updateDatabase(selectedItemsList);

    setState(() {
      isLoading = false; // End loading
    });

    if (success) {
      // Show a success message or navigate to another screen
      MotionToast.success(
        //title: Text("Delete Successfully"),
        description: Text("Item updated successfully."),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);
    } else {
      // Handle failure case
      MotionToast.error(
        //title: Text("Delete Successfully"),
        description: Text("Updated item Unsuccessfully."),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);
    }
  }

  Future<bool> _updateDatabase(
      List<Map<String, dynamic>> selectedItemsList) async {
    final url = baseURL + 'updateitems'; // Replace with your API endpoint
    final FlutterSecureStorage secureStorage = FlutterSecureStorage();
    String? Cust_id = await secureStorage.read(key: 'id');
    final body = jsonEncode({
      'departmentId': widget.departmentId,
      'items': selectedItemsList,
      'totalAmount': totalAmount,
      'custID': Cust_id
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        return true; // Successfully updated
      } else {
        print(response.body);
        return false; // Failed to update
      }
    } catch (e) {
      print('Error updating database: $e');
      return false;
    }
  }
}
