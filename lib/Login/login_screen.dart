import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:skilltest/constants.dart';
import 'package:skilltest/responsive.dart';

import '../../components/background.dart';
import 'components/login_form.dart';
import 'components/login_screen_top_image.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Background(
      child: SingleChildScrollView(
        child: Responsive(
          mobile: MobileLoginScreen(),
          desktop: Row(
            children: [
              Expanded(
                child: LoginScreenTopImage(),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 450,
                      child: LoginForm(),
                    ),
                    SizedBox(height: defaultPadding / 2),
                    AppVersionDisplay(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MobileLoginScreen extends StatelessWidget {
  const MobileLoginScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        LoginScreenTopImage(),
        Row(
          children: [
            Spacer(),
            Expanded(
              flex: 8,
              child: LoginForm(),
            ),
            Spacer(),
          ],
        ),
        AppVersionDisplay(),
      ],
    );
  }
}

class AppVersionDisplay extends StatelessWidget {
  const AppVersionDisplay({Key? key}) : super(key: key);

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version} (${packageInfo.buildNumber})';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _getAppVersion(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text(
            'Version info unavailable',
            style: TextStyle(color: Colors.red),
          );
        } else if (snapshot.hasData && snapshot.data != null) {
          return Text(
            'Version: ${snapshot.data}',
            style: TextStyle(color: Colors.grey),
          );
        } else {
          return Text(
            'Version info not found',
            style: TextStyle(color: Colors.grey),
          );
        }
      },
    );
  }
}
