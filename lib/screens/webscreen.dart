// import 'package:flutter/material.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class WebViewScreen extends StatefulWidget {
//   final String initialUrl;

//   const WebViewScreen({Key? key, required this.initialUrl}) : super(key: key);

//   @override
//   _WebViewScreenState createState() => _WebViewScreenState();
// }

// class _WebViewScreenState extends State<WebViewScreen> {
//   late WebViewController _webViewController;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Web View"),
//       ),
//       body: SafeArea(
//         child: WebView(initialUrl: widget.initialUrl,
//             onWebViewCreated: (WebViewController webViewController) {
//           _webViewController = webViewController;
//         }, JavaScriptMode.unrestricted),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () async {
//           if (await _webViewController.canGoBack()) {
//             _webViewController.goBack();
//           } else {
//             Navigator.pop(context); // Navigate back to the previous screen
//           }
//         },
//         child: Icon(Icons.arrow_back),
//       ),
//     );
//   }
// }
