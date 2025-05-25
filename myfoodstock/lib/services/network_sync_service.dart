import 'dart:convert';
import 'dart:io';
import 'dart:async';
import '../models/food_item.dart';
import '../models/shopping_item.dart';
import 'storage_service.dart';

class NetworkSyncService {
  static const int _defaultPort = 8080;
  static HttpServer? _server;
  static bool _isRunning = false;
  static Timer? _broadcastTimer;

  static bool get isRunning => _isRunning;

  static Future<void> startServer({int port = _defaultPort}) async {
    if (_isRunning) return;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _isRunning = true;
      
      print('Servidor iniciado na porta $port');
      
      await for (HttpRequest request in _server!) {
        _handleRequest(request);
      }
    } catch (e) {
      print('Erro ao iniciar servidor: $e');
      _isRunning = false;
    }
  }

  static Future<void> stopServer() async {
    if (!_isRunning) return;
    
    _broadcastTimer?.cancel();
    await _server?.close();
    _server = null;
    _isRunning = false;
    print('Servidor parado');
  }

  static void _handleRequest(HttpRequest request) async {
    // Configurar CORS
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      return;
    }

    try {
      switch (request.uri.path) {
        case '/food-items':
          await _handleFoodItems(request);
          break;
        case '/shopping-items':
          await _handleShoppingItems(request);
          break;
        case '/sync':
          await _handleSync(request);
          break;
        default:
          request.response.statusCode = 404;
          await request.response.close();
      }
    } catch (e) {
      request.response.statusCode = 500;
      request.response.write('Erro interno: $e');
      await request.response.close();
    }
  }

  static Future<void> _handleFoodItems(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
        final items = await StorageService.getFoodItems();
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode(items.map((e) => e.toJson()).toList()));
        break;
      case 'POST':
        final body = await utf8.decoder.bind(request).join();
        final data = json.decode(body) as List;
        final items = data.map((e) => FoodItem.fromJson(e)).toList();
        await StorageService.saveFoodItems(items);
        request.response.statusCode = 200;
        break;
    }
    await request.response.close();
  }

  static Future<void> _handleShoppingItems(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
        final items = await StorageService.getShoppingItems();
        request.response.headers.contentType = ContentType.json;
        request.response.write(json.encode(items.map((e) => e.toJson()).toList()));
        break;
      case 'POST':
        final body = await utf8.decoder.bind(request).join();
        final data = json.decode(body) as List;
        final items = data.map((e) => ShoppingItem.fromJson(e)).toList();
        await StorageService.saveShoppingItems(items);
        request.response.statusCode = 200;
        break;
    }
    await request.response.close();
  }

  static Future<void> _handleSync(HttpRequest request) async {
    if (request.method == 'GET') {
      final foodItems = await StorageService.getFoodItems();
      final shoppingItems = await StorageService.getShoppingItems();
      
      final syncData = {
        'foodItems': foodItems.map((e) => e.toJson()).toList(),
        'shoppingItems': shoppingItems.map((e) => e.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      request.response.headers.contentType = ContentType.json;
      request.response.write(json.encode(syncData));
    } else if (request.method == 'POST') {
      final body = await utf8.decoder.bind(request).join();
      final data = json.decode(body);
      
      if (data['foodItems'] != null) {
        final foodItems = (data['foodItems'] as List)
            .map((e) => FoodItem.fromJson(e)).toList();
        await StorageService.saveFoodItems(foodItems);
      }
      
      if (data['shoppingItems'] != null) {
        final shoppingItems = (data['shoppingItems'] as List)
            .map((e) => ShoppingItem.fromJson(e)).toList();
        await StorageService.saveShoppingItems(shoppingItems);
      }
      
      request.response.statusCode = 200;
    }
    await request.response.close();
  }

  static Future<Map<String, dynamic>?> syncWithPeer(String ipAddress, {int port = _defaultPort}) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('http://$ipAddress:$port/sync'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final body = await utf8.decoder.bind(response).join();
        final data = json.decode(body);
        return data;
      }
    } catch (e) {
      print('Erro ao sincronizar com $ipAddress: $e');
    }
    return null;
  }

  static Future<bool> sendDataToPeer(String ipAddress, Map<String, dynamic> data, {int port = _defaultPort}) async {
    try {
      final client = HttpClient();
      final request = await client.postUrl(Uri.parse('http://$ipAddress:$port/sync'));
      request.headers.contentType = ContentType.json;
      request.write(json.encode(data));
      
      final response = await request.close();
      return response.statusCode == 200;
    } catch (e) {
      print('Erro ao enviar dados para $ipAddress: $e');
      return false;
    }
  }

  static Future<String?> getLocalIPAddress() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      print('Erro ao obter IP local: $e');
    }
    return null;
  }
}
