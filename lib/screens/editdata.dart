// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:motion_toast/motion_toast.dart';
// import 'package:skilltest/screens/addrecord.dart';
// import 'package:skilltest/services/baseurl.dart';

// class EditRecordScreen extends StatefulWidget {
//   @override
//   _EditRecordScreenState createState() => _EditRecordScreenState();
// }

// class _EditRecordScreenState extends State<EditRecordScreen> {
//   List<Map<String, dynamic>> records = [];
//   bool isLoading = true;

//   Future<bool> updateRecord(
//     int id,
//     String cust_id,
//     String title,
//     double sales,
//     double cost,
//     double profit,
//   ) async {
//     // Make the API call to update the record with the provided data
//     print(cust_id);
//     try {
//       // Make the HTTP PUT request to update the record
//       var response = await http.put(
//         Uri.parse(
//             baseURL + 'update'), // Assuming your API endpoint is '/update/:id'
//         headers: headers,
//         body: jsonEncode({
//           'id': id,
//           'cust_id': cust_id,
//           'title': title,
//           'sales': sales.toString(),
//           'cost': cost.toString(),
//           'profit': profit.toString(),
//         }),
//       );
//       print('Response body: ${response.body}');
//       print('Response status code: ${response.statusCode}');
//       // Check if the request was successful (status code 200)
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // Record updated successfully
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   const SnackBar(
//         //     content: Text('Update Data Successfully'),
//         //     backgroundColor: Colors.green,
//         //   ),
//         // );
//         MotionToast.success(
//           description: Text("Update Data Successfully"),
//           //title: Text("Update Data Successfully"),
//           position: MotionToastPosition.top,
//           animationType: AnimationType.fromTop,
//         ).show(context);
//         return true;
//       } else {
//         // Failed to update the record
//         MotionToast.error(
//           position: MotionToastPosition.top,
//           //title: Text("Update Data Successfully"),
//           description: Text("Update Data Unsuccessfully"),
//           animationType: AnimationType.fromTop,
//         ).show(context);
//         return false;
//       }
//     } catch (error) {
//       // Error occurred while making the request
//       print('Error updating record: $error');
//       return false;
//     }
//   }

//   // Fetch data from API
//   Future<void> fetchData() async {
//     final FlutterSecureStorage secureStorage = FlutterSecureStorage();
//     String? userId = await secureStorage.read(key: 'id');
//     var response = await http.get(
//       Uri.parse(baseURL + 'get/$userId'),
//       headers: headers,
//     );
//     print(response.statusCode);
//     print(response.body);

//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body) as List<dynamic>;

//       double totalSales = 0;
//       double profit = 0;
//       double cost = 0;

//       List<Map<String, dynamic>> dataList = [];

//       data.forEach((item) {
//         totalSales += double.tryParse(item['sales']) ?? 0;
//         profit += double.tryParse(item['profit']) ?? 0;
//         cost += double.tryParse(item['cost']) ?? 0;

//         dataList.add({
//           'id': item['id'],
//           'cust_id': item['cust_id'],
//           'title': item['title'],
//           'sales': double.tryParse(item['sales']) ?? 0,
//           'cost': double.tryParse(item['cost']) ?? 0,
//           'profit': double.tryParse(item['profit']) ?? 0,
//           'created_at': item['timestamp'],
//         });
//       });

//       setState(() {
//         records = dataList;
//         isLoading = false;
//       });
//     } else {
//       setState(() {
//         isLoading = false; // Stop loading on error
//       });
//       throw Exception('Failed to load data');
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     fetchData(); // Fetch data when screen initializes
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Edit Records'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.add),
//             onPressed: () {
//               // Handle adding new records here
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) =>
//                       AddRecordScreen(), // Replace with your screen
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: isLoading
//           ? Center(child: CircularProgressIndicator()) // Show loading indicator
//           : SingleChildScrollView(
//               // Wrap the DataTable with SingleChildScrollView
//               scrollDirection: Axis.horizontal,
//               child: DataTable(
//                 headingRowColor: MaterialStateColor.resolveWith(
//                     (states) => Colors.blueGrey), // Color for heading row
//                 columns: [
//                   DataColumn(
//                       label: Text('Title',
//                           style: TextStyle(fontWeight: FontWeight.bold))),
//                   DataColumn(
//                       label: Text('Sales',
//                           style: TextStyle(fontWeight: FontWeight.bold))),
//                   DataColumn(
//                       label: Text('Cost',
//                           style: TextStyle(fontWeight: FontWeight.bold))),
//                   DataColumn(
//                       label: Text('Profit',
//                           style: TextStyle(fontWeight: FontWeight.bold))),
//                   DataColumn(
//                       label: Text('Created Date',
//                           style: TextStyle(fontWeight: FontWeight.bold))),
//                   DataColumn(
//                       label: Text('Edit',
//                           style: TextStyle(fontWeight: FontWeight.bold))),
//                   DataColumn(
//                       label: Text('Delete',
//                           style: TextStyle(fontWeight: FontWeight.bold))),
//                 ],
//                 rows: List.generate(records.length, (index) {
//                   // Alternate row colors
//                   Color color = index % 2 == 0
//                       ? const Color.fromARGB(255, 143, 143, 143)
//                       : const Color.fromARGB(255, 255, 217, 217);
//                   return DataRow(
//                     color: MaterialStateColor.resolveWith((states) => color),
//                     cells: [
//                       DataCell(TextField(
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.all(8.0),
//                           fillColor: color,
//                         ),
//                         style: TextStyle(
//                           fontSize: 14.0,
//                         ),
//                         controller: TextEditingController(
//                             text: records[index]['title']),
//                         onChanged: (value) => records[index]['title'] = value,
//                       )),
//                       DataCell(TextField(
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.all(8.0),
//                           fillColor: color,
//                         ),
//                         style: TextStyle(fontSize: 14.0),
//                         controller: TextEditingController(
//                             text: records[index]['sales'].toStringAsFixed(
//                                 2)), // Format to two decimal places
//                         onChanged: (value) =>
//                             records[index]['sales'] = double.parse(value),
//                       )),
//                       DataCell(TextField(
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.all(8.0),
//                           fillColor: color,
//                         ),
//                         style: TextStyle(fontSize: 14.0),
//                         controller: TextEditingController(
//                             text: records[index]['cost'].toStringAsFixed(
//                                 2)), // Format to two decimal places
//                         onChanged: (value) =>
//                             records[index]['cost'] = double.parse(value),
//                       )),
//                       DataCell(TextField(
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           contentPadding: EdgeInsets.all(8.0),
//                           fillColor: color,
//                         ),
//                         style: TextStyle(fontSize: 14.0),
//                         controller: TextEditingController(
//                             text: records[index]['profit'].toStringAsFixed(
//                                 2)), // Format to two decimal places
//                         onChanged: (value) =>
//                             records[index]['profit'] = double.parse(value),
//                       )),
//                       DataCell(Text(
//                           DateFormat('yyyy-MM-dd').format(
//                               DateTime.parse(records[index]['created_at'])),
//                           style: TextStyle(fontSize: 14.0))),
//                       DataCell(
//                         IconButton(
//                           icon: Icon(Icons.edit),
//                           onPressed: () {
//                             editRecord(index);
//                           },
//                         ),
//                       ),
//                       DataCell(
//                         IconButton(
//                           icon: Icon(
//                             Icons.delete,
//                             color: Color.fromARGB(255, 247, 45, 30),
//                           ),
//                           onPressed: () {
//                             deleteRecord(index);
//                           },
//                         ),
//                       ),
//                     ],
//                   );
//                 }),
//               ),
//             ),
//     );
//   }

