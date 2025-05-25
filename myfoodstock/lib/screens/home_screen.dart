import 'package:flutter/material.dart';
import 'stock_screen.dart';
import 'shopping_list_screen.dart';
import 'sync_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const StockScreen(),
    const ShoppingListScreen(),
    const SyncScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false, // Para usar todo o espaço na parte inferior
        child: _screens[_currentIndex],
      ),      extendBody: true, // Permite que o conteúdo se estenda por baixo do navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.95),
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Compras',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sync),
            label: 'Sincronizar',
          ),        ],
        ),
      ),
    );
  }
}
