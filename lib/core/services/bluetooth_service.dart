import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';


import '../../gen/proto/meshtastic/mesh.pb.dart';
import '../../gen/proto/meshtastic/portnums.pbenum.dart';

import '../database/database.dart';


final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
   final db = ref.watch(appDatabaseProvider);
   return BluetoothService(db);
});

final connectionStateProvider = StreamProvider<BluetoothConnectionState>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  return service.connectionState;
});

final nodesProvider = StreamProvider<Map<int, NodeInfo>>((ref) {
  return ref.watch(bluetoothServiceProvider).nodes;
});

final myNodeInfoProvider = StreamProvider<MyNodeInfo?>((ref) {
  return ref.watch(bluetoothServiceProvider).myNodeInfo;
});

class BluetoothService {
  final AppDatabase _db;
  
  BluetoothService(this._db);

  static const String serviceUuid = "6ba1b218-15a8-461f-9fa8-5dcae273eafd";
  static const String toRadioUuid = "f75c76d2-129e-4dad-a1dd-7866124401e7";
  static const String fromRadioUuid = "2c55e69e-4993-11ed-b878-0242ac120002";
  static const String fromNumUuid = "ed9da18c-a800-4f66-a670-aa7547e34453";

  BluetoothCharacteristic? _toRadioChar;
  BluetoothCharacteristic? _fromRadioChar;
  BluetoothCharacteristic? _fromNumChar;
  BluetoothDevice? _connectedDevice;

  // Stream controllers
  final _messagesController = StreamController<MeshPacket>.broadcast();
  Stream<MeshPacket> get messages => _messagesController.stream;

  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionState => _connectionStateController.stream;

  // Node tracking
  final _nodesController = StreamController<Map<int, NodeInfo>>.broadcast();
  final Map<int, NodeInfo> _knownNodes = {};
  Stream<Map<int, NodeInfo>> get nodes => _nodesController.stream;
  
  final _myNodeInfoController = StreamController<MyNodeInfo?>.broadcast();
  MyNodeInfo? _currentMyNodeInfo;
  Stream<MyNodeInfo?> get myNodeInfo => _myNodeInfoController.stream;
  
  // Public accessor for current MyNodeInfo (useful for finding my ID)
  MyNodeInfo? get currentMyNodeInfo => _currentMyNodeInfo;

