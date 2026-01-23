import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../../core/services/bluetooth_service.dart';
import '../../../core/database/database.dart';


import 'widgets/channel_list_item.dart';
import 'widgets/conversation_list_item.dart';

final allNodesProvider = StreamProvider<List<Node>>((ref) {
  return ref.watch(appDatabaseProvider).watchAllNodes();
});

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(allNodesProvider);
    final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
    final channelsAsync = ref.watch(channelsProvider); // Watch channels
    final myId = myNodeInfoAsync.value?.myNodeNum ?? 0;
    

    


    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        centerTitle: false,
      ),
      body: nodesAsync.when(
        data: (nodes) {
          // final nodes = nodesMap.values.toList(); // No map anymore
          
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
                             'role': 'PRIMARY',
                           });
                        },
                      );
                   }
                   return Column(
                     children: channels.map((channel) => ChannelListItem(channel: channel)).toList(),
                   );
                 },
                 loading: () => const LinearProgressIndicator(), 
                 error: (_, __) => const SizedBox(),
              ),
              const Divider(),
              if (nodes.isEmpty)
                 const Padding(
                   padding: EdgeInsets.all(16.0),
                   child: Center(child: Text("No nodes discovered yet.")),
                 ),

              // Discovered Nodes
              ...nodes.where((n) => n.num != myId).map((node) => ConversationListItem(node: node)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

