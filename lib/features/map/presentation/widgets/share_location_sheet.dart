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
    
    // Force usage of light-friendly text colors since the background is hardcoded white
    final titleStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(color: Colors.black87);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold);

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
                  style: titleStyle,
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
                           color: Colors.grey[100],
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.grey[300]!)
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
                                     style: bodyStyle,
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
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          hintText: "Add a note (e.g. Meet here)",
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
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
                    style: labelStyle,
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
                    style: labelStyle,
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
                     child: Text("No users found", style: bodyStyle?.copyWith(color: Colors.grey)),
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
        backgroundColor: isSelected ? theme.colorScheme.primaryContainer : Colors.grey[200],
        child: Icon(icon, color: isSelected ? theme.colorScheme.primary : Colors.grey[700]),
      ),
      title: Text(name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: Colors.black)),
      subtitle: subtitle != null ? Text(subtitle, style: TextStyle(color: Colors.grey[600])) : null,
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
