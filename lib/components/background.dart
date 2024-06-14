import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  const Background({
    Key? key,
    required this.child,
    this.topImage = "assets/images/main_top.png",
    this.bottomImage = "assets/images/login_bottom.png",
    this.backgroundImage = "assets/images/background.jpg", // Add background image path
  }) : super(key: key);

  final String topImage, bottomImage, backgroundImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImage), // Set the background image
            fit: BoxFit.cover, // You can adjust the fit as needed
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Positioned(
              top: 0,
              left: 0,
              child: Image.asset(
                topImage,
                width: 120,
              ),
            ),
            Positioned(
              bottom: 0,
              right: -18,
              child: Image.asset(bottomImage, width: 120),
            ),
            SafeArea(child: child),
          ],
        ),
      ),
    );
  }
}
