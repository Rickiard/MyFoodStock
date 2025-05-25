class ShoppingItem {
  final String id;
  String name;
  int quantity;
  bool isCompleted;
  DateTime createdAt;
  DateTime updatedAt;
  String? notes;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.quantity,
    this.isCompleted = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.notes,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'notes': notes,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      quantity: json['quantity'],
      isCompleted: json['isCompleted'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      notes: json['notes'],
    );
  }

  ShoppingItem copyWith({
    String? id,
    String? name,
    int? quantity,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      notes: notes ?? this.notes,
    );
  }
}
