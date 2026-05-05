import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/webview_screen.dart';

void main() async {
  // Siguraduhin na ang engine ay initialized bago mag-call ng SystemChrome
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. I-lock sa Portrait mode para sa consistent na UI ng Scantrix
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // 2. Full Screen Mode: Itago ang Status Bar at Navigation Bar
  // Gamit ang immersiveSticky para hindi agad lumabas ang bars sa accidental touch
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // 3. (Optional) Gawing transparent ang system overlays para sa seamless look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  
  runApp(const ScantrixApp());
}

class ScantrixApp extends StatelessWidget {
  const ScantrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scantrix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Adaptive density para sa tamang spacing sa iba't ibang devices
        visualDensity: VisualDensity.adaptivePlatformDensity,
        // Siguraduhin na puti ang background para match sa loading screen
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ScantrixWebView(),
    );
  }
}