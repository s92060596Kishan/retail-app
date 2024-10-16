import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/currencyget.dart';

class EditQuantityPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const EditQuantityPage({Key? key, required this.item}) : super(key: key);

  @override
  _EditQuantityPageState createState() => _EditQuantityPageState();
}

class _EditQuantityPageState extends State<EditQuantityPage> {
  late TextEditingController _quantityController;
  double _newAmount = 0.0;
  bool _isLoading = false; // State to show loading indicator

  @override
  void initState() {
    super.initState();
    _quantityController =
        TextEditingController(text: widget.item['quantity'].toString());
    _calculateNewAmount(); // Calculate initial amount
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateNewAmount() {
    setState(() {
      _newAmount = (double.tryParse(widget.item['price'].toString()) ?? 0) *
          (int.tryParse(_quantityController.text) ?? 0);
    });
  }

  Future<void> _saveChanges() async {
    // Set loading state
    setState(() {
      _isLoading = true;
    });

    // Prepare data to be sent to the backend
    final updatedData = {
      'id': widget.item['id'], // Ensure 'id' is included
      'cust_id': widget.item['cust_id'],
      'transaction_itemsId': widget.item['transaction_itemsId'],
      'quantity': int.tryParse(_quantityController.text) ?? 0,
      'amount': _newAmount,
    };

    // Make an API call to save changes
    try {
      final response = await http.post(
        Uri.parse(baseURL + 'updateQuantity'), // Replace with your API URL
        headers: headers,
        body: jsonEncode(updatedData),
      );
      print(response.body);
      if (response.statusCode == 200) {
        // Success response handling
        Navigator.pop(
            context, updatedData); // Return updated data to the previous screen
      } else {
        // Error response handling
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes. Please try again.')),
        );
      }
    } catch (e) {
      // Exception handling
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    } finally {
      // Reset loading state
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Quantity',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display item details in a Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.production_quantity_limits,
                              color: Colors.teal),
                          SizedBox(width: 8),
                          Text(
                            'Product: ${widget.item['item']}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Divider(),
                      Text(
                        'Price: \ $currencySymbol ${widget.item['price'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                      Text(
                        'VAT: \ ${widget.item['vat'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                      Text(
                        'Promo: ${widget.item['promo']}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                      Text(
                        'Promo Value: \$${widget.item['promo_val'].toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Quantity input field
              Text(
                'Edit Quantity',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.edit, color: Colors.teal),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: (value) {
                    _calculateNewAmount(); // Recalculate total when quantity changes
                  },
                ),
              ),
              SizedBox(height: 30),

              // Display calculated total amount dynamically
              Card(
                color: Colors.teal.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\ $currencySymbol ${_newAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.teal,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),

              // Save changes button
              Center(
                child: _isLoading
                    ? CircularProgressIndicator() // Show loading indicator while saving
                    : ElevatedButton.icon(
                        onPressed: _saveChanges,
                        icon: Icon(Icons.save),
                        label: Text('Save'),
                        style: ElevatedButton.styleFrom(
                          primary: Colors.teal,
                          padding: EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          textStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
