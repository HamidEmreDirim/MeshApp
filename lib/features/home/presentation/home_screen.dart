import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../map/application/location_broadcast_manager.dart';
import '../../../core/services/bluetooth_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start broadcasting location periodic updates
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationBroadcastManagerProvider).start();
    });
  }

  @override
  void dispose() {
    // Attempt to stop the broadcaster when the screen is disposed
    // Note: In many apps HomeScreen is the root and only disposed on app exit
    try {
      ref.read(locationBroadcastManagerProvider).stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        destinations: [
          NavigationDestination(
            icon: Badge(
              label: Consumer(
                builder: (context, ref, child) {
                  final count = ref.watch(unreadMessageCountProvider).asData?.value ?? 0;
                  return count > 0 ? Text('$count') : const SizedBox.shrink();
                },
              ),
              isLabelVisible: (ref.watch(unreadMessageCountProvider).asData?.value ?? 0) > 0,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
               label: Consumer(
                builder: (context, ref, child) {
                  final count = ref.watch(unreadMessageCountProvider).asData?.value ?? 0;
                  return count > 0 ? Text('$count') : const SizedBox.shrink();
                },
              ),
              isLabelVisible: (ref.watch(unreadMessageCountProvider).asData?.value ?? 0) > 0,
              child: const Icon(Icons.chat_bubble),
            ),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
