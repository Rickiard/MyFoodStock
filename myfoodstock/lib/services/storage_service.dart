import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import '../models/shopping_item.dart';

class StorageService {
  static const String _foodItemsKey = 'food_items';
  static const String _shoppingItemsKey = 'shopping_items';
  
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Food Items Storage
  static Future<List<FoodItem>> getFoodItems() async {
    final String? itemsJson = _prefs?.getString(_foodItemsKey);
    if (itemsJson == null) return [];
    
    final List<dynamic> itemsList = json.decode(itemsJson);
    return itemsList.map((item) => FoodItem.fromJson(item)).toList();
  }

  static Future<void> saveFoodItems(List<FoodItem> items) async {
    final String itemsJson = json.encode(items.map((item) => item.toJson()).toList());
    await _prefs?.setString(_foodItemsKey, itemsJson);
  }

  static Future<void> addFoodItem(FoodItem item) async {
    final items = await getFoodItems();
    items.add(item);
    await saveFoodItems(items);
  }

  static Future<void> updateFoodItem(FoodItem updatedItem) async {
    final items = await getFoodItems();
    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      items[index] = updatedItem;
      await saveFoodItems(items);
    }
  }

  static Future<void> deleteFoodItem(String id) async {
    final items = await getFoodItems();
    items.removeWhere((item) => item.id == id);
    await saveFoodItems(items);
  }

  // Shopping Items Storage
  static Future<List<ShoppingItem>> getShoppingItems() async {
    final String? itemsJson = _prefs?.getString(_shoppingItemsKey);
    if (itemsJson == null) return [];
    
    final List<dynamic> itemsList = json.decode(itemsJson);
    return itemsList.map((item) => ShoppingItem.fromJson(item)).toList();
  }

  static Future<void> saveShoppingItems(List<ShoppingItem> items) async {
    final String itemsJson = json.encode(items.map((item) => item.toJson()).toList());
    await _prefs?.setString(_shoppingItemsKey, itemsJson);
  }

  static Future<void> addShoppingItem(ShoppingItem item) async {
    final items = await getShoppingItems();
    items.add(item);
    await saveShoppingItems(items);
  }

  static Future<void> updateShoppingItem(ShoppingItem updatedItem) async {
    final items = await getShoppingItems();
    final index = items.indexWhere((item) => item.id == updatedItem.id);
    if (index != -1) {
      items[index] = updatedItem;
      await saveShoppingItems(items);
    }
  }

  static Future<void> deleteShoppingItem(String id) async {
    final items = await getShoppingItems();
    items.removeWhere((item) => item.id == id);
    await saveShoppingItems(items);
  }

  static Future<void> clearAllData() async {
    await _prefs?.remove(_foodItemsKey);
    await _prefs?.remove(_shoppingItemsKey);
  }
}
