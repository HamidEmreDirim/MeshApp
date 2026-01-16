import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart'; // Added dependency

import 'package:permission_handler/permission_handler.dart';
import '../../../core/services/bluetooth_service.dart';

class ScanDialog extends ConsumerStatefulWidget {
  const ScanDialog({super.key});

  @override
  ConsumerState<ScanDialog> createState() => _ScanDialogState();
}

class _ScanDialogState extends ConsumerState<ScanDialog> {
  bool _isConnecting = false;
  bool _locationServiceEnabled = true;

  @override
  void initState() {
    super.initState();
    _checkLocationAndScan();
  }

  Future<void> _checkLocationAndScan() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _locationServiceEnabled = false;
        });
      }
      return; 
    }

    // Services enabled, request permissions and scan
    _startScan();
  }

  Future<void> _startScan() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    if (statuses[Permission.bluetoothScan] == PermissionStatus.granted || 
        statuses[Permission.bluetoothConnect] == PermissionStatus.granted) {
          ref.read(bluetoothServiceProvider).startScan();
    } else {
      debugPrint("Permissions denied");
       ref.read(bluetoothServiceProvider).startScan();
    }
  }

  @override
  void dispose() {
    // Only stop scanning if we aren't connecting (connecting might need scan? No usually stop scan before connect)
    // ref.read(bluetoothServiceProvider).stopScan(); // Moved to connect logic
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetooth = ref.watch(bluetoothServiceProvider);
    
    return AlertDialog(
      title: const Text("Scanning Devices"),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: !_locationServiceEnabled
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_off, size: 48, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text(
                      "Location Services are disabled.\nAndroid requires Location to scan for Bluetooth devices.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await Geolocator.openLocationSettings();
                        // Wait user to come back? or manual retry
                        _checkLocationAndScan();
                      },
                      child: const Text("Enable Location"),
                    ),
                  ],
                ),
              )
            : _isConnecting 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Connecting..."),
                ],
              ),
            )
          : StreamBuilder<List<ScanResult>>(
          stream: bluetooth.scanResults,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            final results = snapshot.data!;
            final devices = results;

            if (devices.isEmpty) {
               return const Center(child: Text("No devices found"));
            }

            return ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index].device;
                final name = device.platformName.isNotEmpty ? device.platformName : "Unknown Device";
                final id = device.remoteId.toString();

                return ListTile(
                  title: Text(name),
                  subtitle: Text(id),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      setState(() {
                         _isConnecting = true;
                      });
                      
                      try {
                        await bluetooth.connect(device);
                        
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          // Navigation is now handled by the listener in LandingScreen, 
                          // but keeping this pop is good for the dialog itself.
                        }
                      } catch (e) {
                         setState(() {
                           _isConnecting = false;
                        });
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text("Connection failed: $e"))
                           );
                         }
                      }
                    },
                    child: const Text("Connect"),
                  ),
                );
              },
            );
          },
        ),
      ),
      actions: [
        if (!_isConnecting)
          TextButton(
            onPressed: () {
              ref.read(bluetoothServiceProvider).stopScan();
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
      ],
    );
  }
}
