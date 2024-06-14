import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:skilltest/models/user_model.dart';
import 'package:skilltest/screens/editdata.dart';
import 'package:skilltest/screens/home_screen.dart';
import 'package:skilltest/screens/menu.dart';

class MyNavigationBar extends StatefulWidget {
  final User loggedInUser;

  const MyNavigationBar({Key? key, required this.loggedInUser})
      : super(key: key);

  @override
  _MyNavigationBarState createState() => _MyNavigationBarState();
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.loggedInUser; // Access loggedInUser here
    final List<Widget> _widgetOptions = <Widget>[
      HomeScreen(), // Pass user as a parameter when creating HomeScreen
      EditRecordScreen(),
      MenuScreen(), // Pass user here
    ];

    return Scaffold(
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: CurvedNavigationBar(
        index: _selectedIndex,
        height: 50.0,
        items: <Widget>[
          Icon(Icons.home, size: 30),
          Icon(Icons.data_usage, size: 30),
          Icon(Icons.person, size: 30),
        ],
        color: Color.fromARGB(255, 193, 193, 193),
        buttonBackgroundColor: Colors.blue,
        backgroundColor: Colors.transparent,
        animationCurve: Curves.easeInOut,
        animationDuration: Duration(milliseconds: 600),
        onTap: _onItemTapped,
      ),
    );
  }
}
