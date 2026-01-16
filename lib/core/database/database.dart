import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Messages, Nodes])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

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
          await m.addColumn(nodes, nodes.latitude);
          await m.addColumn(nodes, nodes.longitude);
          await m.addColumn(nodes, nodes.altitude);
        }
      },
    );
  }
  
  // Message CRUD
  Future<int> insertMessage(MessagesCompanion message) => into(messages).insert(message);
  
  Stream<List<Message>> watchMessagesForNode(int targetNodeId, int myId) {
    if (targetNodeId == 4294967295) {
       // Primary Channel (Broadcast): Show all messages to 4294967295
       return (select(messages)
           ..where((t) => t.toId.equals(4294967295))
           ..orderBy([(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
           .watch();
    } else {
      // Private Chat: either FROM target TO me, OR FROM me TO target
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

  Stream<List<Node>> watchAllNodes() => select(nodes).watch();

  Stream<Node?> watchNode(int nodeId) {
    return (select(nodes)..where((t) => t.num.equals(nodeId))).watchSingleOrNull();
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
