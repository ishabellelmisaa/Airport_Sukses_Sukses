import 'package:airplane_thoriq/ui/pages/ScanResultPage.dart';
import 'package:airplane_thoriq/ui/pages/get_started_page.dart';
import 'package:airplane_thoriq/ui/pages/sign_up_page.dart';
import 'package:airplane_thoriq/ui/pages/splash_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => SplashPage(),
        '/sign-up': (context) => SignUpPage(),
        '/get-started': (context) => GetStartedPage(),
        '/scan-result': (context) => ScanResultPage(
              rawpnr: '',
              token: '',
            ),
      },
    );
  }
}
