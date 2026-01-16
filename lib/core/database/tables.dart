import 'package:drift/drift.dart';

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromId => integer()();
  IntColumn get toId => integer()();
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();
}

class Nodes extends Table {
  IntColumn get num => integer()(); // Node ID
  TextColumn get shortName => text().nullable()();
  TextColumn get longName => text().nullable()();
  // We can add more fields from NodeInfo as needed, or store blob
  
  @override
  Set<Column> get primaryKey => {num};
}
