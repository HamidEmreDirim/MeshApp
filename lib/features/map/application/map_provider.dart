import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/database/database.dart';
import '../../../core/services/bluetooth_service.dart';

// --- Location Source Logic ---

enum LocationSource {
  phone,
  device,
  none
}

class UserLocationState {
  final LatLng? location;
  final LocationSource source;

  UserLocationState({this.location, this.source = LocationSource.none});
}

// Current User Location (Phone GPS)
final phoneLocationProvider = StreamProvider<LatLng?>((ref) async* {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    yield null;
    return;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      yield null;
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    yield null;
    return;
  }

  // Yield current position immediately
  try {
     final pos = await Geolocator.getCurrentPosition();
     yield LatLng(pos.latitude, pos.longitude);
  } catch (e) {
    // Ignore initial error
  }

  // Then stream updates
  final stream = Geolocator.getPositionStream();
  await for (final pos in stream) {
    yield LatLng(pos.latitude, pos.longitude);
  }
});

// My Device Location (from Mesh Database, populated by BluetoothService)
// We need to know 'myId' to query this. 
// Assuming we can get 'myId' from somewhere or just query the node with matching ID if we had it.
// Since BluetoothService stores MyNodeInfo, let's assume we can get myId from the db or service.
// For now, let's create a provider that finds "My" node. 
// However, the DB doesn't explicitly flag "My Node" in the Nodes table unless we match against MyNodeInfo.
// We'll rely on BluetoothService to update a specific provider or just broadcast my location.
// Actually, better: We can watch the node with ID = myId.
// For this step, I'll update BluetoothService to expose myId, then use it here.
// But circular dependency risk.
// Let's just assume we watch ALL nodes and filter by 'isMe' if we had that, or use a heuristic.
// The BluetoothService has `myId`. Let's assume we can pass it or use a provider for it.
// I will add `myIdProvider` in a separate file or import it if it exists. 
// It exists in `bluetooth_service.dart` as a getter, but not a Riverpod provider we can easily watch inside another provider without ref imports.
// Actually `bluetooth_service.dart` has `myNodeInfoProvider`.

// We need to import the providers from bluetooth_service to get myId


final myDeviceLocationProvider = StreamProvider<LatLng?>((ref) async* {
  final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
  final myId = myNodeInfoAsync.value?.myNodeNum;

  if (myId == null) {
    yield null;
    return;
  }

  final db = ref.watch(appDatabaseProvider);
  // Watch specific node
  await for (final node in db.watchNode(myId)) {
    if (node != null && node.latitude != null && node.longitude != null) {
      yield LatLng(node.latitude!, node.longitude!);
    } else {
      yield null;
    }
  }
});


final displayLocationProvider = Provider<AsyncValue<UserLocationState>>((ref) {
  final phoneLoc = ref.watch(phoneLocationProvider);
  final deviceLoc = ref.watch(myDeviceLocationProvider);

  if (phoneLoc.value != null) {
    return AsyncValue.data(UserLocationState(location: phoneLoc.value, source: LocationSource.phone));
  } else if (deviceLoc.value != null) {
    return AsyncValue.data(UserLocationState(location: deviceLoc.value, source: LocationSource.device));
  } else {
    // Determine state (loading vs error vs data null)
    if (phoneLoc.isLoading || deviceLoc.isLoading) return const AsyncValue.loading();
    return AsyncValue.data(UserLocationState(location: null, source: LocationSource.none));
  }
});


// Mesh Nodes with Location (Excluding Me)
final meshNodesWithLocationProvider = StreamProvider<List<Node>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final myNodeInfoAsync = ref.watch(myNodeInfoProvider);
  final myId = myNodeInfoAsync.value?.myNodeNum;

  return db.watchAllNodes().map((nodes) => 
      nodes.where((n) => 
        n.latitude != null && 
        n.longitude != null && 
        (myId == null || n.num != myId) // Exclude myself from "other nodes" markers
      ).toList()
  );
});

// --- Map Layer Logic ---

enum MapLayerType {
  normal,
  satellite,
  terrain
}


class MapLayerNotifier extends Notifier<MapLayerType> {
  @override
  MapLayerType build() {
    return MapLayerType.normal;
  }
  
  void setType(MapLayerType type) => state = type;
}

final mapLayerProvider = NotifierProvider<MapLayerNotifier, MapLayerType>(MapLayerNotifier.new);

// Shared Location Target (for viewing shared location from Chat)
class SharedLocationTargetNotifier extends Notifier<LatLng?> {
  @override
  LatLng? build() => null;

  void setLocation(LatLng location) => state = location;
  void clear() => state = null;
}

final sharedLocationTargetProvider = NotifierProvider<SharedLocationTargetNotifier, LatLng?>(SharedLocationTargetNotifier.new);

