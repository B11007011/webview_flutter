import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Set preferred orientations and system UI overlay style
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Modify the system UI mode to use manual instead of edgeToEdge
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top],
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
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
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  double _statusBarHeight = 0;
  bool _triedFallback = false;
  
  // Define URLs
  final String _primaryUrl = 'https://ranran.azurewebsites.net/';
  final String _fallbackUrl = 'https://waterwise-eta.vercel.app/'; // This URL seemed to work in the logs

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Get the status bar height after the first frame is rendered
      _statusBarHeight = MediaQuery.of(context).padding.top;
      _setupWebView();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _controller != null) {
      _controller!.reload();
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

      final WebViewController controller = WebViewController.fromPlatformCreationParams(params);

      if (controller.platform is AndroidWebViewController) {
        AndroidWebViewController.enableDebugging(true);
        (controller.platform as AndroidWebViewController)
          ..setMediaPlaybackRequiresUserGesture(false)
          ..setBackgroundColor(Colors.transparent);
      }

      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(Colors.transparent);
      
      // Set custom user agent to improve compatibility
      await controller.setUserAgent('Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36');
      
      // Add these settings to help with cross-origin issues
      // For DOM storage (localStorage and sessionStorage)
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      
      // Enable cross-origin requests
      if (controller.platform is AndroidWebViewController) {
        final AndroidWebViewController androidController = controller.platform as AndroidWebViewController;
        // Android-specific settings that might help
        androidController.setMediaPlaybackRequiresUserGesture(false);
        androidController.setBackgroundColor(Colors.transparent);
      }
      
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onUrlChange: (UrlChange change) {
            print('URL changed to: ${change.url}');
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request to: ${request.url}');
            // Allow all navigation requests, including cross-origin ones
            return NavigationDecision.navigate;
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) async {
            // Inject CSS to adjust the website's header to avoid status bar overlap
            await _injectViewportAdjustment(controller);
            
            // Inject JavaScript to enhance cross-origin compatibility
            await _injectCompatibilityFixes(controller);
            
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            print('WebView error: ${error.errorCode} - ${error.description}');
            // Only set error state for major errors, not for resource loading errors
            if (error.isForMainFrame ?? false) {
              // If primary URL fails and we haven't tried fallback, try the fallback automatically
              if (!_triedFallback && error.url == _primaryUrl) {
                _tryFallbackUrl();
                return;
              }
              
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = '${error.errorCode}: ${error.description}';
              });
            }
          },
        ),
      );

      // Try an alternative approach to load the URL
      try {
        // Add headers that might help with CORS and ORB issues
        await controller.loadRequest(
          Uri.parse(_primaryUrl),
          headers: {
            'Accept': '*/*',
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'no-cache',
            'Connection': 'keep-alive',
          },
        );
      } catch (e) {
        print('Error loading initial URL: $e');
        // Fallback to a direct load without headers if the initial load fails
        await controller.loadRequest(Uri.parse(_primaryUrl));
      }

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Try fallback URL when primary URL fails
  Future<void> _tryFallbackUrl() async {
    if (_controller == null || _triedFallback) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _triedFallback = true;
    });
    
    try {
      await _controller!.loadRequest(Uri.parse(_fallbackUrl));
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load alternate URL: ${e.toString()}';
        });
      }
    }
  }

  // Inject JavaScript to adjust viewport to prevent status bar overlap
  Future<void> _injectViewportAdjustment(WebViewController controller) async {
    // Convert status bar height to viewport height units
    await controller.runJavaScript('''
      (function() {
        // Add a padding to the top of the body or adjust the header position
        document.body.style.paddingTop = "${_statusBarHeight}px";
        // Look for header or navigation elements that might need adjustment
        var header = document.querySelector('header') || 
                     document.querySelector('.header') || 
                     document.querySelector('.app-header') ||
                     document.querySelector('nav');
        if (header) {
          header.style.marginTop = "${_statusBarHeight}px";
        }
      })();
    ''');
  }

  // Inject JavaScript to enhance compatibility
  Future<void> _injectCompatibilityFixes(WebViewController controller) async {
    await controller.runJavaScript('''
      (function() {
        // Override certain browser APIs that might be causing issues
        if (window.fetch) {
          const originalFetch = window.fetch;
          window.fetch = function(url, options) {
            if (!options) options = {};
            if (!options.headers) options.headers = {};
            options.headers['Access-Control-Allow-Origin'] = '*';
            return originalFetch(url, options);
          };
        }
        
        // Add meta tag for viewport
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no';
        document.head.appendChild(meta);
        
        // Make cross-origin XMLHttpRequests more permissive if possible
        if (window.XMLHttpRequest) {
          const originalOpen = XMLHttpRequest.prototype.open;
          XMLHttpRequest.prototype.open = function(method, url, async, user, password) {
            const xhr = this;
            xhr.setRequestHeader = function(name, value) {
              if (name.toLowerCase() === 'origin') return;
              XMLHttpRequest.prototype.setRequestHeader.call(this, name, value);
            };
            return originalOpen.call(this, method, url, async, user, password);
          };
        }
      })();
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: PopScope(
        onPopInvoked: (bool didPop) async {
          if (didPop) return;
          if (_controller == null) {
            Navigator.of(context).pop();
            return;
          }
          
          try {
            final canGoBack = await _controller!.canGoBack();
            if (canGoBack) {
              await _controller!.goBack();
            } else {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        },
        child: Scaffold(
          // Don't extend body behind app bar to prevent overlap
          extendBodyBehindAppBar: false,
          extendBody: false,
          body: Column(
            children: [
              // Add a container with the same height as the status bar
              // to ensure we have proper spacing
              Container(
                height: MediaQuery.of(context).padding.top,
                color: Colors.transparent,
              ),
              Expanded(
                child: Stack(
                  children: [
                    if (_controller != null)
                      WebViewWidget(
                        controller: _controller!,
                      ),
                    if (_isLoading)
                      Container(
                        color: Colors.white.withOpacity(0.7),
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    if (_hasError)
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
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _hasError = false;
                                    _isLoading = true;
                                  });
                                  _triedFallback ? _setupWebView() : _tryFallbackUrl();
                                },
                                child: Text(_triedFallback ? 'Retry Primary URL' : 'Try Alternate URL'),
                              ),
                            ],
                          ),
                        ),
                      ),
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