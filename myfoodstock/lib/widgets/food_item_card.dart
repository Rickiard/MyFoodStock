import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/food_item.dart';
import '../theme/app_theme.dart';

class FoodItemCard extends StatelessWidget {
  final FoodItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(int) onQuantityChanged;
  final VoidCallback? onAddToShoppingList;

  const FoodItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onQuantityChanged,
    this.onAddToShoppingList,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getBorderColor(),
          width: item.isExpired || item.isExpiringSoon ? 2 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name and status
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildCategoryChip(),
                      ],
                    ),
                  ),
                  if (item.isExpired || item.isExpiringSoon)
                    _buildStatusBadge(),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                        case 'add_to_shopping':
                          onAddToShoppingList?.call();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                      ),
                      if (onAddToShoppingList != null)
                        const PopupMenuItem(
                          value: 'add_to_shopping',
                          child: Row(
                            children: [
                              Icon(Icons.add_shopping_cart, size: 20),
                              SizedBox(width: 8),
                              Text('Adicionar à lista'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Remover', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Expiry date info
              if (item.expiryDate != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: StatusColors.getExpiryColor(item.expiryDate),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Validade: ${dateFormat.format(item.expiryDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: StatusColors.getExpiryColor(item.expiryDate),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (item.expiryDate != null)
                      Text(
                        _getDaysUntilExpiry(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: StatusColors.getExpiryColor(item.expiryDate),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ],
              
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),
              
              // Quantity controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quantidade:',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      _QuantityButton(
                        icon: Icons.remove,
                        onPressed: () => onQuantityChanged(-1),
                        color: Colors.red[600]!,
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      _QuantityButton(
                        icon: Icons.add,
                        onPressed: () => onQuantityChanged(1),
                        color: Colors.green[600]!,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: StatusColors.getCategoryColor(item.category.displayName),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        item.category.displayName,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    final isExpired = item.isExpired;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isExpired ? AppColors.expired : AppColors.expiringSoon,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.warning : Icons.schedule,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isExpired ? 'EXPIRADO' : 'EXPIRA EM BREVE',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBorderColor() {
    if (item.isExpired) return AppColors.expired;
    if (item.isExpiringSoon) return AppColors.expiringSoon;
    return Colors.transparent;
  }

  String _getDaysUntilExpiry() {
    if (item.expiryDate == null) return '';
    
    final difference = item.expiryDate!.difference(DateTime.now()).inDays;
    
    if (difference < 0) {
      return '${-difference} dias expirado';
    } else if (difference == 0) {
      return 'Expira hoje';
    } else if (difference == 1) {
      return 'Expira amanhã';
    } else {
      return 'Expira em $difference dias';
    }
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
      ),
    );
  }
}
