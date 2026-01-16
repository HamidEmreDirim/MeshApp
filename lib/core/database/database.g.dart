// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MessagesTable extends Messages with TableInfo<$MessagesTable, Message> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _fromIdMeta = const VerificationMeta('fromId');
  @override
  late final GeneratedColumn<int> fromId = GeneratedColumn<int>(
    'from_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<int> toId = GeneratedColumn<int>(
    'to_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isMeMeta = const VerificationMeta('isMe');
  @override
  late final GeneratedColumn<bool> isMe = GeneratedColumn<bool>(
    'is_me',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_me" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    fromId,
    toId,
    content,
    timestamp,
    isMe,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Message> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('from_id')) {
      context.handle(
        _fromIdMeta,
        fromId.isAcceptableOrUnknown(data['from_id']!, _fromIdMeta),
      );
    } else if (isInserting) {
      context.missing(_fromIdMeta);
    }
    if (data.containsKey('to_id')) {
      context.handle(
        _toIdMeta,
        toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('is_me')) {
      context.handle(
        _isMeMeta,
        isMe.isAcceptableOrUnknown(data['is_me']!, _isMeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Message map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Message(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      fromId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}from_id'],
      )!,
      toId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      isMe: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_me'],
      )!,
    );
  }

  @override
  $MessagesTable createAlias(String alias) {
    return $MessagesTable(attachedDatabase, alias);
  }
}