//   void deleteRecord(int index) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Confirm Deletion'),
//           content: Text('Are you sure you want to delete this record?'),
//           actions: [
//             TextButton(
//               onPressed: () async {
//                 // Close the dialog
//                 Navigator.of(context).pop();

//                 // Delete the record
//                 bool success = await deleteRecordFromAPI(
//                     records[index]['id'] ?? 0, records[index]['cust_id']);

//                 if (success) {
//                   // Remove the record from the list if deletion is successful
//                   setState(() {
//                     records.removeAt(index);
//                   });
//                 } else {
//                   // Show error message if deletion fails
//                   showDialog(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return AlertDialog(
//                         title: Text('Error'),
//                         content: Text('Failed to delete the record.'),
//                         actions: [
//                           TextButton(
//                             onPressed: () {
//                               Navigator.of(context).pop();
//                             },
//                             child: Text('OK'),
//                           ),
//                         ],
//                       );
//                     },
//                   );
//                 }
//               },
//               child: Text('Yes'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('No'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   Future<bool> deleteRecordFromAPI(int id, int user_id) async {
//     print(id);
//     try {
//       var response = await http.delete(
//         Uri.parse(baseURL + 'delete/$id/$user_id'),
//         headers: headers,
//       );
//       print(response.body);
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         // Record deleted successfully
//         // ScaffoldMessenger.of(context).showSnackBar(
//         //   const SnackBar(
//         //     content: Text('Record deleted successfully'),
//         //     backgroundColor: Colors.green,
//         //   ),
//         // );

