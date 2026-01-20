import 'package:flutter/material.dart';
import 'scan_qr_screen.dart';
import 'share_qr_screen.dart';

class QrCodeScreen extends StatefulWidget {
  final int initialIndex;
  
  const QrCodeScreen({super.key, this.initialIndex = 0});

  @override
  State<QrCodeScreen> createState() => _QrCodeScreenState();
}

class _QrCodeScreenState extends State<QrCodeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Config'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan Code'),
            Tab(icon: Icon(Icons.qr_code), text: 'My Code'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          ScanQrView(), // We will rename ScanQrScreen to this
          ShareQrView(), // We will rename ShareQrScreen to this
        ],
      ),
    );
  }
}
