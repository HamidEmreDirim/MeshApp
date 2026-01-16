import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';

import 'package:flutter_animate/flutter_animate.dart';

import 'scan_dialog.dart';
import '../../../core/services/bluetooth_service.dart';

class LandingScreen extends ConsumerWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to connection state
    ref.listen(connectionStateProvider, (previous, next) {
      next.whenData((state) {
        if (state == BluetoothConnectionState.connected) {
          // Navigate to chat when connected
          // Check if we are already there to avoid dupes? GoRouter handles that?
          context.go('/chat');
        }
      });
    });

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo or Icon
              Icon(
                Icons.hub,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ).animate().fade(duration: 600.ms).scale(),
              const Gap(40),
              
              // Connect Button
              Material(
                elevation: 8,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                color: Theme.of(context).colorScheme.primary,
                child: InkWell(
                  onTap: () {
                     showDialog(
                      context: context, 
                      builder: (context) => const ScanDialog()
                    );
                  },
                  child: Container(
                    width: 160,
                    height: 160,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bluetooth_searching, size: 40, color: Colors.white),
                        const Gap(8),
                        Text(
                          "CONNECT",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate(delay: 200.ms).scale().shimmer(delay: 1.seconds, duration: 2.seconds),

              const Gap(40),

              // Offline Button
              OutlinedButton.icon(
                onPressed: () {
                  context.go('/chat');
                },
                icon: const Icon(Icons.wifi_off),
                label: const Text("Continue Offline"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 500.ms).moveY(begin: 20, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
