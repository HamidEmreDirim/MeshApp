import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/database/database.dart';
import '../application/map_provider.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final locationStateAsync = ref.watch(displayLocationProvider);
    final meshNodesAsync = ref.watch(meshNodesWithLocationProvider);
    final mapLayer = ref.watch(mapLayerProvider);

    final userLocation = locationStateAsync.value?.location;
    final source = locationStateAsync.value?.source ?? LocationSource.none;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full Screen Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLocation ?? const LatLng(0, 0),
              initialZoom: 15.0,
            ),
            children: [
              _buildTileLayer(mapLayer),

              // User Location Marker
              if (userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: userLocation,
                      width: 80,
                      height: 80,
                      child: _buildUserMarker(source),
                    ),
                  ],
                ),

              // Mesh Nodes Markers
              if (meshNodesAsync.value != null)
                MarkerLayer(
                  markers: meshNodesAsync.value!.map((node) {
                    return Marker(
                      point: LatLng(node.latitude!, node.longitude!),
                      width: 100,
                      height: 80,
                      child: _buildNodeMarker(node),
                    );
                  }).toList(),
                ),
            ],
          ),

          // 2. Floating Layer Switcher (Top Right)
          Positioned(
            top: 60,
            right: 20,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20), // Match FAB radius
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8), // Match FAB opacity
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _buildLayerSwitcher(ref, mapLayer),
                ),
              ),
            ),
          ),

          // 3. Floating Action Buttons (Recenter)
          Positioned(
            bottom: 30,
            right: 20,
            child: _buildFloatingButton(
              icon: Icons.my_location_rounded,
              onPressed: () {
                if (userLocation != null) {
                  _mapController.move(userLocation, 16.0);
                }
              },
            ),
          ),
          
          // 4. Location Source Info (Optional: Show if using Device GPS)
          if (source == LocationSource.device)
            Positioned(
              bottom: 100,
              right: 20,
              child: Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                 decoration: BoxDecoration(
                   color: Colors.green.withValues(alpha: 0.8),
                   borderRadius: BorderRadius.circular(20),
                 ),
                 child: const Text("Using Device GPS", style: TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserMarker(LocationSource source) {
    final color = source == LocationSource.phone ? Colors.blue : Colors.green;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (controller) => controller.repeat())
         .scale(duration: 2.seconds, begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5))
         .fadeOut(duration: 2.seconds),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNodeMarker(Node node) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
               BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            node.shortName ?? node.num.toString(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        const Icon(
          Icons.location_on_rounded,
          color: Colors.redAccent,
          size: 40,
        ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
      ],
    );
  }

  Widget _buildLayerSwitcher(WidgetRef ref, MapLayerType currentLayer) {
    return PopupMenuButton<MapLayerType>(
      icon: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Icon(Icons.layers_outlined, color: Colors.black87, size: 28),
      ),
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: Colors.white.withValues(alpha: 0.95),
      offset: const Offset(0, 50),
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

  Widget _buildFloatingButton({required IconData icon, required VoidCallback onPressed}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Icon(icon, color: Colors.black87, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTileLayer(MapLayerType type) {
    switch (type) {
      case MapLayerType.satellite:
        return TileLayer(
          urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          userAgentPackageName: 'com.example.mesh_app',
        );
      case MapLayerType.terrain:
        return TileLayer(
          urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mesh_app',
        );
      case MapLayerType.normal:
        return TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mesh_app',
        );
    }
  }
}