  /// Returns my Node ID if available, otherwise 0
  int get myId => _currentMyNodeInfo?.myNodeNum ?? 0;

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  Future<void> startScan() async {
    if (await FlutterBluePlus.isSupported == false) return;
    if (Platform.isAndroid) await FlutterBluePlus.turnOn();
    
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      withServices: [Guid(serviceUuid)],
    );
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    _connectedDevice = device;
    try {
      await device.connect(autoConnect: false);
      
      // Listen to disconnection
      device.connectionState.listen((state) {
        _connectionStateController.add(state);
        if (state == BluetoothConnectionState.disconnected) {
            _toRadioChar = null;
            _fromRadioChar = null;
            _fromNumChar = null;
        }
      });

      final services = await device.discoverServices();
      final service = services.firstWhere((s) => s.uuid.toString() == serviceUuid);
      
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString() == toRadioUuid) {
          _toRadioChar = characteristic;
        } else if (characteristic.uuid.toString() == fromRadioUuid) {
          _fromRadioChar = characteristic;
        } else if (characteristic.uuid.toString() == fromNumUuid) {
          _fromNumChar = characteristic;
        }
      }

      if (_toRadioChar != null && _fromRadioChar != null && _fromNumChar != null) {
        await _initializeConnection();
        // Force update to connected only after handshake initialization if desired, 
        // but device.connectionState handles the physical link status.
      } else {
        throw Exception("Required Meshtastic characteristics not found");
      }
    } catch (e) {
      _connectionStateController.add(BluetoothConnectionState.disconnected);
      rethrow;
    }
  }

  Future<void> _initializeConnection() async {
    print("Initializing connection: subscribing to FromNum");
    await _fromNumChar!.setNotifyValue(true);
    _fromNumChar!.onValueReceived.listen((value) async {
       print("FromNum notification received: $value");
       await _readFromRadio();
    });

    print("Sending want_config_id to ToRadio");
    final packet = ToRadio();
    packet.wantConfigId = 12345;
    await _toRadioChar!.write(packet.writeToBuffer());
    print("Sent want_config_id");
    
    // Kickstart read just in case
    print("Doing initial read kick...");
    await _readFromRadio();
  }

  Future<void> _readFromRadio() async {
    if (_fromRadioChar == null) return;
    
    // Read loop
    while (true) {
      try {
        print("Reading FromRadio...");
        List<int> value = await _fromRadioChar!.read();
        if (value.isEmpty) {
          print("FromRadio empty, stopping read loop");
          break;
        }

        final fromRadio = FromRadio.fromBuffer(value);
        print("Received FromRadio packet. Has packet: ${fromRadio.hasPacket()}");
        
        if (fromRadio.hasPacket()) {
          final packet = fromRadio.packet;
          _messagesController.add(packet);
          
          if (packet.decoded.portnum == PortNum.TEXT_MESSAGE_APP) {
              final text = utf8.decode(packet.decoded.payload, allowMalformed: true);
              _db.insertMessage(MessagesCompanion.insert(
                fromId: packet.from,
                toId: packet.to,
                content: text,
                isMe: Value(false),
                timestamp: Value(DateTime.now()),
              ));
          }
        }

        if (fromRadio.hasNodeInfo()) {
           print("Received NodeInfo for: ${fromRadio.nodeInfo.user.longName} (${fromRadio.nodeInfo.num})");
           _knownNodes[fromRadio.nodeInfo.num] = fromRadio.nodeInfo;
           _nodesController.add(Map.from(_knownNodes));
           
           // Persist Node
           _db.insertOrUpdateNode(Node(
             num: fromRadio.nodeInfo.num,
             shortName: fromRadio.nodeInfo.user.shortName,
             longName: fromRadio.nodeInfo.user.longName,
           ));
        }

        if (fromRadio.hasMyInfo()) {
           print("Received MyNodeInfo: ${fromRadio.myInfo.myNodeNum}");
           _currentMyNodeInfo = fromRadio.myInfo;
           _myNodeInfoController.add(_currentMyNodeInfo);
        }
        
        if (fromRadio.configCompleteId == 12345) {
           print("Config sync complete");
           // _connectionStateController.add(BluetoothConnectionState.connected); // Signal ready?
        }
      } catch (e) {
        print("Error reading/decoding packet: $e");
        break; 
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (_toRadioChar == null) {
      print("Cannot send: ToRadio char is null");
      return;
    }

    print("Sending message: $text");
    final meshPacket = MeshPacket();
    meshPacket.decoded = Data();
    meshPacket.decoded.portnum = PortNum.TEXT_MESSAGE_APP;
    meshPacket.decoded.payload = utf8.encode(text);
    // meshPacket.to = 4294967295; // Broadcast
    // meshPacket.wantAck = true;  

    final toRadio = ToRadio();
    toRadio.packet = meshPacket;

    await _toRadioChar!.write(toRadio.writeToBuffer());
    print("Message sent to BLE characteristic");
    
    // Persist Sent Message
    _db.insertMessage(MessagesCompanion.insert(
      fromId: myId,
      toId: 4294967295, // Broadcast
      content: text,
      isMe: Value(true),
      timestamp: Value(DateTime.now()),
    ));
  }

  /// Sends a message to a specific node. defaults to broadcast if nodeId is null.
  Future<void> sendMessageTo(String text, int toNodeId) async {
      if (_toRadioChar == null) {
      print("Cannot send: ToRadio char is null");
      return;
    }

    print("Sending message to $toNodeId: $text");
    final meshPacket = MeshPacket();
    meshPacket.decoded = Data();
    meshPacket.decoded.portnum = PortNum.TEXT_MESSAGE_APP;
    meshPacket.decoded.payload = utf8.encode(text);
    meshPacket.to = toNodeId;
    
    // Set wantAck for private messages usually
    if (toNodeId != 4294967295) {
      meshPacket.wantAck = true;
    }

    final toRadio = ToRadio();
    toRadio.packet = meshPacket;

    await _toRadioChar!.write(toRadio.writeToBuffer());
    print("Private Message sent to $toNodeId");
    
    // Persist Sent Message
    _db.insertMessage(MessagesCompanion.insert(
      fromId: myId,
      toId: toNodeId,
      content: text,
      isMe: Value(true),
      timestamp: Value(DateTime.now()),
    ));
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
  }
}
