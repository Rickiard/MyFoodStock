import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/network_sync_service.dart';
import '../services/storage_service.dart';
import '../models/food_item.dart';
import '../models/shopping_item.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  bool _isServerRunning = false;
  String? _localIpAddress;
  final _ipController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLocalIp();
    _isServerRunning = NetworkSyncService.isRunning;
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalIp() async {
    final ip = await NetworkSyncService.getLocalIPAddress();
    setState(() {
      _localIpAddress = ip;
    });
  }

  Future<void> _toggleServer() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_isServerRunning) {
        await NetworkSyncService.stopServer();
        setState(() {
          _isServerRunning = false;
        });
        _showSnackBar('Servidor parado', Colors.orange);
      } else {
        // Start server in background
        NetworkSyncService.startServer().then((_) {
          // Server started
        }).catchError((error) {
          if (mounted) {
            _showSnackBar('Erro ao iniciar servidor: $error', Colors.red);
          }
        });
        
        setState(() {
          _isServerRunning = true;
        });
        _showSnackBar('Servidor iniciado na porta 8080', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Erro: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncWithPeer() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      _showSnackBar('Por favor, insira um endereço IP', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final peerData = await NetworkSyncService.syncWithPeer(ip);
      if (peerData != null) {
        // Merge data from peer
        if (peerData['foodItems'] != null) {
          final foodItems = await StorageService.getFoodItems();
          final peerFoodItems = (peerData['foodItems'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          
          // Simple merge - this could be more sophisticated
          final mergedIds = <String>{};
          final mergedItems = [...foodItems];
          
          for (final item in foodItems) {
            mergedIds.add(item.id);
          }
            for (final peerItem in peerFoodItems) {
            if (!mergedIds.contains(peerItem['id'])) {
              mergedItems.add(FoodItem.fromJson(peerItem));
            }
          }
          
          await StorageService.saveFoodItems(mergedItems);
        }
        
        if (peerData['shoppingItems'] != null) {
          final shoppingItems = await StorageService.getShoppingItems();
          final peerShoppingItems = (peerData['shoppingItems'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList();
          
          // Simple merge
          final mergedIds = <String>{};
          final mergedItems = [...shoppingItems];
          
          for (final item in shoppingItems) {
            mergedIds.add(item.id);
          }
          
          for (final peerItem in peerShoppingItems) {
            if (!mergedIds.contains(peerItem['id'])) {
              mergedItems.add(ShoppingItem.fromJson(peerItem));
            }
          }
          
          await StorageService.saveShoppingItems(mergedItems);
        }
        
        _showSnackBar('Sincronização concluída com sucesso!', Colors.green);
      } else {
        _showSnackBar('Falha ao conectar com o dispositivo', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erro de sincronização: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendDataToPeer() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      _showSnackBar('Por favor, insira um endereço IP', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final foodItems = await StorageService.getFoodItems();
      final shoppingItems = await StorageService.getShoppingItems();
      
      final data = {
        'foodItems': foodItems.map((e) => e.toJson()).toList(),
        'shoppingItems': shoppingItems.map((e) => e.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      final success = await NetworkSyncService.sendDataToPeer(ip, data);
      if (success) {
        _showSnackBar('Dados enviados com sucesso!', Colors.green);
      } else {
        _showSnackBar('Falha ao enviar dados', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erro ao enviar dados: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _copyIpToClipboard() {
    if (_localIpAddress != null) {
      Clipboard.setData(ClipboardData(text: _localIpAddress!));
      _showSnackBar('IP copiado para a área de transferência', Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sincronização'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server Status Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.wifi,
                              color: Colors.purple[700],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Servidor Local',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _isServerRunning ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isServerRunning ? 'Ativo' : 'Inativo',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: _isServerRunning ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        if (_localIpAddress != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text(
                                'IP Local: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_localIpAddress:8080',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _copyIpToClipboard,
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copiar IP',
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _toggleServer,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(_isServerRunning ? Icons.stop : Icons.play_arrow),
                            label: Text(_isServerRunning ? 'Parar Servidor' : 'Iniciar Servidor'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isServerRunning ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Sync with Peer Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sync,
                              color: Colors.blue[700],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Sincronizar com Dispositivo',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],                    ),
                        const SizedBox(height: 16),
                        if (_localIpAddress != null) ...[
                          Row(
                            children: [
                              const Text(
                                'Seu IP: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Expanded(
                                child: Text(
                                  _localIpAddress!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _copyIpToClipboard,
                                icon: const Icon(Icons.copy, size: 18),
                                tooltip: 'Copiar seu IP',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        TextField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'IP do dispositivo',
                            hintText: '192.168.1.100',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.computer),
                          ),
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _syncWithPeer,
                                icon: const Icon(Icons.sync),
                                label: const Text('Sincronizar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _sendDataToPeer,
                                icon: const Icon(Icons.send),
                                label: const Text('Enviar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Instructions Card
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.green[700],
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Como Usar',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '1. Certifique-se de que ambos os dispositivos estão na mesma rede Wi-Fi\n\n'
                          '2. Inicie o servidor em um dos dispositivos\n\n'
                          '3. No outro dispositivo, insira o IP mostrado e toque em "Sincronizar"\n\n'
                          '4. Os dados serão mesclados automaticamente',
                          style: TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );  }
}
