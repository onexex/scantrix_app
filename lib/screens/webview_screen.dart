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

  @override
  void initState() {
    super.initState();
    
    _requestCameraPermission();

    // 1. Initialize with Android Parameters for Camera/Mic Access
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
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (url) {
            // FORCE CSS: Eto ang pumapatay sa padding sa kanan
            _controller.runJavaScript('''
              document.documentElement.style.overflowX = 'hidden';
              document.body.style.overflowX = 'hidden';
              document.body.style.margin = '0';
              document.body.style.padding = '0';
            ''');
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      );

    // 2. CAMERA PERMISSION GRANT: Para sa Html5Qrcode ng website mo
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
            // ETO ANG NAG-CE-CENTER SA VIEW AREA
            alignment: Alignment.center, 
            children: [
              
              // 1. WEBVIEW: Full width at protected ang taas (SafeArea)
              Positioned.fill(
                child: SafeArea(
                  top: true, 
                  bottom: false,
                  child: WebViewWidget(controller: _controller),
                ),
              ),

              // 2. LOADING SCREEN: Laging nasa gitna
              if (_isLoading)
                Container(
                  color: Colors.white,
                  width: double.infinity,
                  height: double.infinity,
                  child: Center( 
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/logo.png',
                          width: 100,
                          fit: BoxFit.contain,
                        ),
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
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