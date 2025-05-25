import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/food_item.dart';

class AddEditFoodDialog extends StatefulWidget {
  final FoodItem? foodItem;

  const AddEditFoodDialog({super.key, this.foodItem});

  @override
  State<AddEditFoodDialog> createState() => _AddEditFoodDialogState();
}

class _AddEditFoodDialogState extends State<AddEditFoodDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _dateController = TextEditingController();
  
  FoodCategory _selectedCategory = FoodCategory.other;
  DateTime? _selectedDate;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    
    if (widget.foodItem != null) {
      _nameController.text = widget.foodItem!.name;
      _quantityController.text = widget.foodItem!.quantity.toString();
      _selectedCategory = widget.foodItem!.category;
      _selectedDate = widget.foodItem!.expiryDate;
      
      if (_selectedDate != null) {
        _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate!);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _dateController.text = DateFormat('dd/MM/yyyy').format(date);
      });
    }
  }

  void _clearDate() {
    setState(() {
      _selectedDate = null;
      _dateController.clear();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final item = FoodItem(
      id: widget.foodItem?.id ?? _uuid.v4(),
      name: _nameController.text.trim(),
      quantity: int.parse(_quantityController.text),
      expiryDate: _selectedDate,
      category: _selectedCategory,
      createdAt: widget.foodItem?.createdAt,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.foodItem != null;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Editar Alimento' : 'Adicionar Alimento',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Nome
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome do alimento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.restaurant),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira o nome do alimento';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              
              // Quantidade
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantidade',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.format_list_numbered),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira a quantidade';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Insira uma quantidade válida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Categoria
              DropdownButtonFormField<FoodCategory>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: FoodCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Data de validade
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Data de validade (opcional)',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixIcon: _selectedDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearDate,
                        )
                      : null,
                ),
                readOnly: true,
                onTap: _selectDate,
              ),
              const SizedBox(height: 24),
              
              // Botões
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(isEditing ? 'Atualizar' : 'Adicionar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
