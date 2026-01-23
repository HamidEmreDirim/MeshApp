import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/bluetooth_service.dart';
import '../../../../core/database/database.dart';

class ChannelListItem extends ConsumerWidget {
  final Channel channel;

  const ChannelListItem({
    super.key,
    required this.channel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = channel.name.isNotEmpty ? channel.name : "Channel ${channel.index}";
    final unreadCount = ref.watch(unreadMessageCountForChannelProvider(channel.index)).asData?.value ?? 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.tag), 
      ),
      title: Text(name),
      subtitle: Text(channel.role ?? "UNKNOWN"),
      trailing: unreadCount > 0 
        ? Badge.count(count: unreadCount, backgroundColor: Theme.of(context).colorScheme.error, textColor: Theme.of(context).colorScheme.onError) 
        : null,
      onTap: () {
          context.push('/chat/detail', extra: {
            'nodeId': 4294967295, 
            'name': name,
            'channelIndex': channel.index, 
          });
      },
    );
  }
}
