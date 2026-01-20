import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../core/database/database.dart';

class ScanQrView extends ConsumerStatefulWidget {
  const ScanQrView({super.key});

  @override
  ConsumerState<ScanQrView> createState() => _ScanQrViewState();
}

class _ScanQrViewState extends ConsumerState<ScanQrView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() {
          _isProcessing = true;
        });
        _processQrCode(code);
      }
    }
  }

  void _processQrCode(String rawData) {
    Map<String, dynamic> data = {};
    
    // Try JSON parsing first
    try {
      data = jsonDecode(rawData);
    } catch (e) {
      // Fallback to text parsing (YAML-like)
      final lines = rawData.split('\n');
      for (var line in lines) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join(':').trim();
          data[key] = value;
        }
      }
    }

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid QR Code format')),
      );
      // Resume scanning after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessing = false);
      });
      return;
    }

    _showImportDialog(data);
  }

  void _showImportDialog(Map<String, dynamic> data) {
    // Extract fields with fallbacks
    final idStr = data['id']?.toString() ?? data['!']?.toString() ?? '';
    final longName = data['long_name']?.toString() ?? data['name']?.toString();
    final shortName = data['short_name']?.toString() ?? data['short']?.toString();
    final numVal = data['num'] is int ? data['num'] as int : int.tryParse(data['num']?.toString() ?? '') ?? 0;
    
    // If num is missing but we have !ID, try to parse it from hex? 
    // Usually Meshtastic IDs are integers. '!deadbeef' is hex.
    int nodeId = numVal;
    if (nodeId == 0 && idStr.startsWith('!')) {
       nodeId = int.tryParse(idStr.substring(1), radix: 16) ?? 0;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Import Shared Contact?'),
        content: SingleChildScrollView(
          child: ListBody(
            children: data.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) setState(() => _isProcessing = false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
               _importUser(nodeId, shortName, longName, data);
               Navigator.pop(context); // Close dialog
               // Pop screen or show success?
               // User might want to verify.
               ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Imported $shortName')),
               );
               context.pop(); // Return to Users panel
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
  
  void _importUser(int nodeId, String? shortName, String? longName, Map<String, dynamic> data) {
     if (nodeId == 0) return;
     
     final db = ref.read(appDatabaseProvider);
     
     // Insert Node
     db.insertOrUpdateNode(Node(
       num: nodeId,
       shortName: shortName,
       longName: longName,
       role: data['role']?.toString(),
       model: data['hw_model']?.toString(),
       // We don't have stats yet, set to null
       snr: null,
       battery: null,
       lastHeard: DateTime.now(), // Mark as seen now
     ));
     
     // User requirement: "Also in shared node I want to be able to message and receive messages."
     // Adding to DB enables messaging via UsersPanel and Chat functionality.
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: _handleBarcode,
    );
  }
}
