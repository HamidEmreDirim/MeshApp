import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../core/services/bluetooth_service.dart';
import '../../../core/database/database.dart';


class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(nodesProvider);
    final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
    final channelsAsync = ref.watch(channelsProvider); // Watch channels
    final myId = myNodeInfoAsync.value?.myNodeNum ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: false,
      ),
      body: nodesAsync.when(
        data: (nodesMap) {
          final nodes = nodesMap.values.toList();
          
          return ListView(
            children: [
              // Configured Channels
              channelsAsync.when(
                 data: (channels) {
                   if (channels.isEmpty) {
                      // Fallback if no channels fetched yet, show default Primary
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          child: const Icon(Icons.public),
                        ),
                        title: const Text("Primary Channel"),
                        subtitle: const Text("Broadcast (Default)"),
                        onTap: () {
                           context.push('/chat/detail', extra: {
                             'nodeId': 4294967295, 
                             'name': 'Primary Channel',
                             'channelIndex': 0,
                           });
                        },
                      );
                   }
                   return Column(
                     children: channels.map((channel) {
                       final name = channel.name.isNotEmpty ? channel.name : "Channel ${channel.index}";
                       return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          child: const Icon(Icons.tag), // Tag icon for channels
                        ),
                        title: Text(name),
                        subtitle: Text(channel.role ?? "UNKNOWN"),
                        onTap: () {
                           context.push('/chat/detail', extra: {
                             'nodeId': 4294967295, // Broadcast ID for channel messages mostly
                             'name': name,
                             'channelIndex': channel.index, // Pass channel index
                           });
                        },
                       );
                     }).toList(),
                   );
                 },
                 loading: () => const LinearProgressIndicator(), 
                 error: (_,__) => const SizedBox(),
              ),
              const Divider(),
              if (nodes.isEmpty)
                 const Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Center(child: Text("No nodes discovered yet.")),
                 ),

              // Discovered Nodes
              ...nodes.where((n) => n.num != myId).map((node) {
                 final name = node.user.longName.isNotEmpty 
                    ? node.user.longName 
                    : node.user.shortName.isNotEmpty 
                        ? node.user.shortName
                        : "!${node.num.toRadixString(16).padLeft(8,'0').substring(4)}";
                        
                 return ListTile(
                   leading: CircleAvatar(
                     backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                     child: Text(node.user.shortName.isNotEmpty ? node.user.shortName.substring(0,2).toUpperCase() : "?"),
                   ),
                   title: Text(name),
                   subtitle: Text("ID: !${node.num.toRadixString(16).padLeft(8, '0').substring(4)}"),
                   onTap: () {
                     context.push('/chat/detail', extra: {
                       'nodeId': node.num,
                       'name': name,
                       'user_short_name': node.user.shortName, // pass for avatar if needed
                     });
                   },
                   onLongPress: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text("Delete chat with $name?"),
                          content: const Text("This will permanently delete the conversation history."),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                            TextButton(
                              onPressed: () {
                                 ref.read(appDatabaseProvider).deleteMessagesForNode(node.num);
                                 Navigator.pop(context);
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Conversation deleted")));
                              },
                              child: const Text("Delete", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                   },
                 );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
