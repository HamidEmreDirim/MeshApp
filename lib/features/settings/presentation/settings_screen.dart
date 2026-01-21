import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mesh_app/features/auth/presentation/auth_provider.dart';
import '../../../core/services/bluetooth_service.dart';
import 'channel_settings_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
    final nodesAsync = ref.watch(nodesProvider);
    
    final myId = myNodeInfoAsync.value?.myNodeNum;
    
    // Find my full Node object if available
    final myNode = (myId != null && nodesAsync.hasValue) 
        ? nodesAsync.value![myId] 
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          if (myId != null)
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                       children: [
                          const Icon(Icons.perm_device_information, size: 40, color: Colors.blue),
                          const SizedBox(width: 16),
                          Expanded(
                             child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                   Text(
                                     myNode?.user.longName ?? "Unknown Node",
                                     style: Theme.of(context).textTheme.titleLarge,
                                   ),
                                   Text(
                                     myNode?.user.shortName ?? "???",
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                                   ),
                                ],
                             ),
                          ),
                       ],
                    ),
                    const Divider(),
                    const Text("Identity", style: TextStyle(fontWeight: FontWeight.bold)),
                    SelectionArea(
                       child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                           Text("ID (Int): $myId"),
                           Text("ID (Hex): !${myId.toRadixString(16).padLeft(8, '0').substring(4)}"),
                        ],
                       ),
                    ),
                    if (myNode != null) ...[
                        const SizedBox(height: 16),
                        const Text("Status", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             _buildInfoItem(Icons.battery_std, "Battery", "${myNode.deviceMetrics.hasBatteryLevel() ? myNode.deviceMetrics.batteryLevel : 'N/A'}%"),
                             _buildInfoItem(Icons.admin_panel_settings, "Role", myNode.user.role.name.replaceAll('Config_DeviceConfig_Role.', '')),
                             _buildInfoItem(Icons.hardware, "Model", myNode.user.hwModel.name),
                          ],
                        ),
                     ]
                  ],
                ),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.settings_input_antenna),
            title: const Text('Channel Configuration'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChannelSettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
     return Column(
       children: [
          Icon(icon, color: Colors.grey),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
       ],
     );
  }
}
