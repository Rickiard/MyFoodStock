import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_item.dart';
import '../models/food_item.dart';
import '../services/storage_service.dart';
import '../widgets/add_edit_shopping_dialog.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  List<ShoppingItem> _shoppingItems = [];
  final _uuid = const Uuid();
  bool _showCompleted = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await StorageService.getShoppingItems();
    setState(() {
      _shoppingItems = items;
    });
  }

  List<ShoppingItem> get _filteredItems {
    if (_showCompleted) {
      return _shoppingItems;
    } else {
      return _shoppingItems.where((item) => !item.isCompleted).toList();
    }
  }

  Future<void> _addItem() async {
    final result = await showDialog<ShoppingItem>(
      context: context,
      builder: (context) => const AddEditShoppingDialog(),
    );

    if (result != null) {
      await StorageService.addShoppingItem(result);
      _loadItems();
    }
  }

  Future<void> _editItem(ShoppingItem item) async {
    final result = await showDialog<ShoppingItem>(
      context: context,
      builder: (context) => AddEditShoppingDialog(shoppingItem: item),
    );

    if (result != null) {
      await StorageService.updateShoppingItem(result);
      _loadItems();
    }
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Item'),
        content: Text('Tem certeza que deseja remover "${item.name}" da lista?'),
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
    );

    if (confirmed == true) {
      await StorageService.deleteShoppingItem(item.id);
      _loadItems();
    }
  }

  Future<void> _toggleCompleted(ShoppingItem item) async {
    final updatedItem = item.copyWith(isCompleted: !item.isCompleted);
    await StorageService.updateShoppingItem(updatedItem);
    _loadItems();
  }

  Future<void> _updateQuantity(ShoppingItem item, int change) async {
    final newQuantity = item.quantity + change;
    if (newQuantity < 1) return;

    final updatedItem = item.copyWith(quantity: newQuantity);
    await StorageService.updateShoppingItem(updatedItem);
    _loadItems();
  }

  Future<void> _addFromStock() async {
    final foodItems = await StorageService.getFoodItems();
    if (foodItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum alimento no stock para adicionar'),
        ),
      );
      return;
    }

    final selectedItems = await showDialog<List<FoodItem>>(
      context: context,
      builder: (context) => _StockSelectionDialog(foodItems: foodItems),
    );

    if (selectedItems != null && selectedItems.isNotEmpty) {
      for (final foodItem in selectedItems) {
        final shoppingItem = ShoppingItem(
          id: _uuid.v4(),
          name: foodItem.name,
          quantity: 1,
          notes: 'Adicionado do stock',
        );
        await StorageService.addShoppingItem(shoppingItem);
      }
      _loadItems();
    }
  }

  Future<void> _clearCompleted() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Concluídos'),
        content: const Text('Tem certeza que deseja remover todos os itens concluídos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final completedItems = _shoppingItems.where((item) => item.isCompleted).toList();
      for (final item in completedItems) {
        await StorageService.deleteShoppingItem(item.id);
      }
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    final completedCount = _shoppingItems.where((item) => item.isCompleted).length;
    final totalCount = _shoppingItems.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Compras'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'add_from_stock':
                  _addFromStock();
                  break;
                case 'clear_completed':
                  _clearCompleted();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'add_from_stock',
                child: Row(
                  children: [
                    Icon(Icons.kitchen),
                    SizedBox(width: 8),
                    Text('Adicionar do Stock'),
                  ],
                ),
              ),
              if (completedCount > 0)
                const PopupMenuItem(
                  value: 'clear_completed',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all),
                      SizedBox(width: 8),
                      Text('Limpar Concluídos'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Header com estatísticas
          Container(
            color: Colors.blue[700],
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completedCount/$totalCount concluídos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        const Text(
                          'Mostrar concluídos',
                          style: TextStyle(color: Colors.white),
                        ),
                        Switch(
                          value: _showCompleted,
                          onChanged: (value) {
                            setState(() {
                              _showCompleted = value;
                            });
                          },
                          activeColor: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
                if (totalCount > 0)
                  LinearProgressIndicator(
                    value: totalCount > 0 ? completedCount / totalCount : 0,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _shoppingItems.isEmpty 
                              ? 'Lista de compras vazia\nToque no + para adicionar itens' 
                              : 'Nenhum item para mostrar',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : SafeArea(
                    top: false,
                    left: false,
                    right: false,
                    child: ListView.builder(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 80),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _ShoppingItemCard(
                          item: item,
                          onToggleCompleted: () => _toggleCompleted(item),
                          onEdit: () => _editItem(item),
                          onDelete: () => _deleteItem(item),
                          onQuantityChanged: (change) => _updateQuantity(item, change),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 16),
        child: FloatingActionButton(
          onPressed: _addItem,
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}

class _ShoppingItemCard extends StatelessWidget {
  final ShoppingItem item;
  final VoidCallback onToggleCompleted;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(int) onQuantityChanged;

  const _ShoppingItemCard({
    required this.item,
    required this.onToggleCompleted,
    required this.onEdit,
    required this.onDelete,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: item.isCompleted,
                  onChanged: (_) => onToggleCompleted(),
                  activeColor: Colors.green,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          decoration: item.isCompleted 
                              ? TextDecoration.lineThrough 
                              : null,
                          color: item.isCompleted 
                              ? Colors.grey[600] 
                              : null,
                        ),
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.notes!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  color: Colors.blue[600],
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  color: Colors.red[600],
                ),
              ],
            ),
            const SizedBox(height: 12),
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
                      onPressed: () => onQuantityChanged(-1),
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
                      onPressed: () => onQuantityChanged(1),
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
}

class _StockSelectionDialog extends StatefulWidget {
  final List<FoodItem> foodItems;

  const _StockSelectionDialog({required this.foodItems});

  @override
  State<_StockSelectionDialog> createState() => _StockSelectionDialogState();
}

class _StockSelectionDialogState extends State<_StockSelectionDialog> {
  final Set<String> _selectedItems = {};

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Selecionar do Stock',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: widget.foodItems.length,
                itemBuilder: (context, index) {
                  final item = widget.foodItems[index];
                  final isSelected = _selectedItems.contains(item.id);

                  return CheckboxListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.category.displayName} - Quantidade: ${item.quantity}',
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedItems.add(item.id);
                        } else {
                          _selectedItems.remove(item.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _selectedItems.isEmpty
                      ? null
                      : () {
                          final selectedFoodItems = widget.foodItems
                              .where((item) => _selectedItems.contains(item.id))
                              .toList();
                          Navigator.of(context).pop(selectedFoodItems);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Adicionar (${_selectedItems.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
