import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skilltest/screens/Editselectdepartment.dart';
import 'package:skilltest/screens/selectItemeditscreen.dart';
import 'package:skilltest/services/baseurl.dart';
import 'package:skilltest/services/connectivity_service.dart';
import 'package:skilltest/services/currencyget.dart';
import 'package:skilltest/services/nointernet.dart';

class DateRangeLogEditScreen extends StatefulWidget {
  const DateRangeLogEditScreen({Key? key}) : super(key: key);

  @override
  _DateRangeLogScreenState createState() => _DateRangeLogScreenState();
}

class _DateRangeLogScreenState extends State<DateRangeLogEditScreen> {
  DateTime? startDate;
  DateTime? endDate;
  List<String> userIds = [];
  String? selectedUserId;
  String? selectedTile; // State to keep track of the selected tile
  List<Map<String, dynamic>> dataList = [];
  bool isLoading = false;
  String errorMessage = '';
  List<String> dateRanges = [];
  Map<String, String> dateRangeToUserId = {};
  final FlutterSecureStorage secureStorage = FlutterSecureStorage();
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  bool isSearchExpanded = true; // New state to control expansion
  Map<String, List<Map<String, dynamic>>> departmentItemsMap = {};
  List<Map<String, dynamic>> departmentsList = [];

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
            title: Text(
              'Edit Sales',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            backgroundColor: Colors.teal,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Collapsible Search and Dropdown Section
                _buildSearchAndFilterSection(),
                // SizedBox(height: 10),
                // Expanded(
                //   child: Container(
                //     decoration: BoxDecoration(
                //       gradient: LinearGradient(
                //         colors: [
                //           Color(0xFF001a1a),
                //           Color(0xFF005959),
                //           Color(0xFF0fbf7f)
                //         ],
                //         begin: Alignment.topLeft,
                //         end: Alignment.bottomRight,
                //       ),
                //     ),
                //     child: _buildDepartmentsView(),
                //   ),
                // ),
              ],
            ),
          ));
    });
  }

  Widget _buildSearchAndFilterSection() {
    return Center(
      child: Column(
        children: [
          SizedBox(height: 60),
          TextFormField(
            controller: _startDateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Start Date',
              hintText: 'Select Start Date',
              suffixIcon: Icon(Icons.calendar_today),
              floatingLabelBehavior: FloatingLabelBehavior
                  .auto, // Makes the label float to the top
              labelStyle: TextStyle(
                color: Colors.teal, // Custom color for the label text
                fontWeight: FontWeight.bold,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                  color: Colors.teal, // Border color when field is not focused
                  width: 2.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
                borderSide: BorderSide(
                  color: Colors.blue, // Border color when field is focused
                  width: 2.5,
                ),
              ),
              filled: true,
              fillColor: Colors.grey.shade100, // Background color of the field
            ),
            onTap: () async {
              await _selectDate(context, isStartDate: true);
              if (startDate != null && endDate != null) {
                await fetchLogDetails();
              }
            },
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: _endDateController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'End Date',
              hintText: 'Select End Date',
              suffixIcon: Icon(Icons.calendar_today),
              floatingLabelBehavior: FloatingLabelBehavior.auto,
              labelStyle: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
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
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onTap: () async {
              await _selectDate(context, isStartDate: false);
              if (startDate != null && endDate != null) {
                await fetchLogDetails();
              }
            },
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Select Date Range',
              labelStyle: TextStyle(
                color: Colors.teal,
                fontWeight: FontWeight.bold,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.teal, width: 2.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.teal, width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.blueAccent, width: 2.0),
              ),
            ),
            isExpanded: true,
            hint: Text(
              'Select Date Range',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: selectedUserId,
            items: isLoading
                ? [
                    DropdownMenuItem(
                      child: Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 10),
                          Text(
                            'Loading...',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ]
                : (dateRanges.isNotEmpty
                    ? [
                        DropdownMenuItem(
                          value: 'All',
                          child: Text(
                            'All',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ...dateRanges.map((String dateRange) {
                          return DropdownMenuItem<String>(
                            value: dateRange,
                            child: Column(
                              children: [
                                Text(
                                  dateRange,
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Divider(
                                  // Add divider after each item
                                  color: Colors.grey,
                                  thickness: 1.0,
                                  height: 10,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ]
                    : [
                        DropdownMenuItem(
                          child: Text(
                            'No Data Available',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      ]),
            onChanged: (value) {
              setState(() {
                if (value != null && value != 'No Data Available') {
                  selectedUserId = value;
                }
              });
            },
            icon: Icon(
              Icons.arrow_drop_down_circle,
              color: Colors.teal,
            ),
            dropdownColor: Colors.white,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            isDense: false,
          ),

          SizedBox(height: 20),
          // Find button to navigate to FilterDetailsPage
          SizedBox(
            width: 150,
            child: ElevatedButton(
              onPressed: () {
                if (selectedUserId != null) {
                  if (selectedUserId == 'All') {
                    // Pass a special value to indicate all user IDs
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DepartmentsEditScreen(
                            filterValue: 'All',
                            dateRangeToUserId: dateRangeToUserId),
                      ),
                    );
                  } else {
                    final userId = dateRangeToUserId[selectedUserId];
                    if (userId != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DepartmentsEditScreen(
                              filterValue: userId,
                              dateRangeToUserId: dateRangeToUserId),
                        ),
                      );
                    }
                  }
                } else {
                  setState(() {
                    errorMessage = 'Please select a date range first.';
                  });
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                padding: MaterialStateProperty.all<EdgeInsets>(
                    EdgeInsets.symmetric(vertical: 15)),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                textStyle: MaterialStateProperty.all<TextStyle>(
                  TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              child: Text('Find',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
          if (errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  void _navigateToTransactionScreen(
      int departmentId, String departmentName, department) {
    print(userIds);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionItemsScreen(
          departmentId: departmentId,
          departmentName: departmentName,
          items: departmentItemsMap[departmentId.toString()] ?? [],
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh or update data
        // fetchTransactions(
        //     selectedUserId ?? 'All'); // Or however you fetch the data
      }
    });
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isStartDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
          _startDateController.text = picked.toString().split(' ')[0];
        } else {
          endDate = picked;
          _endDateController.text = picked.toString().split(' ')[0];
        }
        isSearchExpanded = false; // Collapse on date selection
      });
    }
  }

  String formatDateTimeWithoutMilliseconds(String dateTime) {
    DateTime parsedDateTime = DateTime.parse(dateTime).toLocal();
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(parsedDateTime);
  }

  Future<void> fetchLogDetails() async {
    if (startDate == null || endDate == null) {
      setState(() {
        errorMessage = 'Please select both start and end dates.';
      });
      return;
    }

    String? custId = await secureStorage.read(key: 'id');
    if (custId == null) {
      setState(() {
        errorMessage = 'Customer ID not found.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      dateRanges.clear();
      dateRangeToUserId.clear();
      dataList.clear(); // Reset the data list when fetching new logs
      selectedUserId = null; // Reset dropdown selection for new search
      selectedTile = null; // Reset any tile selection
    });

    try {
      final response = await http.get(
        Uri.parse(baseURL +
            'filterLogs/$custId/${startDate!.toIso8601String()}/${endDate!.toIso8601String()}'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(data);
        // Filter data where Status == 1
        // Filter logs where Status == 0 (inactive logs)
        final List<dynamic> filteredData = data
            .where((item) => item['Status'] == 0 || item['Status'] == '0')
            .toList();

        // Update state with the formatted log details
        setState(() {
          dateRangeToUserId = {
            for (var log in filteredData)
              '${formatDateTimeWithoutMilliseconds(log['ShiftStarted'])} - '
                  '${log['ShiftEnd'] != null ? formatDateTimeWithoutMilliseconds(log['ShiftEnd']) : 'Ongoing'}  '
                  '\nUser: ${log['Userid'].toString()}': log['LogId'].toString()
          };

          // Get the list of date ranges for UI display
          dateRanges = dateRangeToUserId.keys.toList();

          // Mark loading as complete
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load logs');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
    }
  }
}
