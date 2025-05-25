import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar orientação apenas para vertical (portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Configurar modo fullscreen e lidar com notch
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [], // Remove todas as barras do sistema
  );
  
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
