import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'dart:io' show Platform;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  WebViewController? _controller;
  bool isLoading = true;
  bool canGoBack = false;
  bool canGoForward = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupWebView();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller?.reload();
    }
  }

  Future<void> _setupWebView() async {
    try {
      late final PlatformWebViewControllerCreationParams params;

      if (WebViewPlatform.instance is WebKitWebViewPlatform) {
        params = WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        );
      } else {
        params = const PlatformWebViewControllerCreationParams();
      }

      final controller = WebViewController.fromPlatformCreationParams(params);

      if (controller.platform is AndroidWebViewController) {
        final androidController = controller.platform as AndroidWebViewController;
        await androidController.setMediaPlaybackRequiresUserGesture(false);
      }

      await controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.transparent)
        ..enableZoom(true)
        ..setNavigationDelegate(
          NavigationDelegate(
            onProgress: (int progress) {
              if (mounted) {
                setState(() {
                  isLoading = progress < 100;
                });
              }
            },
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  isLoading = true;
                  error = null;
                });
              }
            },
            onPageFinished: (String url) async {
              if (mounted) {
                setState(() {
                  isLoading = false;
                });
                canGoBack = await controller.canGoBack();
                canGoForward = await controller.canGoForward();
                setState(() {});
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  this.error = error.description;
                  isLoading = false;
                });
              }
            },
          ),
        );

      // Load the URL
      await controller.loadRequest(
        Uri.parse('https://hackathon-app-mu.vercel.app/'),
      );

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_controller != null && await _controller!.canGoBack()) {
          _controller!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: _controller == null
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    WebViewWidget(
                      controller: _controller!,
                    ),
                    if (isLoading)
                      Container(
                        color: Colors.white70,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    if (error != null)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _setupWebView,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Try Again'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}