enum FoodCategory {
  fruits,
  vegetables,
  meat,
  dairy,
  grains,
  beverages,
  snacks,
  frozen,
  other
}

extension FoodCategoryExtension on FoodCategory {
  String get displayName {
    switch (this) {
      case FoodCategory.fruits:
        return 'Frutas';
      case FoodCategory.vegetables:
        return 'Vegetais';
      case FoodCategory.meat:
        return 'Carnes';
      case FoodCategory.dairy:
        return 'Lacticínios';
      case FoodCategory.grains:
        return 'Cereais';
      case FoodCategory.beverages:
        return 'Bebidas';
      case FoodCategory.snacks:
        return 'Snacks';
      case FoodCategory.frozen:
        return 'Congelados';
      case FoodCategory.other:
        return 'Outros';
    }
  }

  static FoodCategory fromString(String category) {
    return FoodCategory.values.firstWhere(
      (e) => e.toString() == category,
      orElse: () => FoodCategory.other,
    );
  }
}

class FoodItem {
  final String id;
  String name;
  int quantity;
  DateTime? expiryDate;
  FoodCategory category;
  DateTime createdAt;
  DateTime updatedAt;

  FoodItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.expiryDate,
    required this.category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'expiryDate': expiryDate?.toIso8601String(),
      'category': category.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      expiryDate: json['expiryDate'] != null 
          ? DateTime.parse(json['expiryDate']) 
          : null,
      category: FoodCategoryExtension.fromString(json['category']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  FoodItem copyWith({
    String? id,
    String? name,
    int? quantity,
    DateTime? expiryDate,
    FoodCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      expiryDate: expiryDate ?? this.expiryDate,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  bool get isExpired => expiryDate != null && expiryDate!.isBefore(DateTime.now());
  
  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final difference = expiryDate!.difference(DateTime.now()).inDays;
    return difference <= 3 && difference >= 0;
  }
}
