import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:gap/gap.dart';

import '../../../map/application/map_provider.dart';

class ChatBubble extends ConsumerWidget {
  final String content;
  final bool isMe;
  final DateTime timestamp;
  final String? senderName;

  const ChatBubble({
    super.key,
    required this.content,
    required this.isMe,
    required this.timestamp,
    this.senderName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if it's a shared location message
    final locationData = _parseLocationMessage(content);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isMe && senderName != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 2),
                child: Text(
                  senderName!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            if (locationData != null)
              _buildLocationCard(context, ref, locationData)
            else
              _buildTextBubble(context),

            Padding(
               padding: const EdgeInsets.only(left: 4, right: 4, top: 2),
               child: Text(
                 "${timestamp.hour.toString().padLeft(2,'0')}:${timestamp.minute.toString().padLeft(2,'0')}",
                 style: Theme.of(context).textTheme.labelSmall,
               ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextBubble(BuildContext context) {
    return Container(
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
    );
  }

  Widget _buildLocationCard(BuildContext context, WidgetRef ref, _LocationMessageData data) {
    return InkWell(
      onTap: () {
        // Set the shared location target
        ref.read(sharedLocationTargetProvider.notifier).setLocation(data.latLng);
        // Navigation logic: Go to Map Tab
        context.go('/map'); 
      },
      child: Container(
        decoration: BoxDecoration(
          color: isMe 
            ? Theme.of(context).colorScheme.primaryContainer 
            : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant, 
            width: 1
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / Icon
            Container(
              color: isMe 
                 ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                 : Theme.of(context).colorScheme.surfaceTint.withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: Theme.of(context).colorScheme.primary),
                  const Gap(8),
                  Text(
                    "Shared Location",
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data.note.isNotEmpty) ...[
                    Text(
                      data.note,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(8),
                  ],
                  Text(
                    "${data.latLng.latitude.toStringAsFixed(5)}, ${data.latLng.longitude.toStringAsFixed(5)}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        "Tap to view",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                           color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _LocationMessageData? _parseLocationMessage(String content) {
    // Format: "Shared Location: <lat>, <lon>\n<note>"
    if (!content.startsWith("Shared Location:")) return null;

    try {
      final lines = content.split('\n');
      final firstLine = lines[0]; // "Shared Location: 12.34, 56.78"
      final parts = firstLine.substring("Shared Location:".length).split(',');
      
      if (parts.length != 2) return null;
      
      final lat = double.parse(parts[0].trim());
      final lon = double.parse(parts[1].trim());
      
      // Note is everything after first line
      final note = lines.length > 1 ? lines.sublist(1).join('\n').trim() : "";
      
      return _LocationMessageData(LatLng(lat, lon), note);
    } catch (_) {
      return null;
    }
  }
}

class _LocationMessageData {
  final LatLng latLng;
  final String note;

  _LocationMessageData(this.latLng, this.note);
}
