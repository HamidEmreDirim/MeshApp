// import 'dart:convert'; // Removed unused import
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/services/bluetooth_service.dart';


import '../../../core/database/database.dart'; // Add import if not present, checking imports separately

class ChatScreen extends HookConsumerWidget {
  final int targetNodeId;
  final String targetName;

  const ChatScreen({
    super.key, 
    required this.targetNodeId,
    required this.targetName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetooth = ref.watch(bluetoothServiceProvider);
    final db = ref.watch(appDatabaseProvider);
    final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
    final myId = myNodeInfoAsync.value?.myNodeNum ?? 0;
    
    // Stream messages from DB
    final messagesStream = useMemoized(() => db.watchMessagesForNode(targetNodeId, myId), [targetNodeId, myId]);
    final messagesAsync = useStream(messagesStream);
    
    final textController = useTextEditingController();
    
    // Auto-scroll to bottom

    
    useEffect(() {
      if (messagesAsync.hasData && messagesAsync.data!.isNotEmpty) {
        // scrollController.jumpTo(scrollController.position.maxScrollExtent);
        // Or animate, maybe better to just jump on load
      }
      return null;
    }, [messagesAsync.data?.length]);

    void handleSend() {
      final text = textController.text;
      if (text.trim().isEmpty) return;

      bluetooth.sendMessageTo(text, targetNodeId);
      // DB persistence handled in service
      textController.clear();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(targetName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () {
               bluetooth.disconnect();
            },
            tooltip: "Disconnect",
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                if (messagesAsync.hasError) {
                  return Center(child: Text('Error: ${messagesAsync.error}'));
                }
                if (!messagesAsync.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = messagesAsync.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text("No messages here yet."));
                }
                
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.isMe;
                    
                    final content = msg.content;
                    
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe && targetNodeId == 4294967295) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 12, bottom: 2),
                                child: Text(
                                  _getShortId(msg.fromId),
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isMe 
                                  ? Theme.of(context).colorScheme.primaryContainer 
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                                  bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                content,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                   color: isMe 
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            Padding(
                               padding: const EdgeInsets.only(left: 4, right: 4, top: 2),
                               child: Text(
                                 "${msg.timestamp.hour.toString().padLeft(2,'0')}:${msg.timestamp.minute.toString().padLeft(2,'0')}",
                                 style: Theme.of(context).textTheme.labelSmall,
                               ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: "Type a message...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => handleSend(),
                  ),
                ),
                const Gap(8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: handleSend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper for Short ID
String _getShortId(int nodeId) {
  if (nodeId == 0) return "Me";
  // Convert to hex and take last 4 chars (standard Meshtastic Short ID)
  // Node ID is uint32. 
  final hex = nodeId.toRadixString(16).padLeft(8, '0');
  return "!${hex.substring(hex.length - 4)}";
}
