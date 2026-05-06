import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:permission_handler/permission_handler.dart';

class ScantrixWebView extends StatefulWidget {
  const ScantrixWebView({super.key});

  @override
  State<ScantrixWebView> createState() => _ScantrixWebViewState();
}

class _ScantrixWebViewState extends State<ScantrixWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isError = false; // New: Flag para sa offline/error state

  @override
  void initState() {
    super.initState();
    
    _requestCameraPermission();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params);

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) setState(() {
              _isLoading = true;
              _isError = false; // Reset error state pag nag-load ulit
            });
          },
          onPageFinished: (url) {
            _controller.runJavaScript('''
              document.documentElement.style.overflowX = 'hidden';
              document.body.style.overflowX = 'hidden';
              document.body.style.margin = '0';
              document.body.style.padding = '0';
            ''');
            if (mounted) setState(() => _isLoading = false);
          },
          // ETO ANG FIX: Hahawakan nito ang "Web page not available" error
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _isError = true; // Ipakita ang Offline UI
              });
            }
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      (_controller.platform as AndroidWebViewController).setOnPlatformPermissionRequest(
        (request) => request.grant(),
      );
    }

    _controller.loadRequest(Uri.parse('https://ap.mgap-ph.com/'));
  }

  Future<void> _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (status.isDenied) {
      await Permission.camera.request();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: WillPopScope(
        onWillPop: () async {
          if (await _controller.canGoBack()) {
            await _controller.goBack();
            return false;
          }
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Stack(
            alignment: Alignment.center, 
            children: [
              // 1. WEBVIEW
              Positioned.fill(
                child: SafeArea(
                  top: true, 
                  bottom: false,
                  child: WebViewWidget(controller: _controller),
                ),
              ),

              // 2. OFFLINE / ERROR UI (Lilitaw pag walang net)
              if (_isError)
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: double.infinity,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_rounded, size: 60, color: Colors.grey),
                        const SizedBox(height: 20),
                        const Text(
                          "Cannot Load Scantrix",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text("Please check your internet connection.", style: TextStyle(color: Colors.red)),
                        const SizedBox(height: 25),
                        ElevatedButton(
                          onPressed: () => _controller.reload(),
                          child: const Text("Try Again"),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. LOADING SCREEN
              if (_isLoading)
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: double.infinity,
                  child: Center( 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/logo.png', width: 100, fit: BoxFit.contain),
                        const SizedBox(height: 25),
                        const SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            minHeight: 2,
                            color: Colors.blueAccent,
                            backgroundColor: Color(0xFFF0F0F0),
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Loading Scantrix...",
                          style: TextStyle(fontSize: 11, color: Colors.grey, letterSpacing: 1.2),
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