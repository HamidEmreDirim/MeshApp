import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import '../../../../gen/proto/meshtastic/channel.pb.dart';

class ScanChannelQrScreen extends StatefulWidget {
  const ScanChannelQrScreen({super.key});

  @override
  State<ScanChannelQrScreen> createState() => _ScanChannelQrScreenState();
}

class _ScanChannelQrScreenState extends State<ScanChannelQrScreen> {
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
    // Expected formats:
    // 1. https://meshtastic.org/e/#<base64_proto>
    // 2. <base64_proto>
    
    String base64Data = rawData;
    if (rawData.contains('#')) {
      base64Data = rawData.split('#').last;
    }
    
    // Base64URL cleanup
    base64Data = base64Data.replaceAll('-', '+').replaceAll('_', '/');
    // Add padding if needed
    while (base64Data.length % 4 != 0) {
      base64Data += '=';
    }

    try {
      final bytes = base64Decode(base64Data);
      // Try to parse as Channel
      // Note: This assumes the QR contains a single Channel protobuf. 
      // Sometimes it's a ChannelSet or other structure. 
      // For now we will try parsing as Channel.
      
      final channel = Channel.fromBuffer(bytes);
      
      // If successful, return the channel
      context.pop(channel);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to parse channel QR: $e')),
      );
      // Resume scanning
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isProcessing = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Channel QR")),
      body: MobileScanner(
        controller: _controller,
        onDetect: _handleBarcode,
      ),
    );
  }
}
