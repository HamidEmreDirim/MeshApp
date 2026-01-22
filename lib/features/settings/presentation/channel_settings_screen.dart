import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/bluetooth_service.dart';
import '../../../../gen/proto/meshtastic/channel.pb.dart';
import '../../../../core/database/database.dart' as drift_db;
import 'widgets/channel_tab.dart';

class ChannelSettingsScreen extends ConsumerStatefulWidget {
  const ChannelSettingsScreen({super.key});

  @override
  ConsumerState<ChannelSettingsScreen> createState() => _ChannelSettingsScreenState();
}

class _ChannelSettingsScreenState extends ConsumerState<ChannelSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _onSaveChannel(Channel channel) async {
    try {
      final service = ref.read(bluetoothServiceProvider);
      await service.setChannel(channel);
      
      if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Saving Channel ${channel.index}...")),
           );
      }
      
      // No need to update local state, DB update will trigger re-build via provider
      
    } catch (e) {
       if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error saving channel: $e"), backgroundColor: Colors.red),
           );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Channel Config"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (int i = 0; i < 8; i++) ...[
               // We need to map from DB channels to tabs, or just show placeholders
               // It's tricky because channelsAsync is a List of DB channels.
               // We need to find if there is a channel for index i
               _buildTab(channelsAsync, i),
            ]
          ],
        ),
      ),
      body: channelsAsync.when(
        data: (dbChannels) {
           return TabBarView(
              controller: _tabController,
              children: [
                 for (int i = 0; i < 8; i++)
                   _buildChannelView(dbChannels, i),
              ],
            );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildTab(AsyncValue<List<drift_db.Channel>> channelsAsync, int i) {
     String text = (i == 0 ? "Primary" : "Ch $i");
     
     if (channelsAsync.hasValue) {
        final dbChannels = channelsAsync.value!;
        try {
           final channel = dbChannels.firstWhere((c) => c.index == i);
           if (channel.name.isNotEmpty) {
              text = "${i == 0 ? 'P' : i}: ${channel.name}";
           }
        } catch (_) {}
     }

     return Tab(text: text);
  }

  Widget _buildChannelView(List<drift_db.Channel> dbChannels, int i) {
      // Convert Drift Channel to Proto Channel for the widget
      Channel? protoChannel;
      try {
         final dbChannel = dbChannels.firstWhere((c) => c.index == i);
         protoChannel = Channel(
            index: dbChannel.index,
            role: _parseRole(dbChannel.role),
            settings: ChannelSettings(
               name: dbChannel.name,
               psk: dbChannel.psk,
            ),
         );
      } catch (_) {
         // Default empty
         protoChannel = Channel(
            index: i,
            role: Channel_Role.DISABLED,
            settings: ChannelSettings(name: ""),
         );
      }

      return ChannelTab(
          index: i, 
          channel: protoChannel, 
          onSave: _onSaveChannel
      );
  }

  Channel_Role _parseRole(String? roleStr) {
     if (roleStr == null) return Channel_Role.DISABLED;
     return Channel_Role.values.firstWhere(
        (e) => e.toString() == roleStr, 
        orElse: () => Channel_Role.DISABLED
     );
  }
}
