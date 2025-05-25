import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  runApp(const MyFoodStockApp());
}

class MyFoodStockApp extends StatelessWidget {
  const MyFoodStockApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFoodStock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
    );
  }
}
