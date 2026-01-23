import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Messages, Nodes, Channels])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Schema v2: Added lastHeard, battery, snr, role, model to Nodes
          await m.addColumn(nodes, nodes.lastHeard);
          await m.addColumn(nodes, nodes.battery);
          await m.addColumn(nodes, nodes.snr);
          await m.addColumn(nodes, nodes.role);
          await m.addColumn(nodes, nodes.model);
        }
        if (from < 3) {
          // Schema v3: Added location
          await m.addColumn(nodes, nodes.altitude);
        }
        if (from < 4) {
          // Schema v4: Added Channels table & channelIndex to Messages
          await m.createTable(channels);
          await m.addColumn(messages, messages.channelIndex);
        }
        if (from < 5) {
          // Schema v5: Added isRead to Messages
          await m.addColumn(messages, messages.isRead);
        }
      },
    );
  }
  
  // Message CRUD
  Future<int> insertMessage(MessagesCompanion message) => into(messages).insert(message);
  
  Stream<List<Message>> watchMessagesForNode(int targetNodeId, int myId, {int channelIndex = 0}) {
    if (targetNodeId == 4294967295) {
       // Primary/Broadcast Channel: specific channel index
       return (select(messages)
           ..where((t) => t.toId.equals(4294967295) & t.channelIndex.equals(channelIndex))
           ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
           .watch();
    } else {
      // Private Chat: ignore channelIndex usually (defaults to 0 or whatever)
      // Or maybe we should enforce channelIndex? Usually DMs are on a specific channel/LoRa settings, 
      // but in Meshtastic DMs are just to a node, traversing whatever path.
      return (select(messages)
          ..where((t) => 
              (t.fromId.equals(targetNodeId) & t.toId.equals(myId)) |
              (t.fromId.equals(myId) & t.toId.equals(targetNodeId))
          )
          ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
          .watch();
    }
  }

  // Node CRUD
  Future<void> insertOrUpdateNode(Node node) => into(nodes).insertOnConflictUpdate(node);
  
  Future<void> upsertNodeLocation(int nodeId, double? lat, double? lon, int? alt) {
    return into(nodes).insertOnConflictUpdate(
      NodesCompanion(
        num: Value(nodeId),
        latitude: Value(lat),
        longitude: Value(lon),
        altitude: Value(alt),
      ),
    );
  }

  Future<void> deleteNode(int nodeId) {
    return (delete(nodes)..where((t) => t.num.equals(nodeId))).go();
  }
  
  Future<void> deleteMessagesForNode(int nodeId, {int channelIndex = 0}) {
      if (nodeId == 4294967295) {
        return (delete(messages)..where((t) => t.toId.equals(4294967295) & t.channelIndex.equals(channelIndex))).go();
      } else {
        // Delete conversation where either sender is me and receiver is them, OR sender is them and receiver is me.
        // Actually for simplicity, we can just delete where fromId=nodeId OR toId=nodeId? 
        // No, that works.
        return (delete(messages)..where((t) => t.fromId.equals(nodeId) | t.toId.equals(nodeId))).go();
      }
  }

  Stream<List<Node>> watchAllNodes() => select(nodes).watch();

  Stream<Node?> watchNode(int nodeId) {
    return (select(nodes)..where((t) => t.num.equals(nodeId))).watchSingleOrNull();
  }

  // Channel CRUD
  Future<void> insertOrUpdateChannel(Channel channel) => into(channels).insertOnConflictUpdate(channel);
  
  Stream<List<Channel>> watchAllChannels() => select(channels).watch();

  // Notification / Unread helper methods
  Stream<int> watchUnreadMessageCount() {
    // Count messages where isMe is false and isRead is false
    final countExpression = messages.id.count();
    final query = selectOnly(messages)
      ..addColumns([countExpression])
      ..where(messages.isMe.equals(false) & messages.isRead.equals(false));
    
    return query.map((row) => row.read(countExpression) ?? 0).watchSingle();
  }

  Stream<int> watchUnreadMessageCountForNode(int nodeId) {
     final countExpression = messages.id.count();
    final query = selectOnly(messages)
      ..addColumns([countExpression])
      ..where(messages.isMe.equals(false) & messages.isRead.equals(false) & messages.fromId.equals(nodeId));
    
    return query.map((row) => row.read(countExpression) ?? 0).watchSingle();
  }

  Stream<int> watchUnreadMessageCountForChannel(int channelIndex) {
     final countExpression = messages.id.count();
    // For channels, we look for messages sent to broadcast (4294967295) on this channel
    final query = selectOnly(messages)
      ..addColumns([countExpression])
      ..where(messages.isMe.equals(false) & messages.isRead.equals(false) & messages.toId.equals(4294967295) & messages.channelIndex.equals(channelIndex));
    
    return query.map((row) => row.read(countExpression) ?? 0).watchSingle();
  }
  
  Future<void> markMessagesAsRead(int nodeId, {int channelIndex = 0}) async {
    // If nodeId is broadcast (4294967295), we might want to mark all broadcast messages in that channel as read
    if (nodeId == 4294967295) {
        await (update(messages)
          ..where((t) => t.toId.equals(4294967295) & t.channelIndex.equals(channelIndex) & t.isMe.equals(false)))
          .write(MessagesCompanion(isRead: Value(true)));
    } else {
        // Mark all messages from this node as read
        await (update(messages)
          ..where((t) => t.fromId.equals(nodeId) & t.isMe.equals(false)))
          .write(MessagesCompanion(isRead: Value(true)));
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

// Provider
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Dispose? Usually app DB lives forever, but good practice
  ref.onDispose(db.close); 
  return db;
});
