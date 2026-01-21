import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:gap/gap.dart';

import '../../../../core/services/bluetooth_service.dart';

class ShareLocationSheet extends ConsumerStatefulWidget {
  final LatLng location;

  const ShareLocationSheet({super.key, required this.location});

  @override
  ConsumerState<ShareLocationSheet> createState() => _ShareLocationSheetState();
}

class _ShareLocationSheetState extends ConsumerState<ShareLocationSheet> {
  final _noteController = TextEditingController();
  int? _selectedNodeId = 4294967295; // Default to Broadcast
  
  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nodesAsync = ref.watch(nodesProvider);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8, // Taller sheet
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                Text(
                  "Share Location",
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: _handleSend,
                  child: const Text("Share", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Location Preview / Note
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                           borderRadius: BorderRadius.circular(12),
                         ),
                         child: Row(
                           children: [
                             Icon(Icons.location_on, color: theme.colorScheme.primary),
                             const Gap(12),
                             Expanded(
                               child: Column(
                                 crossAxisAlignment: CrossAxisAlignment.start,
                                 children: [
                                   Text(
                                     "Selected Location", 
                                     style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary)
                                   ),
                                   Text(
                                     "${widget.location.latitude.toStringAsFixed(5)}, ${widget.location.longitude.toStringAsFixed(5)}",
                                     style: theme.textTheme.bodyMedium,
                                   ),
                                 ],
                               ),
                             ),
                           ],
                         ),
                      ),
                      const Gap(16),
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          hintText: "Add a note (e.g. Meet here)",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: 3,
                        minLines: 1,
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),
                
                // Recipient Lists
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    "CHANNELS",
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
                _buildRecipientItem(
                  id: 4294967295, 
                  name: "Primary Channel", 
                  subtitle: "Broadcast to all users",
                  icon: Icons.public,
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    "USERS",
                    style: theme.textTheme.labelSmall?.copyWith(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ),
                
                if (nodesAsync.hasValue && nodesAsync.value != null)
                  ...nodesAsync.value!.values.map((node) {
                     final name = node.user.longName.isNotEmpty 
                        ? node.user.longName 
                        : (node.user.shortName.isNotEmpty ? node.user.shortName : "Node ${node.num}");
                     final subtitle = node.user.shortName.isNotEmpty ? node.user.shortName : "ID: ${node.num}";
                     
                     return _buildRecipientItem(
                       id: node.num,
                       name: name,
                       subtitle: subtitle,
                       icon: Icons.person_outline,
                     );
                  })
                else if (nodesAsync.isLoading)
                   const Padding(
                     padding: EdgeInsets.all(16),
                     child: Center(child: CircularProgressIndicator()),
                   )
                else
                   Padding(
                     padding: const EdgeInsets.all(16),
                     child: Text("No users found", style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                   ),
                   
                const Gap(40), // Bottom padding
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecipientItem({
    required int id, 
    required String name, 
    String? subtitle, 
    required IconData icon
  }) {
    final isSelected = _selectedNodeId == id;
    final theme = Theme.of(context);
    
    return ListTile(
      onTap: () {
        setState(() {
          _selectedNodeId = id;
        });
      },
      leading: CircleAvatar(
        backgroundColor: isSelected ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest,
        child: Icon(icon, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
      ),
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: isSelected 
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : null,
    );
  }

  Future<void> _handleSend() async {
    final note = _noteController.text.trim();
    final lat = widget.location.latitude;
    final lon = widget.location.longitude;
    
    final message = "Shared Location: $lat, $lon\n$note".trim();
    final targetId = _selectedNodeId ?? 4294967295;
    
    try {
      final bluetooth = ref.read(bluetoothServiceProvider);
      await bluetooth.sendMessageTo(message, targetId);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location shared successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error sending location: $e")),
        );
      }
    }
  }
}
