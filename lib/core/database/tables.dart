import 'package:drift/drift.dart';

class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fromId => integer()();
  IntColumn get toId => integer()();
  TextColumn get content => text()();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();
  IntColumn get channelIndex => integer().withDefault(const Constant(0))();
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
}

class Nodes extends Table {
  IntColumn get num => integer()(); // Node ID
  TextColumn get shortName => text().nullable()();
  TextColumn get longName => text().nullable()();
  
  // New fields
  DateTimeColumn get lastHeard => dateTime().nullable()();
  IntColumn get battery => integer().nullable()();
  RealColumn get snr => real().nullable()();
  TextColumn get role => text().nullable()(); // Router, Client, etc.
  TextColumn get model => text().nullable()(); // TBEAM, etc.
  
  // Location
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get altitude => integer().nullable()();
  
  // We can add more fields from NodeInfo as needed, or store blob
  
  @override
  Set<Column> get primaryKey => {num};
}

class Channels extends Table {
  IntColumn get index => integer()(); // 0-7 usually
  TextColumn get name => text()();
  TextColumn get role => text().nullable()(); // PRIMARY, SECONDARY, etc.
  BlobColumn get psk => blob().nullable()(); // Store PSK if needed, carefully
  
  @override
  Set<Column> get primaryKey => {index};
}