class Message extends DataClass implements Insertable<Message> {
  final int id;
  final int fromId;
  final int toId;
  final String content;
  final DateTime timestamp;
  final bool isMe;
  const Message({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.content,
    required this.timestamp,
    required this.isMe,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['from_id'] = Variable<int>(fromId);
    map['to_id'] = Variable<int>(toId);
    map['content'] = Variable<String>(content);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['is_me'] = Variable<bool>(isMe);
    return map;
  }

  MessagesCompanion toCompanion(bool nullToAbsent) {
    return MessagesCompanion(
      id: Value(id),
      fromId: Value(fromId),
      toId: Value(toId),
      content: Value(content),
      timestamp: Value(timestamp),
      isMe: Value(isMe),
    );
  }

  factory Message.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Message(
      id: serializer.fromJson<int>(json['id']),
      fromId: serializer.fromJson<int>(json['fromId']),
      toId: serializer.fromJson<int>(json['toId']),
      content: serializer.fromJson<String>(json['content']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      isMe: serializer.fromJson<bool>(json['isMe']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'fromId': serializer.toJson<int>(fromId),
      'toId': serializer.toJson<int>(toId),
      'content': serializer.toJson<String>(content),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'isMe': serializer.toJson<bool>(isMe),
    };
  }

  Message copyWith({
    int? id,
    int? fromId,
    int? toId,
    String? content,
    DateTime? timestamp,
    bool? isMe,
  }) => Message(
    id: id ?? this.id,
    fromId: fromId ?? this.fromId,
    toId: toId ?? this.toId,
    content: content ?? this.content,
    timestamp: timestamp ?? this.timestamp,
    isMe: isMe ?? this.isMe,
  );
  Message copyWithCompanion(MessagesCompanion data) {
    return Message(
      id: data.id.present ? data.id.value : this.id,
      fromId: data.fromId.present ? data.fromId.value : this.fromId,
      toId: data.toId.present ? data.toId.value : this.toId,
      content: data.content.present ? data.content.value : this.content,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      isMe: data.isMe.present ? data.isMe.value : this.isMe,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Message(')
          ..write('id: $id, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('isMe: $isMe')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, fromId, toId, content, timestamp, isMe);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Message &&
          other.id == this.id &&
          other.fromId == this.fromId &&
          other.toId == this.toId &&
          other.content == this.content &&
          other.timestamp == this.timestamp &&
          other.isMe == this.isMe);
}

class MessagesCompanion extends UpdateCompanion<Message> {
  final Value<int> id;
  final Value<int> fromId;
  final Value<int> toId;
  final Value<String> content;
  final Value<DateTime> timestamp;
  final Value<bool> isMe;
  const MessagesCompanion({
    this.id = const Value.absent(),
    this.fromId = const Value.absent(),
    this.toId = const Value.absent(),
    this.content = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.isMe = const Value.absent(),
  });
  MessagesCompanion.insert({
    this.id = const Value.absent(),
    required int fromId,
    required int toId,
    required String content,
    this.timestamp = const Value.absent(),
    this.isMe = const Value.absent(),
  }) : fromId = Value(fromId),
       toId = Value(toId),
       content = Value(content);
  static Insertable<Message> custom({
    Expression<int>? id,
    Expression<int>? fromId,
    Expression<int>? toId,
    Expression<String>? content,
    Expression<DateTime>? timestamp,
    Expression<bool>? isMe,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (fromId != null) 'from_id': fromId,
      if (toId != null) 'to_id': toId,
      if (content != null) 'content': content,
      if (timestamp != null) 'timestamp': timestamp,
      if (isMe != null) 'is_me': isMe,
    });
  }

  MessagesCompanion copyWith({
    Value<int>? id,
    Value<int>? fromId,
    Value<int>? toId,
    Value<String>? content,
    Value<DateTime>? timestamp,
    Value<bool>? isMe,
  }) {
    return MessagesCompanion(
      id: id ?? this.id,
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isMe: isMe ?? this.isMe,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (fromId.present) {
      map['from_id'] = Variable<int>(fromId.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<int>(toId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (isMe.present) {
      map['is_me'] = Variable<bool>(isMe.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MessagesCompanion(')
          ..write('id: $id, ')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('content: $content, ')
          ..write('timestamp: $timestamp, ')
          ..write('isMe: $isMe')
          ..write(')'))
        .toString();
  }
}

class $NodesTable extends Nodes with TableInfo<$NodesTable, Node> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numMeta = const VerificationMeta('num');
  @override
  late final GeneratedColumn<int> num = GeneratedColumn<int>(
    'num',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _shortNameMeta = const VerificationMeta(
    'shortName',
  );
  @override
  late final GeneratedColumn<String> shortName = GeneratedColumn<String>(
    'short_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longNameMeta = const VerificationMeta(
    'longName',
  );
  @override
  late final GeneratedColumn<String> longName = GeneratedColumn<String>(
    'long_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastHeardMeta = const VerificationMeta(
    'lastHeard',
  );
  @override
  late final GeneratedColumn<DateTime> lastHeard = GeneratedColumn<DateTime>(
    'last_heard',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _batteryMeta = const VerificationMeta(
    'battery',
  );
  @override
  late final GeneratedColumn<int> battery = GeneratedColumn<int>(
    'battery',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snrMeta = const VerificationMeta('snr');
  @override
  late final GeneratedColumn<double> snr = GeneratedColumn<double>(
    'snr',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _roleMeta = const VerificationMeta('role');
  @override
  late final GeneratedColumn<String> role = GeneratedColumn<String>(
    'role',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modelMeta = const VerificationMeta('model');
  @override
  late final GeneratedColumn<String> model = GeneratedColumn<String>(
    'model',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    num,
    shortName,
    longName,
    lastHeard,
    battery,
    snr,
    role,
    model,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Node> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('num')) {
      context.handle(
        _numMeta,
        num.isAcceptableOrUnknown(data['num']!, _numMeta),
      );
    }
    if (data.containsKey('short_name')) {
      context.handle(
        _shortNameMeta,
        shortName.isAcceptableOrUnknown(data['short_name']!, _shortNameMeta),
      );
    }
    if (data.containsKey('long_name')) {
      context.handle(
        _longNameMeta,
        longName.isAcceptableOrUnknown(data['long_name']!, _longNameMeta),
      );
    }
    if (data.containsKey('last_heard')) {
      context.handle(
        _lastHeardMeta,
        lastHeard.isAcceptableOrUnknown(data['last_heard']!, _lastHeardMeta),
      );
    }
    if (data.containsKey('battery')) {
      context.handle(
        _batteryMeta,
        battery.isAcceptableOrUnknown(data['battery']!, _batteryMeta),
      );
    }
    if (data.containsKey('snr')) {
      context.handle(
        _snrMeta,
        snr.isAcceptableOrUnknown(data['snr']!, _snrMeta),
      );
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('model')) {
      context.handle(
        _modelMeta,
        model.isAcceptableOrUnknown(data['model']!, _modelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {num};
  @override
  Node map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Node(
      num: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}num'],
      )!,
      shortName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}short_name'],
      ),
      longName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}long_name'],
      ),
      lastHeard: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_heard'],
      ),
      battery: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}battery'],
      ),
      snr: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}snr'],
      ),
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      model: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model'],
      ),
    );
  }

  @override
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }
}

class Node extends DataClass implements Insertable<Node> {
  final int num;
  final String? shortName;
  final String? longName;
  final DateTime? lastHeard;
  final int? battery;
  final double? snr;
  final String? role;
  final String? model;
  const Node({
    required this.num,
    this.shortName,
    this.longName,
    this.lastHeard,
    this.battery,
    this.snr,
    this.role,
    this.model,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['num'] = Variable<int>(num);
    if (!nullToAbsent || shortName != null) {
      map['short_name'] = Variable<String>(shortName);
    }
    if (!nullToAbsent || longName != null) {
      map['long_name'] = Variable<String>(longName);
    }
    if (!nullToAbsent || lastHeard != null) {
      map['last_heard'] = Variable<DateTime>(lastHeard);
    }
    if (!nullToAbsent || battery != null) {
      map['battery'] = Variable<int>(battery);
    }
    if (!nullToAbsent || snr != null) {
      map['snr'] = Variable<double>(snr);
    }
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || model != null) {
      map['model'] = Variable<String>(model);
    }
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      num: Value(num),
      shortName: shortName == null && nullToAbsent
          ? const Value.absent()
          : Value(shortName),
      longName: longName == null && nullToAbsent
          ? const Value.absent()
          : Value(longName),
      lastHeard: lastHeard == null && nullToAbsent
          ? const Value.absent()
          : Value(lastHeard),
      battery: battery == null && nullToAbsent
          ? const Value.absent()
          : Value(battery),
      snr: snr == null && nullToAbsent ? const Value.absent() : Value(snr),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      model: model == null && nullToAbsent
          ? const Value.absent()
          : Value(model),
    );
  }

  factory Node.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Node(
      num: serializer.fromJson<int>(json['num']),
      shortName: serializer.fromJson<String?>(json['shortName']),
      longName: serializer.fromJson<String?>(json['longName']),
      lastHeard: serializer.fromJson<DateTime?>(json['lastHeard']),
      battery: serializer.fromJson<int?>(json['battery']),
      snr: serializer.fromJson<double?>(json['snr']),
      role: serializer.fromJson<String?>(json['role']),
      model: serializer.fromJson<String?>(json['model']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'num': serializer.toJson<int>(num),
      'shortName': serializer.toJson<String?>(shortName),
      'longName': serializer.toJson<String?>(longName),
      'lastHeard': serializer.toJson<DateTime?>(lastHeard),
      'battery': serializer.toJson<int?>(battery),
      'snr': serializer.toJson<double?>(snr),
      'role': serializer.toJson<String?>(role),
      'model': serializer.toJson<String?>(model),
    };
  }

  Node copyWith({
    int? num,
    Value<String?> shortName = const Value.absent(),
    Value<String?> longName = const Value.absent(),
    Value<DateTime?> lastHeard = const Value.absent(),
    Value<int?> battery = const Value.absent(),
    Value<double?> snr = const Value.absent(),
    Value<String?> role = const Value.absent(),
    Value<String?> model = const Value.absent(),
  }) => Node(
    num: num ?? this.num,
    shortName: shortName.present ? shortName.value : this.shortName,
    longName: longName.present ? longName.value : this.longName,
    lastHeard: lastHeard.present ? lastHeard.value : this.lastHeard,
    battery: battery.present ? battery.value : this.battery,
    snr: snr.present ? snr.value : this.snr,
    role: role.present ? role.value : this.role,
    model: model.present ? model.value : this.model,
  );
  Node copyWithCompanion(NodesCompanion data) {
    return Node(
      num: data.num.present ? data.num.value : this.num,
      shortName: data.shortName.present ? data.shortName.value : this.shortName,
      longName: data.longName.present ? data.longName.value : this.longName,
      lastHeard: data.lastHeard.present ? data.lastHeard.value : this.lastHeard,
      battery: data.battery.present ? data.battery.value : this.battery,
      snr: data.snr.present ? data.snr.value : this.snr,
      role: data.role.present ? data.role.value : this.role,
      model: data.model.present ? data.model.value : this.model,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Node(')
          ..write('num: $num, ')
          ..write('shortName: $shortName, ')
          ..write('longName: $longName, ')
          ..write('lastHeard: $lastHeard, ')
          ..write('battery: $battery, ')
          ..write('snr: $snr, ')
          ..write('role: $role, ')
          ..write('model: $model')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    num,
    shortName,
    longName,
    lastHeard,
    battery,
    snr,
    role,
    model,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Node &&
          other.num == this.num &&
          other.shortName == this.shortName &&
          other.longName == this.longName &&
          other.lastHeard == this.lastHeard &&
          other.battery == this.battery &&
          other.snr == this.snr &&
          other.role == this.role &&
          other.model == this.model);
}

class NodesCompanion extends UpdateCompanion<Node> {
  final Value<int> num;
  final Value<String?> shortName;
  final Value<String?> longName;
  final Value<DateTime?> lastHeard;
  final Value<int?> battery;
  final Value<double?> snr;
  final Value<String?> role;
  final Value<String?> model;
  const NodesCompanion({
    this.num = const Value.absent(),
    this.shortName = const Value.absent(),
    this.longName = const Value.absent(),
    this.lastHeard = const Value.absent(),
    this.battery = const Value.absent(),
    this.snr = const Value.absent(),
    this.role = const Value.absent(),
    this.model = const Value.absent(),
  });
  NodesCompanion.insert({
    this.num = const Value.absent(),
    this.shortName = const Value.absent(),
    this.longName = const Value.absent(),
    this.lastHeard = const Value.absent(),
    this.battery = const Value.absent(),
    this.snr = const Value.absent(),
    this.role = const Value.absent(),
    this.model = const Value.absent(),
  });
  static Insertable<Node> custom({
    Expression<int>? num,
    Expression<String>? shortName,
    Expression<String>? longName,
    Expression<DateTime>? lastHeard,
    Expression<int>? battery,
    Expression<double>? snr,
    Expression<String>? role,
    Expression<String>? model,
  }) {
    return RawValuesInsertable({
      if (num != null) 'num': num,
      if (shortName != null) 'short_name': shortName,
      if (longName != null) 'long_name': longName,
      if (lastHeard != null) 'last_heard': lastHeard,
      if (battery != null) 'battery': battery,
      if (snr != null) 'snr': snr,
      if (role != null) 'role': role,
      if (model != null) 'model': model,
    });
  }

  NodesCompanion copyWith({
    Value<int>? num,
    Value<String?>? shortName,
    Value<String?>? longName,
    Value<DateTime?>? lastHeard,
    Value<int?>? battery,
    Value<double?>? snr,
    Value<String?>? role,
    Value<String?>? model,
  }) {
    return NodesCompanion(
      num: num ?? this.num,
      shortName: shortName ?? this.shortName,
      longName: longName ?? this.longName,
      lastHeard: lastHeard ?? this.lastHeard,
      battery: battery ?? this.battery,
      snr: snr ?? this.snr,
      role: role ?? this.role,
      model: model ?? this.model,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (num.present) {
      map['num'] = Variable<int>(num.value);
    }
    if (shortName.present) {
      map['short_name'] = Variable<String>(shortName.value);
    }
    if (longName.present) {
      map['long_name'] = Variable<String>(longName.value);
    }
    if (lastHeard.present) {
      map['last_heard'] = Variable<DateTime>(lastHeard.value);
    }
    if (battery.present) {
      map['battery'] = Variable<int>(battery.value);
    }
    if (snr.present) {
      map['snr'] = Variable<double>(snr.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (model.present) {
      map['model'] = Variable<String>(model.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('num: $num, ')
          ..write('shortName: $shortName, ')
          ..write('longName: $longName, ')
          ..write('lastHeard: $lastHeard, ')
          ..write('battery: $battery, ')
          ..write('snr: $snr, ')
          ..write('role: $role, ')
          ..write('model: $model')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MessagesTable messages = $MessagesTable(this);
  late final $NodesTable nodes = $NodesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [messages, nodes];
}

typedef $$MessagesTableCreateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      required int fromId,
      required int toId,
      required String content,
      Value<DateTime> timestamp,
      Value<bool> isMe,
    });
typedef $$MessagesTableUpdateCompanionBuilder =
    MessagesCompanion Function({
      Value<int> id,
      Value<int> fromId,
      Value<int> toId,
      Value<String> content,
      Value<DateTime> timestamp,
      Value<bool> isMe,
    });

class $$MessagesTableFilterComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fromId => $composableBuilder(
    column: $table.fromId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get toId => $composableBuilder(
    column: $table.toId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isMe => $composableBuilder(
    column: $table.isMe,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MessagesTableOrderingComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fromId => $composableBuilder(
    column: $table.fromId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get toId => $composableBuilder(
    column: $table.toId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isMe => $composableBuilder(
    column: $table.isMe,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MessagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MessagesTable> {
  $$MessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get fromId =>
      $composableBuilder(column: $table.fromId, builder: (column) => column);

  GeneratedColumn<int> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get isMe =>
      $composableBuilder(column: $table.isMe, builder: (column) => column);
}

class $$MessagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MessagesTable,
          Message,
          $$MessagesTableFilterComposer,
          $$MessagesTableOrderingComposer,
          $$MessagesTableAnnotationComposer,
          $$MessagesTableCreateCompanionBuilder,
          $$MessagesTableUpdateCompanionBuilder,
          (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
          Message,
          PrefetchHooks Function()
        > {
  $$MessagesTableTableManager(_$AppDatabase db, $MessagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> fromId = const Value.absent(),
                Value<int> toId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> isMe = const Value.absent(),
              }) => MessagesCompanion(
                id: id,
                fromId: fromId,
                toId: toId,
                content: content,
                timestamp: timestamp,
                isMe: isMe,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int fromId,
                required int toId,
                required String content,
                Value<DateTime> timestamp = const Value.absent(),
                Value<bool> isMe = const Value.absent(),
              }) => MessagesCompanion.insert(
                id: id,
                fromId: fromId,
                toId: toId,
                content: content,
                timestamp: timestamp,
                isMe: isMe,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MessagesTable,
      Message,
      $$MessagesTableFilterComposer,
      $$MessagesTableOrderingComposer,
      $$MessagesTableAnnotationComposer,
      $$MessagesTableCreateCompanionBuilder,
      $$MessagesTableUpdateCompanionBuilder,
      (Message, BaseReferences<_$AppDatabase, $MessagesTable, Message>),
      Message,
      PrefetchHooks Function()
    >;
typedef $$NodesTableCreateCompanionBuilder =
    NodesCompanion Function({
      Value<int> num,
      Value<String?> shortName,
      Value<String?> longName,
      Value<DateTime?> lastHeard,
      Value<int?> battery,
      Value<double?> snr,
      Value<String?> role,
      Value<String?> model,
    });
typedef $$NodesTableUpdateCompanionBuilder =
    NodesCompanion Function({
      Value<int> num,
      Value<String?> shortName,
      Value<String?> longName,
      Value<DateTime?> lastHeard,
      Value<int?> battery,
      Value<double?> snr,
      Value<String?> role,
      Value<String?> model,
    });

class $$NodesTableFilterComposer extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get num => $composableBuilder(
    column: $table.num,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get longName => $composableBuilder(
    column: $table.longName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastHeard => $composableBuilder(
    column: $table.lastHeard,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get battery => $composableBuilder(
    column: $table.battery,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get snr => $composableBuilder(
    column: $table.snr,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NodesTableOrderingComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get num => $composableBuilder(
    column: $table.num,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shortName => $composableBuilder(
    column: $table.shortName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get longName => $composableBuilder(
    column: $table.longName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastHeard => $composableBuilder(
    column: $table.lastHeard,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get battery => $composableBuilder(
    column: $table.battery,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get snr => $composableBuilder(
    column: $table.snr,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get model => $composableBuilder(
    column: $table.model,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get num =>
      $composableBuilder(column: $table.num, builder: (column) => column);

  GeneratedColumn<String> get shortName =>
      $composableBuilder(column: $table.shortName, builder: (column) => column);

  GeneratedColumn<String> get longName =>
      $composableBuilder(column: $table.longName, builder: (column) => column);

  GeneratedColumn<DateTime> get lastHeard =>
      $composableBuilder(column: $table.lastHeard, builder: (column) => column);

  GeneratedColumn<int> get battery =>
      $composableBuilder(column: $table.battery, builder: (column) => column);

  GeneratedColumn<double> get snr =>
      $composableBuilder(column: $table.snr, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<String> get model =>
      $composableBuilder(column: $table.model, builder: (column) => column);
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodesTable,
          Node,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (Node, BaseReferences<_$AppDatabase, $NodesTable, Node>),
          Node,
          PrefetchHooks Function()
        > {
  $$NodesTableTableManager(_$AppDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> num = const Value.absent(),
                Value<String?> shortName = const Value.absent(),
                Value<String?> longName = const Value.absent(),
                Value<DateTime?> lastHeard = const Value.absent(),
                Value<int?> battery = const Value.absent(),
                Value<double?> snr = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> model = const Value.absent(),
              }) => NodesCompanion(
                num: num,
                shortName: shortName,
                longName: longName,
                lastHeard: lastHeard,
                battery: battery,
                snr: snr,
                role: role,
                model: model,
              ),
          createCompanionCallback:
              ({
                Value<int> num = const Value.absent(),
                Value<String?> shortName = const Value.absent(),
                Value<String?> longName = const Value.absent(),
                Value<DateTime?> lastHeard = const Value.absent(),
                Value<int?> battery = const Value.absent(),
                Value<double?> snr = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<String?> model = const Value.absent(),
              }) => NodesCompanion.insert(
                num: num,
                shortName: shortName,
                longName: longName,
                lastHeard: lastHeard,
                battery: battery,
                snr: snr,
                role: role,
                model: model,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodesTable,
      Node,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (Node, BaseReferences<_$AppDatabase, $NodesTable, Node>),
      Node,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MessagesTableTableManager get messages =>
      $$MessagesTableTableManager(_db, _db.messages);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
}
