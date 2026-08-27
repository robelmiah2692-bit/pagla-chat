import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  _PrivacyPolicyPageState createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // জাভাস্ক্রিপ্ট এনাবল করা হয়েছে যাতে লেখার কালার পরিবর্তন করা যায়
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // পেজ লোড হওয়ার পর জাভাস্ক্রিপ্ট দিয়ে টেক্সট কালার সাদা এবং ব্যাকগ্রাউন্ড হালকা করা হলো
            _controller.runJavaScript(
              "document.body.style.color = 'white'; "
              "document.body.style.backgroundColor = 'transparent';"
              "var tags = document.getElementsByp || document.getElementsByTagName('p');"
              "for(var i=0; i<document.all.length; i++) { document.all[i].style.color = 'white'; }",
            );
          },
        ),
      )
      ..loadRequest(Uri.parse('https://raw.githubusercontent.com/robelmiah2692-bit/vip-badges/refs/heads/main/officialall/policy'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF190033),
      appBar: AppBar(
        title: const Text("Privacy Policy", style: TextStyle(color: Colors.cyanAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Container(
        decoration: const BoxDecoration(
          // ছবির কালারের সাথে মিলিয়ে হুবহু গ্রেডিয়েন্ট
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF00B4DB), // Bright Cyan Blue
              Color.fromARGB(255, 100, 212, 250), // Mid Blue
              Color.fromARGB(218, 74, 204, 243), // Deep Purple
              Color.fromARGB(234, 61, 190, 250), // Dark Purple Base
            ],
          ),
        ),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}