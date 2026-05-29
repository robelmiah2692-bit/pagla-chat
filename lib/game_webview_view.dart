import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GameWebViewView extends StatefulWidget {
  final String gameUrl;
  final String gameName;

  const GameWebViewView({super.key, required this.gameUrl, required this.gameName});

  @override
  State<GameWebViewView> createState() => _GameWebViewViewState();
}

class _GameWebViewViewState extends State<GameWebViewView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.gameUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(child: WebViewWidget(controller: _controller)),
    );
  }
}