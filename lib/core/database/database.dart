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
  int get schemaVersion => 2;

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
  Stream<List<Node>> watchAllNodes() => select(nodes).watch();
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
