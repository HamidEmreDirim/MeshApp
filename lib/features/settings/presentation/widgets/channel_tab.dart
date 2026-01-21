import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../gen/proto/meshtastic/channel.pb.dart';

class ChannelTab extends StatefulWidget {
  final int index;
  final Channel channel;
  final Function(Channel) onSave;

  const ChannelTab({
    super.key,
    required this.index,
    required this.channel,
    required this.onSave,
  });

  @override
  State<ChannelTab> createState() => _ChannelTabState();
}

class _ChannelTabState extends State<ChannelTab> with AutomaticKeepAliveClientMixin {
  late TextEditingController _nameController;
  late TextEditingController _pskController;
  late Channel_Role _role;
  bool _obscurePsk = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.channel.settings.name);
    _pskController = TextEditingController(text: _formatPsk(widget.channel.settings.psk));
    _role = widget.channel.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pskController.dispose();
    super.dispose();
  }

  String _formatPsk(List<int> psk) {
    if (psk.isEmpty) return "";
    return base64Encode(psk);
  }

  List<int> _parsePsk(String psk) {
    if (psk.isEmpty) return [];
    try {
      return base64Decode(psk);
    } catch (e) {
      return []; // Invalid base64
    }
  }

  void _generatePsk() {
    final random = Random.secure();
    // Standard AES256 key is 32 bytes
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    setState(() {
      _pskController.text = base64Encode(values);
    });
  }

  void _save() {
    // Clone the channel to avoid mutating the original prop directly/unintentionally
    final newChannel = widget.channel.deepCopy();
    newChannel.role = _role;
    
    // Ensure settings object exists
    if (!newChannel.hasSettings()) {
      newChannel.settings = ChannelSettings();
    }
    
    newChannel.settings.name = _nameController.text;
    newChannel.settings.psk = _parsePsk(_pskController.text);

    widget.onSave(newChannel);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Primary channel (index 0) has restricted roles usually, but per proto:
    // "only one channel can be marked as primary"
    // We will let the user select, device might reject.
    // However, usually index 0 is Primary.
    // Let's allow configuration as requested.
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Role"),
          InputDecorator(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Channel_Role>(
                value: _role,
                isDense: true,
                items: const [
                  DropdownMenuItem(
                    value: Channel_Role.DISABLED,
                    child: Text("DISABLED"),
                  ),
                  DropdownMenuItem(
                    value: Channel_Role.PRIMARY,
                    child: Text("PRIMARY"),
                  ),
                  DropdownMenuItem(
                    value: Channel_Role.SECONDARY,
                    child: Text("SECONDARY"),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _role = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
           _buildSectionHeader("Name"),
           const Text(
            "A unique name for the channel <12 bytes, leave blank for default",
            style: TextStyle(fontSize: 12, color: Colors.grey),
           ),
           const SizedBox(height: 8),
           TextFormField(
             controller: _nameController,
             decoration: const InputDecoration(
               border: OutlineInputBorder(),
               hintText: "Channel Name",
             ),
             maxLength: 12,
             inputFormatters: [
               LengthLimitingTextInputFormatter(12),
             ],
           ),

           const SizedBox(height: 16),
           _buildSectionHeader("Pre-Shared Key"),
           const Text(
            "AES-256 Key (Base64 Encoded)",
            style: TextStyle(fontSize: 12, color: Colors.grey),
           ),
           const SizedBox(height: 8),
           Row(
             children: [
               Expanded(
                 child: TextFormField(
                   controller: _pskController,
                   obscureText: _obscurePsk,
                   decoration: InputDecoration(
                     border: const OutlineInputBorder(),
                     hintText: "Empty (0-bit)",
                     suffixIcon: IconButton(
                       icon: Icon(_obscurePsk ? Icons.visibility : Icons.visibility_off),
                       onPressed: () {
                         setState(() {
                           _obscurePsk = !_obscurePsk;
                         });
                       },
                     ),
                   ),
                 ),
               ),
               const SizedBox(width: 8),
               ElevatedButton(
                 onPressed: _generatePsk,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.green, // Matching the web UI somewhat
                   foregroundColor: Colors.white,
                 ),
                 child: const Text("Generate"),
               ),
             ],
           ),
           const SizedBox(height: 24),
           SizedBox(
             width: double.infinity,
             child: ElevatedButton.icon(
               onPressed: _save,
               icon: const Icon(Icons.save),
               label: const Text("Save Channel"),
               style: ElevatedButton.styleFrom(
                 padding: const EdgeInsets.symmetric(vertical: 16),
               ),
             ),
           ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
