import 'dart:convert'; // For jsonDecode

import 'package:flutter/material.dart';
import 'package:skilltest/services/currencyget.dart';

class RecordTypeDetailsPage extends StatelessWidget {
  final String recordType;
  final List<Map<String, dynamic>> records;

  const RecordTypeDetailsPage({
    Key? key,
    required this.recordType,
    required this.records,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String? currencySymbol = CurrencyService().currencySymbol;
    // Filter records by recordType
    final filteredRecords =
        records.where((record) => record['Rec_Type'] == recordType).toList();

    // Group records by Rec_Id
    final groupedRecords = <String, List<Map<String, dynamic>>>{};
    for (var record in filteredRecords) {
      final recId = record['Rec_Id'].toString();
      if (!groupedRecords.containsKey(recId)) {
        groupedRecords[recId] = [];
      }
      groupedRecords[recId]!.add(record);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Details for $recordType',
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
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: groupedRecords.entries.map((entry) {
            final recId = entry.key;
            final recordsForId = entry.value;

            // Extract and flatten items from records
            final List<Map<String, dynamic>> items =
                recordsForId.expand((record) {
              final recItem = record['Rec_Item'];

              // Check if recItem is a String and parse if necessary
              List<dynamic> itemList;
              if (recItem is String) {
                try {
                  itemList = jsonDecode(recItem);
                } catch (e) {
                  itemList = [];
                }
              } else if (recItem is List<dynamic>) {
                itemList = recItem;
              } else {
                itemList = [];
              }

              return itemList.map((item) => item as Map<String, dynamic>);
            }).toList();
            // Get reason for the record
            final reason = recordsForId.isNotEmpty
                ? recordsForId.first['Record'] ?? 'N/A'
                : 'N/A';
            final date = recordsForId.isNotEmpty
                ? recordsForId.first['Rec_Date'] ?? 'N/A'
                : 'N/A';
            final userId = recordsForId.isNotEmpty
                ? recordsForId.first['Userid'] ?? 'N/A'
                : 'N/A';

            // Debugging print to check the content of recordsForId
            print('Records for RecId $recId: ${recordsForId.first}');

// Log the userId for debugging
            print('UserId for RecId $recId: $userId');
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display reason as heading
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Align text to the left
                    children: [
                      // First line: Record ID
                      Row(
                        children: [
                          Text(
                            'Record ID: $recId',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                              width:
                                  40), // Spacing between Record Date and User ID
                          Text(
                            'User ID: $userId',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4), // Add spacing between lines

                      // Second line: Record Date and User ID in a Row
                      Text(
                        'Record Date: $date',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4), // Add spacing between lines
                      // Third line: Reason
                      Text(
                        'Reason: $reason',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Display item details
                ...items.map((item) {
                  return Card(
                    elevation: 5,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: Icon(
                        Icons.shopping_cart, // Use an appropriate icon
                        color: Colors.blueAccent,
                        size: 40,
                      ),
                      title: Text(
                        item['item_name'] ?? 'Unknown Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Quantity: ${item['quantity'] ?? 0}, '
                        '\nAmount: $currencySymbol ${item['amount'] ?? 0.0}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                      // trailing: Icon(
                      //   Icons.arrow_forward_ios,
                      //   color: Colors.blueAccent,
                      // ),
                      // onTap: () {
                      //   // Handle tile tap if needed
                      // },
                    ),
                  );
                }).toList(),
                SizedBox(height: 20), // Space between different record groups
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
