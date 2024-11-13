import 'dart:convert';

import 'package:drag_select_grid_view/drag_select_grid_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';
import 'package:provider/provider.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/currencyget.dart';
import 'package:skilltest/services/nointernet.dart';

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
  bool isLoading = false;
  late DragSelectGridViewController controller;

  @override
  void initState() {
    super.initState();
    departmentItems = widget.items.where((item) => item['fired'] == 0).toList();
    selectedItems = List<bool>.filled(departmentItems.length, false);
    controller = DragSelectGridViewController();
    controller.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    controller.removeListener(_onSelectionChanged);
    controller.dispose();
    super.dispose();
  }

  void _onSelectionChanged() {
    setState(() {
      _calculateTotalAmount();
    });
  }

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;
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
            '${widget.departmentName} - Items',
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF001a1a),
                Color(0xFF005959),
                Color(0xFF0fbf7f),
              ],
            ),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: DragSelectGridView(
                  gridController: controller,
                  itemCount: departmentItems.length,
                  itemBuilder: (context, index, selected) {
                    final item = departmentItems[index];
                    final transactionId = item['transaction_id'] ?? 'N/A';
                    final quantity = item['quantity'] ?? 0;
                    final amount =
                        (double.tryParse(item['amount'].toString()) ?? 0.0);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedItems[index] = !selectedItems[index];
                          _calculateTotalAmount();
                        });
                      },
                      child: Card(
                        elevation: 5.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(
                                  8.0), // Increased padding
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['item'] ?? 'Unknown Item',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.teal,
                                    ),
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    'Transaction ID: $transactionId\n'
                                    'Quantity: $quantity\n'
                                    'Total Amount: $currencySymbol ${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 8.0,
                              top: MediaQuery.of(context).size.height *
                                  0.05, // Center it vertically inside the card
                              child: controller.value.selectedIndexes
                                      .contains(index)
                                  ? const Icon(Icons.check_circle,
                                      color: Colors.green,
                                      size: 30) // Adjust size as needed
                                  : const Icon(Icons.circle_outlined,
                                      color: Colors.grey,
                                      size: 30), // Adjust size as needed
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio:
                        3.0, // Reduced height by changing aspect ratio
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Text(
                  'Total Amount: $currencySymbol ${totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: isLoading ? null : _confirmSelection,
                  style: ElevatedButton.styleFrom(
                    primary: const Color.fromARGB(255, 94, 197, 245),
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 20.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Confirm Selection',
                          style: TextStyle(fontSize: 16.0, color: Colors.black),
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _calculateTotalAmount() {
    totalAmount = 0.0;
    for (int i = 0; i < departmentItems.length; i++) {
      if (controller.value.selectedIndexes.contains(i)) {
        final amount =
            double.tryParse(departmentItems[i]['amount'].toString()) ?? 0.0;
        totalAmount += amount;
      }
    }
  }

  Future<void> _confirmSelection() async {
    List<Map<String, dynamic>> selectedItemsList = [];
    for (int i = 0; i < departmentItems.length; i++) {
      if (controller.value.selectedIndexes.contains(i)) {
        selectedItemsList.add(departmentItems[i]);
      }
    }

    setState(() {
      isLoading = true; // Start loading
    });

    // Make API call to update the database
    final success = await _updateDatabase(selectedItemsList);

    setState(() {
      isLoading = false; // End loading
    });

    if (success) {
      Navigator.of(context).pop(true); // Ensure we're using the correct context
      MotionToast.success(
        description: const Text("Item updated successfully."),
        position: MotionToastPosition.top,
        animationType: AnimationType.fromTop,
      ).show(context);

      // Navigate back after showing the toast
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context)
              .pop(true); // Ensure we're using the correct context
        }
      });
    } else {
      MotionToast.error(
        description: const Text("Failed to update items."),
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
      'custID': Cust_id,
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
