import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/splash/presentation/splash_page.dart';

class EMarketApp extends StatelessWidget {
  const EMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'e-market',
      theme: AppTheme.light,
      home: const SplashPage(),
    );
  }
}
