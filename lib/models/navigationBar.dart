import 'package:bottom_navy_bar/bottom_navy_bar.dart';
import 'package:flutter/material.dart';
import 'package:skilltest/screens/daterangeEditscreen.dart';
import 'package:skilltest/screens/filterTransaction.dart';
import 'package:skilltest/screens/home_screen.dart';
import 'package:skilltest/screens/menu.dart';
import 'package:skilltest/screens/productScreen.dart';
import 'package:skilltest/services/currencyget.dart';

class MyNavigationBar extends StatefulWidget {
  @override
  _MyNavigationBarState createState() => _MyNavigationBarState();
}

class _MyNavigationBarState extends State<MyNavigationBar> {
  int _currentIndex = 0;
  late PageController _pageController; // Use 'late'

  @override
  void initState() {
    super.initState();
    CurrencyService().fetchCurrencyValue();
    _pageController = PageController(); // Initialize in initState
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: <Widget>[
          HomeScreen(),
          DateRangeLogEditScreen(),
          DateRangeLogScreen(),
          ProductScreen(),
          MenuScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavyBar(
        selectedIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() => _currentIndex = index);
          _pageController.jumpToPage(index);
        },
        items: <BottomNavyBarItem>[
          BottomNavyBarItem(
              title: Text('Home'),
              icon: Icon(Icons.home),
              activeColor: Color(0xFF005959)),
          BottomNavyBarItem(
              title: Text('Edit'),
              icon: Icon(Icons.edit),
              activeColor: Color(0xFF005959)),
          BottomNavyBarItem(
              title: Text('Quick'),
              icon: Icon(Icons.assessment),
              activeColor: Color(0xFF005959)),
          BottomNavyBarItem(
              title: Text('Products'),
              icon: Icon(Icons.inventory),
              activeColor: Color(0xFF005959)),
          BottomNavyBarItem(
              title: Text('Profile'),
              icon: Icon(Icons.person),
              activeColor: Color(0xFF005959)),
        ],
      ),
    );
  }
}
