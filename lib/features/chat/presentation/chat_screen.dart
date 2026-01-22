// import 'dart:convert'; // Removed unused import
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/services/bluetooth_service.dart';


import '../../../core/database/database.dart'; 
import 'widgets/chat_bubble.dart';

class ChatScreen extends HookConsumerWidget {
  final int targetNodeId;
  final String targetName;
  final int channelIndex; // Add channelIndex

  const ChatScreen({
    super.key, 
    required this.targetNodeId,
    required this.targetName,
    this.channelIndex = 0, // Default to 0
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bluetooth = ref.watch(bluetoothServiceProvider);
    final db = ref.watch(appDatabaseProvider);
    final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
    final myId = myNodeInfoAsync.value?.myNodeNum ?? 0;
    
    // Stream messages from DB
    final messagesStream = useMemoized(() => db.watchMessagesForNode(targetNodeId, myId, channelIndex: channelIndex), [targetNodeId, myId, channelIndex]);
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

      bluetooth.sendMessageTo(text, targetNodeId, channelIndex: channelIndex);
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
                    
                    return ChatBubble(
                      content: content,
                      isMe: isMe, 
                      timestamp: msg.timestamp,
                      senderName: _getShortId(msg.fromId),
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
