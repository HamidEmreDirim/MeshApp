import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/bluetooth_service.dart';
import '../../../../gen/proto/meshtastic/channel.pb.dart';
import 'widgets/channel_tab.dart';

class ChannelSettingsScreen extends ConsumerStatefulWidget {
  const ChannelSettingsScreen({super.key});

  @override
  ConsumerState<ChannelSettingsScreen> createState() => _ChannelSettingsScreenState();
}

class _ChannelSettingsScreenState extends ConsumerState<ChannelSettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<int, Channel> _channels = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadChannels();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    setState(() => _isLoading = true);
    try {
      final service = ref.read(bluetoothServiceProvider);
      
      // Execute requests in parallel to speed up loading
      // Note: If the device is slow, this might flood it. 
      // If reliability issues occur, consider batching or sequential with short delays.
      final futures = List<Future<Channel?>>.generate(8, (i) => service.getChannel(i));
      final results = await Future.wait(futures);

      for (int i = 0; i < 8; i++) {
        final channel = results[i];
        if (channel != null) {
            _channels[i] = channel;
        } else {
             // Fallback for empty/unfetched channels
            _channels[i] = Channel(
              index: i,
              role: Channel_Role.DISABLED,
              settings: ChannelSettings(name: ""),
            );
        }
      }
    } catch (e) {
      debugPrint("Error loading channels: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      
      // Update local state locally to reflect changes immediately
      setState(() {
        _channels[channel.index] = channel;
      });
      
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Channel Config"),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            const Tab(text: "Primary"),
            for (int i = 1; i < 8; i++)
               Tab(text: "Ch $i"),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                 for (int i = 0; i < 8; i++)
                   _channels.containsKey(i) 
                       ? ChannelTab(
                           index: i, 
                           channel: _channels[i]!, 
                           onSave: _onSaveChannel
                         )
                       : const Center(child: Text("Failed to load channel")),
              ],
            ),
    );
  }
}
