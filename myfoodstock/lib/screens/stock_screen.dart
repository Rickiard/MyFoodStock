import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';
import '../models/shopping_item.dart';
import '../services/storage_service.dart';
import '../widgets/add_edit_food_dialog.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  List<FoodItem> _allItems = [];
  List<FoodItem> _filteredItems = [];
  FoodCategory? _selectedCategory;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await StorageService.getFoodItems();
    setState(() {
      _allItems = items;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredItems = _allItems.where((item) {
      final matchesCategory = _selectedCategory == null || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || 
          item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
    
    // Ordenar por validade (expirados primeiro, depois próximos do vencimento)
    _filteredItems.sort((a, b) {
      if (a.isExpired && !b.isExpired) return -1;
      if (!a.isExpired && b.isExpired) return 1;
      if (a.isExpiringSoon && !b.isExpiringSoon) return -1;
      if (!a.isExpiringSoon && b.isExpiringSoon) return 1;
      return a.name.compareTo(b.name);
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  void _onCategoryChanged(FoodCategory? category) {
    setState(() {
      _selectedCategory = category;
      _applyFilters();
    });
  }

  Future<void> _addItem() async {
    final result = await showDialog<FoodItem>(
      context: context,
      builder: (context) => const AddEditFoodDialog(),
    );

    if (result != null) {
      await StorageService.addFoodItem(result);
      _loadItems();
    }
  }

  Future<void> _editItem(FoodItem item) async {
    final result = await showDialog<FoodItem>(
      context: context,
      builder: (context) => AddEditFoodDialog(foodItem: item),
    );

    if (result != null) {
      await StorageService.updateFoodItem(result);
      _loadItems();
    }
  }

  Future<void> _deleteItem(FoodItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Item'),
        content: Text('Tem certeza que deseja remover "${item.name}" do stock?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );    if (confirmed == true) {
      await StorageService.deleteFoodItem(item.id);
      _loadItems();
    }
  }

  Future<void> _addToShoppingList(FoodItem item) async {
    final shoppingItem = ShoppingItem(
      id: _uuid.v4(),
      name: item.name,
      quantity: 1,
      notes: 'Adicionado do stock',
    );

    await StorageService.addShoppingItem(shoppingItem);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} adicionado à lista de compras'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _updateQuantity(FoodItem item, int change) async {
    final newQuantity = item.quantity + change;
    if (newQuantity < 0) return;

    final updatedItem = item.copyWith(quantity: newQuantity);
    await StorageService.updateFoodItem(updatedItem);
    _loadItems();
  }

  Widget _buildFoodItemCard(FoodItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isExpired 
              ? Colors.red 
              : item.isExpiringSoon 
                  ? Colors.orange 
                  : Colors.transparent,
          width: item.isExpired || item.isExpiringSoon ? 2 : 0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (item.isExpired)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'EXPIRADO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (item.isExpiringSoon)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'EXPIRA EM BREVE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.category.displayName,
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (item.expiryDate != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Exp: ${item.expiryDate!.day}/${item.expiryDate!.month}/${item.expiryDate!.year}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),                ),
                IconButton(
                  onPressed: () => _editItem(item),
                  icon: const Icon(Icons.edit),
                  color: Colors.blue[600],
                ),
                IconButton(
                  onPressed: () => _addToShoppingList(item),
                  icon: const Icon(Icons.add_shopping_cart),
                  color: Colors.green[600],
                  tooltip: 'Adicionar à lista de compras',
                ),
                IconButton(
                  onPressed: () => _deleteItem(item),
                  icon: const Icon(Icons.delete),
                  color: Colors.red[600],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Quantidade:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _updateQuantity(item, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red[600],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _updateQuantity(item, 1),
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.green[600],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock de Alimentos'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.green[700],
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Barra de pesquisa
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar alimentos...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Filtro por categoria
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(
                          label: 'Todos',
                          isSelected: _selectedCategory == null,
                          onTap: () => _onCategoryChanged(null),
                        ),
                        ...FoodCategory.values.map(
                          (category) => _CategoryChip(
                            label: category.displayName,
                            isSelected: _selectedCategory == category,
                            onTap: () => _onCategoryChanged(category),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.kitchen_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _allItems.isEmpty 
                                ? 'Nenhum alimento no stock\nToque no + para adicionar' 
                                : 'Nenhum resultado encontrado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return _buildFoodItemCard(item);
                    },
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addItem,
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),        backgroundColor: Colors.green[800],
        selectedColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.green[700] : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        checkmarkColor: Colors.green[700],
        side: BorderSide(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
      ),
    );  }
}