//         MotionToast.delete(
//           //title: Text("Delete Successfully"),
//           description: Text("Record deleted successfully"),
//           position: MotionToastPosition.top,
//           animationType: AnimationType.fromTop,
//         ).show(context);

//         return true;
//       } else {
//         // Failed to delete the record
//         MotionToast.error(
//           //title: Text("Delete Successfully"),
//           description: Text("Record deleted Unsuccessfully"),
//           position: MotionToastPosition.top,
//           animationType: AnimationType.fromTop,
//         ).show(context);
//         return false;
//       }
//     } catch (error) {
//       // Error occurred while making the request
//       print('Error deleting record: $error');
//       return false;
//     }
//   }

//   void editRecord(int index) {
//     int id = records[index]['id'] ?? 0;
//     String cust_id = records[index]['cust_id'].toString();
//     String title = records[index]['title'];
//     double sales = records[index]['sales'];
//     double cost = records[index]['cost'];
//     double profit = records[index]['profit'];

//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text('Edit Record'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 initialValue: title,
//                 onChanged: (value) => title = value,
//                 decoration: InputDecoration(labelText: 'Title'),
//               ),
//               SizedBox(
//                 height: 10,
//               ),
//               TextFormField(
//                 initialValue: sales.toString(),
//                 onChanged: (value) => sales = double.tryParse(value) ?? 0,
//                 keyboardType: TextInputType.numberWithOptions(
//                     decimal: true), // Allow only numeric input
//                 decoration: InputDecoration(labelText: 'Sales'),
//               ),
//               SizedBox(
//                 height: 10,
//               ),
//               TextFormField(
//                 initialValue: cost.toString(),
//                 onChanged: (value) => cost = double.tryParse(value) ?? 0,
//                 keyboardType: TextInputType.numberWithOptions(
//                     decimal: true), // Allow only numeric input
//                 decoration: InputDecoration(labelText: 'Cost'),
//               ),
//               SizedBox(
//                 height: 10,
//               ),
//               TextFormField(
//                 initialValue: profit.toString(),
//                 onChanged: (value) => profit = double.tryParse(value) ?? 0,
//                 keyboardType: TextInputType.numberWithOptions(
//                     decimal: true), // Allow only numeric input
//                 decoration: InputDecoration(labelText: 'Profit'),
//               ),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 // Update record using API
//                 bool success = await updateRecord(
//                   id, // Assuming there's an 'id' field in your record data
//                   cust_id,
//                   title,
//                   sales,
//                   cost,
//                   profit,
//                 );

//                 // If update is successful, update the record in UI
//                 if (success) {
//                   setState(() {
//                     records[index]['id'] = id;
//                     records[index]['cust_id'] = cust_id;
//                     records[index]['title'] = title;
//                     records[index]['sales'] = sales;
//                     records[index]['cost'] = cost;
//                     records[index]['profit'] = profit;
//                   });

//                   Navigator.of(context).pop(); // Close the dialog
//                 } else {
//                   // Handle update failure
//                   // Show error message to the user
//                   showDialog(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return AlertDialog(
//                         title: Text('Error'),
//                         content: Text(
//                             'Failed to update the record. Please try again.'),
//                         actions: [
//                           TextButton(
//                             onPressed: () {
//                               Navigator.of(context).pop(); // Close the dialog
//                             },
//                             child: Text('OK'),
//                           ),
//                         ],
//                       );
//                     },
//                   );
//                 }
//               },
//               child: Text('Save'),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
