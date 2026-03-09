import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/database/database.dart';
import '../application/map_provider.dart';
import 'widgets/share_location_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  
  // Custom marker icons
  BitmapDescriptor? _userIcon;
  BitmapDescriptor? _nodeIcon;
  BitmapDescriptor? _sharedIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
  }

  Future<void> _loadCustomMarkers() async {
    // You can load custom assets here. For now using default hues.
    // If you want to use assets, replace with BitmapDescriptor.fromAssetImage(...)
    // Ensure you add them to pubspec.yaml assets section first.
    
    // Example of a cleaner look using default markers with specific hues
    setState(() {
      _userIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      _nodeIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed); 
      _sharedIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationStateAsync = ref.watch(displayLocationProvider);
    final meshNodesAsync = ref.watch(meshNodesWithLocationProvider);
    final mapLayer = ref.watch(mapLayerProvider);
    final sharedLocation = ref.watch(sharedLocationTargetProvider);

    final userLocation = locationStateAsync.value?.location;
    final source = locationStateAsync.value?.source ?? LocationSource.none;

    // Listen for shared location requests to move camera
    ref.listen(sharedLocationTargetProvider, (previous, next) async {
      if (next != null) {
        final controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newLatLngZoom(next, 16));
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _getMapType(mapLayer),
            initialCameraPosition: CameraPosition(
              target: userLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              if (!_controller.isCompleted) {
                _controller.complete(controller);
              }
            },
            myLocationEnabled: source == LocationSource.phone, // Show blue dot if using phone GPS
            myLocationButtonEnabled: false, // We use custom button
            zoomControlsEnabled: false,
            onLongPress: (LatLng point) {
              _showShareLocationSheet(context, point);
            },
            markers: _buildMarkers(userLocation, source, meshNodesAsync.value, sharedLocation),
          ),

          // Layer Switcher
          Positioned(
            top: 60,
            right: 20,
            child: _buildLayerSwitcher(ref, mapLayer),
          ),

          // FABs
          Positioned(
            bottom: 30,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sharedLocation != null) ...[
                   _buildFloatingButton(
                    icon: Icons.location_searching,
                    onPressed: () async {
                      final controller = await _controller.future;
                      controller.animateCamera(CameraUpdate.newLatLngZoom(sharedLocation, 16));
                    },
                    tooltip: "Show Shared Location",
                  ),
                  const SizedBox(height: 16),
                ],
                _buildFloatingButton(
                  icon: Icons.my_location_rounded,
                  onPressed: () async {
                    if (userLocation != null) {
                      final controller = await _controller.future;
                      controller.animateCamera(CameraUpdate.newLatLngZoom(userLocation, 16));
                    }
                  },
                  tooltip: "My Location",
                ),
              ],
            ),
          ),

          // Location Source Indicator
          if (source == LocationSource.device)
            Positioned(
              bottom: 100,
              right: 20,
              child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                   color: Colors.green.withValues(alpha: 0.9),
                   borderRadius: BorderRadius.circular(20),
                   boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
                 ),
                 child: const Text("Using Device GPS", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Set<Marker> _buildMarkers(LatLng? userLocation, LocationSource source, List<Node>? nodes, LatLng? sharedLocation) {
    final markers = <Marker>{};

    // User Marker (only if NOT using phone GPS, because phone GPS shows the native blue dot via myLocationEnabled)
    if (userLocation != null && source == LocationSource.device) {
      markers.add(Marker(
        markerId: const MarkerId('user_device_location'),
        position: userLocation,
        icon: _userIcon ?? BitmapDescriptor.defaultMarker,
        infoWindow: const InfoWindow(title: 'My Device'),
      ));
    }

    // Nodes
    if (nodes != null) {
      for (final node in nodes) {
        markers.add(Marker(
          markerId: MarkerId('node_${node.num}'),
          position: LatLng(node.latitude!, node.longitude!),
          icon: _nodeIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: node.longName ?? node.shortName ?? 'Node ${node.num}',
            snippet: node.shortName,
          ),
        ));
      }
    }

    // Shared Location
    if (sharedLocation != null) {
      markers.add(Marker(
        markerId: const MarkerId('shared_location'),
        position: sharedLocation,
        icon: _sharedIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueMagenta),
        infoWindow: const InfoWindow(title: 'Shared Location'),
      ));
    }

    return markers;
  }

  MapType _getMapType(MapLayerType type) {
    switch (type) {
      case MapLayerType.normal:
        return MapType.normal;
      case MapLayerType.satellite:
        return MapType.hybrid; // Hybrid is usually better for satellite views users actually want (with labels)
      case MapLayerType.terrain:
        return MapType.terrain;
    }
  }

  void _showShareLocationSheet(BuildContext context, LatLng point) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ShareLocationSheet(location: point),
      ),
    );
  }

  Widget _buildLayerSwitcher(WidgetRef ref, MapLayerType currentLayer) {
    return PopupMenuButton<MapLayerType>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: const Icon(Icons.layers_outlined, color: Colors.black87, size: 24),
      ),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (MapLayerType type) {
        ref.read(mapLayerProvider.notifier).setType(type);
      },
      itemBuilder: (context) => [
        _buildLayerMenuItem(MapLayerType.normal, 'Normal', Icons.map_outlined, currentLayer),
        _buildLayerMenuItem(MapLayerType.satellite, 'Satellite', Icons.satellite_alt_outlined, currentLayer),
        _buildLayerMenuItem(MapLayerType.terrain, 'Terrain', Icons.terrain_outlined, currentLayer),
      ],
    );
  }

  PopupMenuItem<MapLayerType> _buildLayerMenuItem(
    MapLayerType value, String label, IconData icon, MapLayerType current) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: current == value ? Colors.blue : Colors.grey[700], size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: current == value ? FontWeight.w600 : FontWeight.w400,
              color: current == value ? Colors.blue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onPressed, String? tooltip}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: Material(
        color: Colors.transparent,
        child: IconButton(
          icon: Icon(icon, color: Colors.black87),
          onPressed: onPressed,
          tooltip: tooltip,
          padding: const EdgeInsets.all(12),
          iconSize: 28,
        ),
      ),
    );
  }
}
