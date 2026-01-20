import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/bluetooth_service.dart';
import '../../../core/database/database.dart';

class ShareQrView extends ConsumerWidget {
  const ShareQrView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
    final db = ref.watch(appDatabaseProvider);

    return myNodeInfoAsync.when(
        data: (myNodeInfo) {
          if (myNodeInfo == null) {
            return const Center(child: Text("Node info not available yet. Connect to device."));
          }

          // We have the ID, let's look up the full node details from DB to get name, etc.
          return StreamBuilder<Node?>(
            stream: db.watchNode(myNodeInfo.myNodeNum),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data == null) {
                 return const Center(child: Text("Loading node details..."));
              }
              
              final user = snapshot.data!;
              final qrData = _generateQrData(user);

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 250.0,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        user.longName ?? user.shortName ?? 'Unknown',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.shortName ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        '!${user.num.toRadixString(16)}',
                         style: const TextStyle(fontFamily: 'monospace'),
                      ),
                       const SizedBox(height: 32),
                      const Text(
                        "Scan this code on another device to add this node.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      );
  }

  String _generateQrData(Node user) {
    // Creating a JSON payload for the QR code
    final Map<String, dynamic> data = {
      'id': '!${user.num.toRadixString(16)}',
      'num': user.num,
      'long_name': user.longName,
      'short_name': user.shortName,
      'macaddr': '', // Not readily available in Node table, but maybe not critical
      'hw_model': user.model,
      'role': user.role,
      // Add other fields as per the screenshot if available
    };
    return jsonEncode(data);
  }
}
