import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skilltest/screens/recorddetailspage.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/nointernet.dart';

class PosrecordsPage extends StatefulWidget {
  final List<Map<String, dynamic>> records;

  const PosrecordsPage({Key? key, required this.records}) : super(key: key);

  @override
  _PosrecordsPageState createState() => _PosrecordsPageState();
}

class _PosrecordsPageState extends State<PosrecordsPage> {
  String? selectedRecordType;
  List<String> recordTypes = []; // List to store unique record types

  @override
  void initState() {
    super.initState();
    // Extract unique record types from records, ensuring no null values
    recordTypes = widget.records
        .map((record) => record['Rec_Type'] as String?)
        .where((type) => type != null)
        .cast<String>() // Cast to non-nullable String
        .toSet()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredRecords = selectedRecordType == null
        ? widget.records
        : widget.records
            .where((record) => record['Rec_Type'] == selectedRecordType)
            .toList();
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
            title: Text(
              'POS Records',
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
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                // Animated Tiles for each record type with space between them
                ...recordTypes.map((type) {
                  return Column(
                    children: [
                      AnimatedTile(
                        title: type,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RecordTypeDetailsPage(
                                recordType: type,
                                records: widget.records,
                              ),
                            ),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios,
                            color: Colors.white, size: 30), // Add trailing
                        amount:
                            '${widget.records.where((record) => record['Rec_Type'] == type).length} Items',
                      ),
                      SizedBox(height: 16), // Space between tiles
                    ],
                  );
                }).toList(),

                // Display filtered records
                if (selectedRecordType != null) SizedBox(height: 20),
                if (selectedRecordType != null)
                  ...filteredRecords.map((record) {
                    return ListTile(
                      title: Text(record['Rec_Item'] ?? 'Unknown Item'),
                      subtitle:
                          Text('Record Type: ${record['Rec_Type'] ?? 'N/A'}'),
                      // Add other details as needed
                    );
                  }).toList(),
              ],
            ),
          ));
    });
  }
}

class AnimatedTile extends StatefulWidget {
  final String title;
  final VoidCallback onTap;
  final String amount;
  final Widget? trailing;
  const AnimatedTile({
    required this.title,
    required this.onTap,
    required this.amount,
    this.trailing,
  });

  @override
  _AnimatedTileState createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<AnimatedTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _isHovered ? Colors.blueAccent : Colors.blue,
            Color.fromARGB(221, 22, 0, 40)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 7,
                  offset: Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: widget.onTap,
        onHover: (value) {
          setState(() {
            _isHovered = value;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.category, // Use appropriate icon
                color: Colors.white,
                size: 40,
              ),
              SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Items: ${widget.amount}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 18.0),
                  child: widget.trailing!,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
