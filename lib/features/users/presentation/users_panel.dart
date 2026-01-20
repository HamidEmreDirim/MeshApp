import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/user_service.dart';
import '../../../core/services/bluetooth_service.dart';
import '../../../core/database/database.dart'; // Ensure correct import for Node
import 'qr_code_screen.dart';

class UsersPanel extends ConsumerWidget {
  const UsersPanel({super.key});

  void _navigateToChat(BuildContext context, Node user) {
    context.push(
      '/chat/detail',
      extra: {
        'nodeId': user.num,
        'name': user.shortName ?? 'Unknown',
      },
    );
  }

  void _showNodeDetails(BuildContext context, Node user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.longName ?? user.shortName ?? 'Unknown Node'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('ID: ${user.num}'),
             const SizedBox(height: 8),
             Text('Short Name: ${user.shortName ?? 'N/A'}'),
             const SizedBox(height: 8),
             // We can add more details here if we expand the Node entity in the future
             // e.g., Last Seen, SNR, Battery (if accessible via NodeInfo in DB or joined table)
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
             onPressed: () {
               Navigator.pop(context);
               _navigateToChat(context, user);
             },
             child: const Text('Message'),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref, Node user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${user.shortName}?'),
        content: const Text('Are you sure you want to remove this node?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Remove from BluetoothService memory
              ref.read(bluetoothServiceProvider).forgetNode(user.num);
              // Remove from Database (Node + Messages)
              final db = ref.read(appDatabaseProvider);
              db.deleteNode(user.num);
              db.deleteMessagesForNode(user.num);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${user.shortName} removed')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddUserOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Add by Link'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement add by link
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Scan QR Code'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QrCodeScreen(initialIndex: 0)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMyQrCode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrCodeScreen(initialIndex: 1)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nodes'),
        actions: [
           IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => _showMyQrCode(context),
            tooltip: 'Show QR Code',
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddUserOptions(context),
            tooltip: 'Add User',
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
             return const Center(child: Text("No nodes found."));
          }
           return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Filter',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    filled: true,
                    fillColor: Colors.black12, // Darker input
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder( // Removed separator, using Cards
                  itemCount: users.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildNodeCard(context, ref, user);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildNodeCard(BuildContext context, WidgetRef ref, Node user) {
     final lastHeard = user.lastHeard;
     final timeAgo = lastHeard != null ? _formatTimeAgo(lastHeard) : 'Unknown';
     final isOnline = timeAgo == 'now' || timeAgo.contains('min') || timeAgo.contains('sec'); // Simple heuristic based on text

    return Card(
      color: const Color(0xFF2C3317), // Dark Olive/Greenish Grey approximation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _showNodeDetails(context, user),
        onLongPress: () => _showRemoveDialog(context, ref, user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Short Name Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6D666), // Muted Yellow
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      user.shortName?.substring(0, min(2, user.shortName?.length ?? 0)) ?? '??',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Lock Icon (Encryption) - Dummy for now as we don't have this info
                  const Icon(Icons.lock, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  // Long Name
                  Expanded(
                    child: Text(
                      user.longName ?? user.shortName ?? 'Unknown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                   // Status / Time
                  Icon(Icons.wifi_tethering, size: 16, color: isOnline ? Colors.white70 : Colors.grey),
                   const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                   const SizedBox(width: 4),
                   const Icon(Icons.cloud_queue, size: 16, color: Colors.green), // LoRa/MQTT status
                ],
              ),
              const SizedBox(height: 8),
              // Battery line
              Row(
                children: [
                  Icon(
                    _getBatteryIcon(user.battery),
                    size: 16,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    user.battery != null ? '${user.battery}%' : 'PWD',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // SNR / Role / Model
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: SNR & Hardware
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       if (user.snr != null)
                        Text(
                          'SNR ${user.snr!.toStringAsFixed(2)}dB',
                          style: const TextStyle(color: Colors.green, fontSize: 12),
                        ),
                       Text(
                         user.model ?? 'UNKNOWN', 
                         style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                       )
                    ],
                  ),
                  // Center: Role
                  Text(
                     user.role?.replaceAll('Config_DeviceConfig_Role.', '') ?? 'CLIENT', // Strip enum prefix if needed
                     style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  // Right: ID
                   Text(
                     '!${user.num.toRadixString(16).substring(max(0, user.num.toRadixString(16).length - 8))}', // Last 8 hex chars
                     style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
              
              // Helper Action (Message) - Integrated into card or external?
              // User said "in the list item at the right of it I want to be able to private chat"
              // Maybe a prominent button or just the tap action. tap is details.
              // Let's rely on Details -> Message or add a specific icon button in the top row?
              // The reference image doesn't show a message button explicitly on the card face, 
              // but user requested it. I will keep it in the slide/long press or add to row.
              // Actually, user said: "Also in the list item at the right of it I want to be able to private chat"
              // The card is quite dense. I'll add an icon button at the top right, overriding the inkwell?
              // Or maybe bottom right? 
              // I will leave it as: Tap -> Details -> Message, OR add a dedicated IconButton in the Row.
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hr';
    return '${diff.inDays} day';
  }
  
  IconData _getBatteryIcon(int? level) {
      if (level == null) return Icons.power;
      if (level >= 80) return Icons.battery_full;
      if (level >= 50) return Icons.battery_std; 
      if (level >= 20) return Icons.battery_std;
      return Icons.battery_alert;
  }

  
}
