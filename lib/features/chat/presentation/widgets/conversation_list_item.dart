import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/bluetooth_service.dart';
import '../../../../core/database/database.dart';

class ConversationListItem extends ConsumerWidget {
  final Node node;

  const ConversationListItem({
    super.key,
    required this.node,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = node.longName?.isNotEmpty == true 
                    ? node.longName! 
                    : node.shortName?.isNotEmpty == true 
                        ? node.shortName!
                        : "!${node.num.toRadixString(16).padLeft(8,'0').substring(4)}";
    
    final unreadCount = ref.watch(unreadMessageCountForNodeProvider(node.num)).asData?.value ?? 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text(node.shortName?.isNotEmpty == true ? node.shortName!.substring(0,2).toUpperCase() : "?"),
      ),
      title: Text(name),
      subtitle: Text("ID: !${node.num.toRadixString(16).padLeft(8, '0').substring(4)}"),
      trailing: unreadCount > 0 
          ? Badge.count(count: unreadCount, backgroundColor: Theme.of(context).colorScheme.primary, textColor: Theme.of(context).colorScheme.onPrimary) 
          : null,
      onTap: () {
        context.push('/chat/detail', extra: {
          'nodeId': node.num,
          'name': name,
          'user_short_name': node.shortName, 
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
  }
}
