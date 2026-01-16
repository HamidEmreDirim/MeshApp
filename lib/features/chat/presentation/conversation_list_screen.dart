import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import '../../../core/services/bluetooth_service.dart';
import '../../../gen/proto/meshtastic/mesh.pb.dart';

class ConversationListScreen extends ConsumerWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodesAsync = ref.watch(nodesProvider);
    final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
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
              // Primary Channel (Broadcast)
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Icon(Icons.public),
                ),
                title: const Text("Primary Channel"),
                subtitle: const Text("Broadcast to everyone"),
                onTap: () {
                   context.push('/chat/detail', extra: {
                     'nodeId': 4294967295, // 0xFFFFFFFF
                     'name': 'Primary Channel',
                   });
                },
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
                     });
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
