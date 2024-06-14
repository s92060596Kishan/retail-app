import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:motion_toast/motion_toast.dart';
import 'package:skilltest/services/baseurl.dart';

class AddRecordScreen extends StatefulWidget {
  @override
  _AddRecordScreenState createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _name;
  late double _sales;
  late double _cost;
  late double _profit;
  bool _isLoading = false;

  //late String _csrfToken; // Variable to hold the CSRF token

  @override
  void initState() {
    super.initState();
    // Call a function to obtain the CSRF token when the screen initializes
    //obtainCsrfToken();
  }

  // Function to obtain CSRF token from the server
  // Future<void> obtainCsrfToken() async {
  //   try {
  //     final response = await http.get(Uri.parse(baseURL + 'csrf-token'));
  //     if (response.statusCode == 200) {
  //       setState(() {
  //         _csrfToken =
  //             response.body; // Set the CSRF token received from the server
  //       });
  //     } else {
  //       throw Exception('Failed to obtain CSRF token');
  //     }
  //   } catch (error) {
  //     print('Error obtaining CSRF token: $error');
  //   }
  // }

  void _saveDataToApi() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });
      var url = baseURL + 'putdata';
      //print(_csrfToken);
      // final headers = {
      //   'Content-Type': 'application/json',
      //   'X-CSRF-Token': _csrfToken, // Include CSRF token in the headers
      // };
      final body = jsonEncode({
        'title': _name,
        'sales': _sales,
        'cost': _cost,
        'profit': _profit,
      });

      try {
        var response =
            await http.post(Uri.parse(url), headers: headers, body: body);
        print(headers);
        print(response.body);
        print(response.statusCode);
        if (response.statusCode == 200) {
          print('Data saved successfully.');
          MotionToast.success(
            //title: Text("Delete Successfully"),
            description: Text("Data saved successfully."),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
          ).show(context);
        } else {
          print('Failed to save data. Error: ${response.reasonPhrase}');
          MotionToast.error(
            //title: Text("Delete Successfully"),
            description: Text("Data saved Unsuccessfully."),
            position: MotionToastPosition.top,
            animationType: AnimationType.fromTop,
          ).show(context);
        }
      } catch (error) {
        print('Failed to save data. Error: $error');
        MotionToast.error(
          //title: Text("Delete Successfully"),
          description: Text("Data saved Unsuccessfully."),
          position: MotionToastPosition.top,
          animationType: AnimationType.fromTop,
        ).show(context);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Record'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              child: Center(
                child: Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a name';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _name = value!;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Sales'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter sales amount';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _sales = double.parse(value!);
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Cost'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter cost amount';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _cost = double.parse(value!);
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Profit'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter profit amount';
                            }
                            return null;
                          },
                          onSaved: (value) {
                            _profit = double.parse(value!);
                          },
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _saveDataToApi,
                          child: Text(
                            'Submit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
