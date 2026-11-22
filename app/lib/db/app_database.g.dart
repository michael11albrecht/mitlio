// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $GroupsTable extends Groups with TableInfo<$GroupsTable, GroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdByMeta = const VerificationMeta(
    'createdBy',
  );
  @override
  late final GeneratedColumn<String> createdBy = GeneratedColumn<String>(
    'created_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    currency,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('created_by')) {
      context.handle(
        _createdByMeta,
        createdBy.isAcceptableOrUnknown(data['created_by']!, _createdByMeta),
      );
    } else if (isInserting) {
      context.missing(_createdByMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      createdBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_by'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $GroupsTable createAlias(String alias) {
    return $GroupsTable(attachedDatabase, alias);
  }
}

class GroupRow extends DataClass implements Insertable<GroupRow> {
  final String id;
  final String name;

  /// ISO 4217 code.
  final String currency;
  final String createdBy;
  final DateTime createdAt;
  final String updatedAt;
  final DateTime? deletedAt;
  const GroupRow({
    required this.id,
    required this.name,
    required this.currency,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['currency'] = Variable<String>(currency);
    map['created_by'] = Variable<String>(createdBy);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  GroupsCompanion toCompanion(bool nullToAbsent) {
    return GroupsCompanion(
      id: Value(id),
      name: Value(name),
      currency: Value(currency),
      createdBy: Value(createdBy),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory GroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      currency: serializer.fromJson<String>(json['currency']),
      createdBy: serializer.fromJson<String>(json['createdBy']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'currency': serializer.toJson<String>(currency),
      'createdBy': serializer.toJson<String>(createdBy),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  GroupRow copyWith({
    String? id,
    String? name,
    String? currency,
    String? createdBy,
    DateTime? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => GroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    currency: currency ?? this.currency,
    createdBy: createdBy ?? this.createdBy,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  GroupRow copyWithCompanion(GroupsCompanion data) {
    return GroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      currency: data.currency.present ? data.currency.value : this.currency,
      createdBy: data.createdBy.present ? data.createdBy.value : this.createdBy,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    currency,
    createdBy,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.currency == this.currency &&
          other.createdBy == this.createdBy &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class GroupsCompanion extends UpdateCompanion<GroupRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> currency;
  final Value<String> createdBy;
  final Value<DateTime> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const GroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.currency = const Value.absent(),
    this.createdBy = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupsCompanion.insert({
    required String id,
    required String name,
    required String currency,
    required String createdBy,
    required DateTime createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       currency = Value(currency),
       createdBy = Value(createdBy),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GroupRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? currency,
    Expression<String>? createdBy,
    Expression<DateTime>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (currency != null) 'currency': currency,
      if (createdBy != null) 'created_by': createdBy,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? currency,
    Value<String>? createdBy,
    Value<DateTime>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return GroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      currency: currency ?? this.currency,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (createdBy.present) {
      map['created_by'] = Variable<String>(createdBy.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('currency: $currency, ')
          ..write('createdBy: $createdBy, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembersTable extends Members with TableInfo<$MembersTable, MemberRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paypalMeMeta = const VerificationMeta(
    'paypalMe',
  );
  @override
  late final GeneratedColumn<String> paypalMe = GeneratedColumn<String>(
    'paypal_me',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ibanHintMeta = const VerificationMeta(
    'ibanHint',
  );
  @override
  late final GeneratedColumn<String> ibanHint = GeneratedColumn<String>(
    'iban_hint',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _canDriveMeta = const VerificationMeta(
    'canDrive',
  );
  @override
  late final GeneratedColumn<bool> canDrive = GeneratedColumn<bool>(
    'can_drive',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("can_drive" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    position,
    paypalMe,
    userId,
    ibanHint,
    canDrive,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'members';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemberRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('paypal_me')) {
      context.handle(
        _paypalMeMeta,
        paypalMe.isAcceptableOrUnknown(data['paypal_me']!, _paypalMeMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('iban_hint')) {
      context.handle(
        _ibanHintMeta,
        ibanHint.isAcceptableOrUnknown(data['iban_hint']!, _ibanHintMeta),
      );
    }
    if (data.containsKey('can_drive')) {
      context.handle(
        _canDriveMeta,
        canDrive.isAcceptableOrUnknown(data['can_drive']!, _canDriveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemberRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemberRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      paypalMe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paypal_me'],
      ),
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      ),
      ibanHint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iban_hint'],
      ),
      canDrive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}can_drive'],
      )!,
    );
  }

  @override
  $MembersTable createAlias(String alias) {
    return $MembersTable(attachedDatabase, alias);
  }
}

class MemberRow extends DataClass implements Insertable<MemberRow> {
  /// UUIDv7 generated on the client.
  final String id;
  final String groupId;

  /// Creation time, UTC.
  final DateTime createdAt;

  /// Hybrid logical clock string.
  final String updatedAt;

  /// Soft delete marker; null while the row is live.
  final DateTime? deletedAt;
  final String name;
  final int position;
  final String? paypalMe;

  /// Null until the member is linked to an account (P6).
  final String? userId;

  /// Masked hint only; the full IBAN lives in [LocalMemberBank].
  final String? ibanHint;

  /// Whether this member drives; only drivers are suggested as next driver.
  final bool canDrive;
  const MemberRow({
    required this.id,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.position,
    this.paypalMe,
    this.userId,
    this.ibanHint,
    required this.canDrive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || paypalMe != null) {
      map['paypal_me'] = Variable<String>(paypalMe);
    }
    if (!nullToAbsent || userId != null) {
      map['user_id'] = Variable<String>(userId);
    }
    if (!nullToAbsent || ibanHint != null) {
      map['iban_hint'] = Variable<String>(ibanHint);
    }
    map['can_drive'] = Variable<bool>(canDrive);
    return map;
  }

  MembersCompanion toCompanion(bool nullToAbsent) {
    return MembersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      position: Value(position),
      paypalMe: paypalMe == null && nullToAbsent
          ? const Value.absent()
          : Value(paypalMe),
      userId: userId == null && nullToAbsent
          ? const Value.absent()
          : Value(userId),
      ibanHint: ibanHint == null && nullToAbsent
          ? const Value.absent()
          : Value(ibanHint),
      canDrive: Value(canDrive),
    );
  }

  factory MemberRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemberRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      paypalMe: serializer.fromJson<String?>(json['paypalMe']),
      userId: serializer.fromJson<String?>(json['userId']),
      ibanHint: serializer.fromJson<String?>(json['ibanHint']),
      canDrive: serializer.fromJson<bool>(json['canDrive']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'paypalMe': serializer.toJson<String?>(paypalMe),
      'userId': serializer.toJson<String?>(userId),
      'ibanHint': serializer.toJson<String?>(ibanHint),
      'canDrive': serializer.toJson<bool>(canDrive),
    };
  }

  MemberRow copyWith({
    String? id,
    String? groupId,
    DateTime? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    int? position,
    Value<String?> paypalMe = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    Value<String?> ibanHint = const Value.absent(),
    bool? canDrive,
  }) => MemberRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    position: position ?? this.position,
    paypalMe: paypalMe.present ? paypalMe.value : this.paypalMe,
    userId: userId.present ? userId.value : this.userId,
    ibanHint: ibanHint.present ? ibanHint.value : this.ibanHint,
    canDrive: canDrive ?? this.canDrive,
  );
  MemberRow copyWithCompanion(MembersCompanion data) {
    return MemberRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      paypalMe: data.paypalMe.present ? data.paypalMe.value : this.paypalMe,
      userId: data.userId.present ? data.userId.value : this.userId,
      ibanHint: data.ibanHint.present ? data.ibanHint.value : this.ibanHint,
      canDrive: data.canDrive.present ? data.canDrive.value : this.canDrive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemberRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('paypalMe: $paypalMe, ')
          ..write('userId: $userId, ')
          ..write('ibanHint: $ibanHint, ')
          ..write('canDrive: $canDrive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    position,
    paypalMe,
    userId,
    ibanHint,
    canDrive,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemberRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.position == this.position &&
          other.paypalMe == this.paypalMe &&
          other.userId == this.userId &&
          other.ibanHint == this.ibanHint &&
          other.canDrive == this.canDrive);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<DateTime> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<int> position;
  final Value<String?> paypalMe;
  final Value<String?> userId;
  final Value<String?> ibanHint;
  final Value<bool> canDrive;
  final Value<int> rowid;
  const MembersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.paypalMe = const Value.absent(),
    this.userId = const Value.absent(),
    this.ibanHint = const Value.absent(),
    this.canDrive = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String groupId,
    required DateTime createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required int position,
    this.paypalMe = const Value.absent(),
    this.userId = const Value.absent(),
    this.ibanHint = const Value.absent(),
    this.canDrive = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       position = Value(position);
  static Insertable<MemberRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<DateTime>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<int>? position,
    Expression<String>? paypalMe,
    Expression<String>? userId,
    Expression<String>? ibanHint,
    Expression<bool>? canDrive,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (paypalMe != null) 'paypal_me': paypalMe,
      if (userId != null) 'user_id': userId,
      if (ibanHint != null) 'iban_hint': ibanHint,
      if (canDrive != null) 'can_drive': canDrive,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<DateTime>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<int>? position,
    Value<String?>? paypalMe,
    Value<String?>? userId,
    Value<String?>? ibanHint,
    Value<bool>? canDrive,
    Value<int>? rowid,
  }) {
    return MembersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      position: position ?? this.position,
      paypalMe: paypalMe ?? this.paypalMe,
      userId: userId ?? this.userId,
      ibanHint: ibanHint ?? this.ibanHint,
      canDrive: canDrive ?? this.canDrive,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (paypalMe.present) {
      map['paypal_me'] = Variable<String>(paypalMe.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (ibanHint.present) {
      map['iban_hint'] = Variable<String>(ibanHint.value);
    }
    if (canDrive.present) {
      map['can_drive'] = Variable<bool>(canDrive.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembersCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('paypalMe: $paypalMe, ')
          ..write('userId: $userId, ')
          ..write('ibanHint: $ibanHint, ')
          ..write('canDrive: $canDrive, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses
    with TableInfo<$ExpensesTable, ExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    check: () => ComparableExpr(amountCents).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fxRatePpmMeta = const VerificationMeta(
    'fxRatePpm',
  );
  @override
  late final GeneratedColumn<int> fxRatePpm = GeneratedColumn<int>(
    'fx_rate_ppm',
    aliasedName,
    false,
    check: () => ComparableExpr(fxRatePpm).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupAmountCentsMeta = const VerificationMeta(
    'groupAmountCents',
  );
  @override
  late final GeneratedColumn<int> groupAmountCents = GeneratedColumn<int>(
    'group_amount_cents',
    aliasedName,
    false,
    check: () => ComparableExpr(groupAmountCents).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    check: () => type.isIn(const ['regular', 'trip', 'settlement']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _splitModeMeta = const VerificationMeta(
    'splitMode',
  );
  @override
  late final GeneratedColumn<String> splitMode = GeneratedColumn<String>(
    'split_mode',
    aliasedName,
    false,
    check: () => splitMode.isIn(const ['equal', 'shares', 'percent', 'exact']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tripMetaMeta = const VerificationMeta(
    'tripMeta',
  );
  @override
  late final GeneratedColumn<String> tripMeta = GeneratedColumn<String>(
    'trip_meta',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    title,
    amountCents,
    currency,
    fxRatePpm,
    groupAmountCents,
    date,
    category,
    type,
    splitMode,
    tripMeta,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('fx_rate_ppm')) {
      context.handle(
        _fxRatePpmMeta,
        fxRatePpm.isAcceptableOrUnknown(data['fx_rate_ppm']!, _fxRatePpmMeta),
      );
    } else if (isInserting) {
      context.missing(_fxRatePpmMeta);
    }
    if (data.containsKey('group_amount_cents')) {
      context.handle(
        _groupAmountCentsMeta,
        groupAmountCents.isAcceptableOrUnknown(
          data['group_amount_cents']!,
          _groupAmountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_groupAmountCentsMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('split_mode')) {
      context.handle(
        _splitModeMeta,
        splitMode.isAcceptableOrUnknown(data['split_mode']!, _splitModeMeta),
      );
    } else if (isInserting) {
      context.missing(_splitModeMeta);
    }
    if (data.containsKey('trip_meta')) {
      context.handle(
        _tripMetaMeta,
        tripMeta.isAcceptableOrUnknown(data['trip_meta']!, _tripMetaMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      fxRatePpm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fx_rate_ppm'],
      )!,
      groupAmountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}group_amount_cents'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      splitMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_mode'],
      )!,
      tripMeta: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_meta'],
      ),
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class ExpenseRow extends DataClass implements Insertable<ExpenseRow> {
  /// UUIDv7 generated on the client.
  final String id;
  final String groupId;

  /// Creation time, UTC.
  final DateTime createdAt;

  /// Hybrid logical clock string.
  final String updatedAt;

  /// Soft delete marker; null while the row is live.
  final DateTime? deletedAt;
  final String title;
  final int amountCents;
  final String currency;

  /// Frozen FX rate, parts per million (1_000_000 == same currency).
  final int fxRatePpm;
  final int groupAmountCents;
  final DateTime date;
  final String? category;
  final String type;
  final String splitMode;

  /// JSON-encoded trip metadata (SQLite has no jsonb).
  final String? tripMeta;
  const ExpenseRow({
    required this.id,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.title,
    required this.amountCents,
    required this.currency,
    required this.fxRatePpm,
    required this.groupAmountCents,
    required this.date,
    this.category,
    required this.type,
    required this.splitMode,
    this.tripMeta,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['title'] = Variable<String>(title);
    map['amount_cents'] = Variable<int>(amountCents);
    map['currency'] = Variable<String>(currency);
    map['fx_rate_ppm'] = Variable<int>(fxRatePpm);
    map['group_amount_cents'] = Variable<int>(groupAmountCents);
    map['date'] = Variable<DateTime>(date);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['type'] = Variable<String>(type);
    map['split_mode'] = Variable<String>(splitMode);
    if (!nullToAbsent || tripMeta != null) {
      map['trip_meta'] = Variable<String>(tripMeta);
    }
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      title: Value(title),
      amountCents: Value(amountCents),
      currency: Value(currency),
      fxRatePpm: Value(fxRatePpm),
      groupAmountCents: Value(groupAmountCents),
      date: Value(date),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      type: Value(type),
      splitMode: Value(splitMode),
      tripMeta: tripMeta == null && nullToAbsent
          ? const Value.absent()
          : Value(tripMeta),
    );
  }

  factory ExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      title: serializer.fromJson<String>(json['title']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      currency: serializer.fromJson<String>(json['currency']),
      fxRatePpm: serializer.fromJson<int>(json['fxRatePpm']),
      groupAmountCents: serializer.fromJson<int>(json['groupAmountCents']),
      date: serializer.fromJson<DateTime>(json['date']),
      category: serializer.fromJson<String?>(json['category']),
      type: serializer.fromJson<String>(json['type']),
      splitMode: serializer.fromJson<String>(json['splitMode']),
      tripMeta: serializer.fromJson<String?>(json['tripMeta']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'title': serializer.toJson<String>(title),
      'amountCents': serializer.toJson<int>(amountCents),
      'currency': serializer.toJson<String>(currency),
      'fxRatePpm': serializer.toJson<int>(fxRatePpm),
      'groupAmountCents': serializer.toJson<int>(groupAmountCents),
      'date': serializer.toJson<DateTime>(date),
      'category': serializer.toJson<String?>(category),
      'type': serializer.toJson<String>(type),
      'splitMode': serializer.toJson<String>(splitMode),
      'tripMeta': serializer.toJson<String?>(tripMeta),
    };
  }

  ExpenseRow copyWith({
    String? id,
    String? groupId,
    DateTime? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? title,
    int? amountCents,
    String? currency,
    int? fxRatePpm,
    int? groupAmountCents,
    DateTime? date,
    Value<String?> category = const Value.absent(),
    String? type,
    String? splitMode,
    Value<String?> tripMeta = const Value.absent(),
  }) => ExpenseRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    title: title ?? this.title,
    amountCents: amountCents ?? this.amountCents,
    currency: currency ?? this.currency,
    fxRatePpm: fxRatePpm ?? this.fxRatePpm,
    groupAmountCents: groupAmountCents ?? this.groupAmountCents,
    date: date ?? this.date,
    category: category.present ? category.value : this.category,
    type: type ?? this.type,
    splitMode: splitMode ?? this.splitMode,
    tripMeta: tripMeta.present ? tripMeta.value : this.tripMeta,
  );
  ExpenseRow copyWithCompanion(ExpensesCompanion data) {
    return ExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      title: data.title.present ? data.title.value : this.title,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      currency: data.currency.present ? data.currency.value : this.currency,
      fxRatePpm: data.fxRatePpm.present ? data.fxRatePpm.value : this.fxRatePpm,
      groupAmountCents: data.groupAmountCents.present
          ? data.groupAmountCents.value
          : this.groupAmountCents,
      date: data.date.present ? data.date.value : this.date,
      category: data.category.present ? data.category.value : this.category,
      type: data.type.present ? data.type.value : this.type,
      splitMode: data.splitMode.present ? data.splitMode.value : this.splitMode,
      tripMeta: data.tripMeta.present ? data.tripMeta.value : this.tripMeta,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('amountCents: $amountCents, ')
          ..write('currency: $currency, ')
          ..write('fxRatePpm: $fxRatePpm, ')
          ..write('groupAmountCents: $groupAmountCents, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('splitMode: $splitMode, ')
          ..write('tripMeta: $tripMeta')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    title,
    amountCents,
    currency,
    fxRatePpm,
    groupAmountCents,
    date,
    category,
    type,
    splitMode,
    tripMeta,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.title == this.title &&
          other.amountCents == this.amountCents &&
          other.currency == this.currency &&
          other.fxRatePpm == this.fxRatePpm &&
          other.groupAmountCents == this.groupAmountCents &&
          other.date == this.date &&
          other.category == this.category &&
          other.type == this.type &&
          other.splitMode == this.splitMode &&
          other.tripMeta == this.tripMeta);
}

class ExpensesCompanion extends UpdateCompanion<ExpenseRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<DateTime> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> title;
  final Value<int> amountCents;
  final Value<String> currency;
  final Value<int> fxRatePpm;
  final Value<int> groupAmountCents;
  final Value<DateTime> date;
  final Value<String?> category;
  final Value<String> type;
  final Value<String> splitMode;
  final Value<String?> tripMeta;
  final Value<int> rowid;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.fxRatePpm = const Value.absent(),
    this.groupAmountCents = const Value.absent(),
    this.date = const Value.absent(),
    this.category = const Value.absent(),
    this.type = const Value.absent(),
    this.splitMode = const Value.absent(),
    this.tripMeta = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensesCompanion.insert({
    required String id,
    required String groupId,
    required DateTime createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String title,
    required int amountCents,
    required String currency,
    required int fxRatePpm,
    required int groupAmountCents,
    required DateTime date,
    this.category = const Value.absent(),
    required String type,
    required String splitMode,
    this.tripMeta = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       title = Value(title),
       amountCents = Value(amountCents),
       currency = Value(currency),
       fxRatePpm = Value(fxRatePpm),
       groupAmountCents = Value(groupAmountCents),
       date = Value(date),
       type = Value(type),
       splitMode = Value(splitMode);
  static Insertable<ExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<DateTime>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? title,
    Expression<int>? amountCents,
    Expression<String>? currency,
    Expression<int>? fxRatePpm,
    Expression<int>? groupAmountCents,
    Expression<DateTime>? date,
    Expression<String>? category,
    Expression<String>? type,
    Expression<String>? splitMode,
    Expression<String>? tripMeta,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (title != null) 'title': title,
      if (amountCents != null) 'amount_cents': amountCents,
      if (currency != null) 'currency': currency,
      if (fxRatePpm != null) 'fx_rate_ppm': fxRatePpm,
      if (groupAmountCents != null) 'group_amount_cents': groupAmountCents,
      if (date != null) 'date': date,
      if (category != null) 'category': category,
      if (type != null) 'type': type,
      if (splitMode != null) 'split_mode': splitMode,
      if (tripMeta != null) 'trip_meta': tripMeta,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<DateTime>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? title,
    Value<int>? amountCents,
    Value<String>? currency,
    Value<int>? fxRatePpm,
    Value<int>? groupAmountCents,
    Value<DateTime>? date,
    Value<String?>? category,
    Value<String>? type,
    Value<String>? splitMode,
    Value<String?>? tripMeta,
    Value<int>? rowid,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      fxRatePpm: fxRatePpm ?? this.fxRatePpm,
      groupAmountCents: groupAmountCents ?? this.groupAmountCents,
      date: date ?? this.date,
      category: category ?? this.category,
      type: type ?? this.type,
      splitMode: splitMode ?? this.splitMode,
      tripMeta: tripMeta ?? this.tripMeta,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (fxRatePpm.present) {
      map['fx_rate_ppm'] = Variable<int>(fxRatePpm.value);
    }
    if (groupAmountCents.present) {
      map['group_amount_cents'] = Variable<int>(groupAmountCents.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (splitMode.present) {
      map['split_mode'] = Variable<String>(splitMode.value);
    }
    if (tripMeta.present) {
      map['trip_meta'] = Variable<String>(tripMeta.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('amountCents: $amountCents, ')
          ..write('currency: $currency, ')
          ..write('fxRatePpm: $fxRatePpm, ')
          ..write('groupAmountCents: $groupAmountCents, ')
          ..write('date: $date, ')
          ..write('category: $category, ')
          ..write('type: $type, ')
          ..write('splitMode: $splitMode, ')
          ..write('tripMeta: $tripMeta, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpensePayersTable extends ExpensePayers
    with TableInfo<$ExpensePayersTable, ExpensePayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensePayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expenses (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _paidCentsMeta = const VerificationMeta(
    'paidCents',
  );
  @override
  late final GeneratedColumn<int> paidCents = GeneratedColumn<int>(
    'paid_cents',
    aliasedName,
    false,
    check: () => ComparableExpr(paidCents).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    expenseId,
    memberId,
    paidCents,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_payers';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpensePayerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('paid_cents')) {
      context.handle(
        _paidCentsMeta,
        paidCents.isAcceptableOrUnknown(data['paid_cents']!, _paidCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_paidCentsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {expenseId, memberId};
  @override
  ExpensePayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpensePayerRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      paidCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paid_cents'],
      )!,
    );
  }

  @override
  $ExpensePayersTable createAlias(String alias) {
    return $ExpensePayersTable(attachedDatabase, alias);
  }
}

class ExpensePayerRow extends DataClass implements Insertable<ExpensePayerRow> {
  /// Aggregate child: no own sync metadata, replaced wholesale with the
  /// parent expense. `group_id` is kept for RLS later.
  final String groupId;
  final String expenseId;
  final String memberId;
  final int paidCents;
  const ExpensePayerRow({
    required this.groupId,
    required this.expenseId,
    required this.memberId,
    required this.paidCents,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['paid_cents'] = Variable<int>(paidCents);
    return map;
  }

  ExpensePayersCompanion toCompanion(bool nullToAbsent) {
    return ExpensePayersCompanion(
      groupId: Value(groupId),
      expenseId: Value(expenseId),
      memberId: Value(memberId),
      paidCents: Value(paidCents),
    );
  }

  factory ExpensePayerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpensePayerRow(
      groupId: serializer.fromJson<String>(json['groupId']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      paidCents: serializer.fromJson<int>(json['paidCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'expenseId': serializer.toJson<String>(expenseId),
      'memberId': serializer.toJson<String>(memberId),
      'paidCents': serializer.toJson<int>(paidCents),
    };
  }

  ExpensePayerRow copyWith({
    String? groupId,
    String? expenseId,
    String? memberId,
    int? paidCents,
  }) => ExpensePayerRow(
    groupId: groupId ?? this.groupId,
    expenseId: expenseId ?? this.expenseId,
    memberId: memberId ?? this.memberId,
    paidCents: paidCents ?? this.paidCents,
  );
  ExpensePayerRow copyWithCompanion(ExpensePayersCompanion data) {
    return ExpensePayerRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      paidCents: data.paidCents.present ? data.paidCents.value : this.paidCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpensePayerRow(')
          ..write('groupId: $groupId, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('paidCents: $paidCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, expenseId, memberId, paidCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpensePayerRow &&
          other.groupId == this.groupId &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.paidCents == this.paidCents);
}

class ExpensePayersCompanion extends UpdateCompanion<ExpensePayerRow> {
  final Value<String> groupId;
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<int> paidCents;
  final Value<int> rowid;
  const ExpensePayersCompanion({
    this.groupId = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.paidCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensePayersCompanion.insert({
    required String groupId,
    required String expenseId,
    required String memberId,
    required int paidCents,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       expenseId = Value(expenseId),
       memberId = Value(memberId),
       paidCents = Value(paidCents);
  static Insertable<ExpensePayerRow> custom({
    Expression<String>? groupId,
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<int>? paidCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (paidCents != null) 'paid_cents': paidCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensePayersCompanion copyWith({
    Value<String>? groupId,
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<int>? paidCents,
    Value<int>? rowid,
  }) {
    return ExpensePayersCompanion(
      groupId: groupId ?? this.groupId,
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      paidCents: paidCents ?? this.paidCents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (paidCents.present) {
      map['paid_cents'] = Variable<int>(paidCents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensePayersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('paidCents: $paidCents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpenseSharesTable extends ExpenseShares
    with TableInfo<$ExpenseSharesTable, ExpenseShareRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseSharesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expenses (id)',
    ),
  );
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _shareCentsMeta = const VerificationMeta(
    'shareCents',
  );
  @override
  late final GeneratedColumn<int> shareCents = GeneratedColumn<int>(
    'share_cents',
    aliasedName,
    false,
    check: () => ComparableExpr(shareCents).isBiggerThanValue(-1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _weightMeta = const VerificationMeta('weight');
  @override
  late final GeneratedColumn<int> weight = GeneratedColumn<int>(
    'weight',
    aliasedName,
    false,
    check: () => ComparableExpr(weight).isBiggerThanValue(-1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    expenseId,
    memberId,
    shareCents,
    weight,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_shares';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseShareRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('share_cents')) {
      context.handle(
        _shareCentsMeta,
        shareCents.isAcceptableOrUnknown(data['share_cents']!, _shareCentsMeta),
      );
    } else if (isInserting) {
      context.missing(_shareCentsMeta);
    }
    if (data.containsKey('weight')) {
      context.handle(
        _weightMeta,
        weight.isAcceptableOrUnknown(data['weight']!, _weightMeta),
      );
    } else if (isInserting) {
      context.missing(_weightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {expenseId, memberId};
  @override
  ExpenseShareRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseShareRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      shareCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}share_cents'],
      )!,
      weight: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weight'],
      )!,
    );
  }

  @override
  $ExpenseSharesTable createAlias(String alias) {
    return $ExpenseSharesTable(attachedDatabase, alias);
  }
}

class ExpenseShareRow extends DataClass implements Insertable<ExpenseShareRow> {
  /// Aggregate child: no own sync metadata, replaced wholesale with the
  /// parent expense. `group_id` is kept for RLS later.
  final String groupId;
  final String expenseId;
  final String memberId;
  final int shareCents;

  /// Weight / basis points for share and percent modes (re-editing).
  final int weight;
  const ExpenseShareRow({
    required this.groupId,
    required this.expenseId,
    required this.memberId,
    required this.shareCents,
    required this.weight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['share_cents'] = Variable<int>(shareCents);
    map['weight'] = Variable<int>(weight);
    return map;
  }

  ExpenseSharesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseSharesCompanion(
      groupId: Value(groupId),
      expenseId: Value(expenseId),
      memberId: Value(memberId),
      shareCents: Value(shareCents),
      weight: Value(weight),
    );
  }

  factory ExpenseShareRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseShareRow(
      groupId: serializer.fromJson<String>(json['groupId']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      shareCents: serializer.fromJson<int>(json['shareCents']),
      weight: serializer.fromJson<int>(json['weight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'expenseId': serializer.toJson<String>(expenseId),
      'memberId': serializer.toJson<String>(memberId),
      'shareCents': serializer.toJson<int>(shareCents),
      'weight': serializer.toJson<int>(weight),
    };
  }

  ExpenseShareRow copyWith({
    String? groupId,
    String? expenseId,
    String? memberId,
    int? shareCents,
    int? weight,
  }) => ExpenseShareRow(
    groupId: groupId ?? this.groupId,
    expenseId: expenseId ?? this.expenseId,
    memberId: memberId ?? this.memberId,
    shareCents: shareCents ?? this.shareCents,
    weight: weight ?? this.weight,
  );
  ExpenseShareRow copyWithCompanion(ExpenseSharesCompanion data) {
    return ExpenseShareRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      shareCents: data.shareCents.present
          ? data.shareCents.value
          : this.shareCents,
      weight: data.weight.present ? data.weight.value : this.weight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseShareRow(')
          ..write('groupId: $groupId, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('shareCents: $shareCents, ')
          ..write('weight: $weight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(groupId, expenseId, memberId, shareCents, weight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseShareRow &&
          other.groupId == this.groupId &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.shareCents == this.shareCents &&
          other.weight == this.weight);
}

class ExpenseSharesCompanion extends UpdateCompanion<ExpenseShareRow> {
  final Value<String> groupId;
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<int> shareCents;
  final Value<int> weight;
  final Value<int> rowid;
  const ExpenseSharesCompanion({
    this.groupId = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.shareCents = const Value.absent(),
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseSharesCompanion.insert({
    required String groupId,
    required String expenseId,
    required String memberId,
    required int shareCents,
    required int weight,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       expenseId = Value(expenseId),
       memberId = Value(memberId),
       shareCents = Value(shareCents),
       weight = Value(weight);
  static Insertable<ExpenseShareRow> custom({
    Expression<String>? groupId,
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<int>? shareCents,
    Expression<int>? weight,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (shareCents != null) 'share_cents': shareCents,
      if (weight != null) 'weight': weight,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseSharesCompanion copyWith({
    Value<String>? groupId,
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<int>? shareCents,
    Value<int>? weight,
    Value<int>? rowid,
  }) {
    return ExpenseSharesCompanion(
      groupId: groupId ?? this.groupId,
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      shareCents: shareCents ?? this.shareCents,
      weight: weight ?? this.weight,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (shareCents.present) {
      map['share_cents'] = Variable<int>(shareCents.value);
    }
    if (weight.present) {
      map['weight'] = Variable<int>(weight.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseSharesCompanion(')
          ..write('groupId: $groupId, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('shareCents: $shareCents, ')
          ..write('weight: $weight, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettlementsTable extends Settlements
    with TableInfo<$SettlementsTable, SettlementRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettlementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fromMemberMeta = const VerificationMeta(
    'fromMember',
  );
  @override
  late final GeneratedColumn<String> fromMember = GeneratedColumn<String>(
    'from_member',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _toMemberMeta = const VerificationMeta(
    'toMember',
  );
  @override
  late final GeneratedColumn<String> toMember = GeneratedColumn<String>(
    'to_member',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    check: () => ComparableExpr(amountCents).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyMeta = const VerificationMeta(
    'currency',
  );
  @override
  late final GeneratedColumn<String> currency = GeneratedColumn<String>(
    'currency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    check: () => method.isIn(const ['paypal', 'sepa', 'cash', 'other']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    fromMember,
    toMember,
    amountCents,
    currency,
    date,
    method,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settlements';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettlementRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('from_member')) {
      context.handle(
        _fromMemberMeta,
        fromMember.isAcceptableOrUnknown(data['from_member']!, _fromMemberMeta),
      );
    } else if (isInserting) {
      context.missing(_fromMemberMeta);
    }
    if (data.containsKey('to_member')) {
      context.handle(
        _toMemberMeta,
        toMember.isAcceptableOrUnknown(data['to_member']!, _toMemberMeta),
      );
    } else if (isInserting) {
      context.missing(_toMemberMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('currency')) {
      context.handle(
        _currencyMeta,
        currency.isAcceptableOrUnknown(data['currency']!, _currencyMeta),
      );
    } else if (isInserting) {
      context.missing(_currencyMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettlementRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettlementRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      fromMember: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_member'],
      )!,
      toMember: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_member'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      currency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
    );
  }

  @override
  $SettlementsTable createAlias(String alias) {
    return $SettlementsTable(attachedDatabase, alias);
  }
}

class SettlementRow extends DataClass implements Insertable<SettlementRow> {
  /// UUIDv7 generated on the client.
  final String id;
  final String groupId;

  /// Creation time, UTC.
  final DateTime createdAt;

  /// Hybrid logical clock string.
  final String updatedAt;

  /// Soft delete marker; null while the row is live.
  final DateTime? deletedAt;
  final String fromMember;
  final String toMember;
  final int amountCents;
  final String currency;
  final DateTime date;
  final String method;
  const SettlementRow({
    required this.id,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.fromMember,
    required this.toMember,
    required this.amountCents,
    required this.currency,
    required this.date,
    required this.method,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['from_member'] = Variable<String>(fromMember);
    map['to_member'] = Variable<String>(toMember);
    map['amount_cents'] = Variable<int>(amountCents);
    map['currency'] = Variable<String>(currency);
    map['date'] = Variable<DateTime>(date);
    map['method'] = Variable<String>(method);
    return map;
  }

  SettlementsCompanion toCompanion(bool nullToAbsent) {
    return SettlementsCompanion(
      id: Value(id),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      fromMember: Value(fromMember),
      toMember: Value(toMember),
      amountCents: Value(amountCents),
      currency: Value(currency),
      date: Value(date),
      method: Value(method),
    );
  }

  factory SettlementRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettlementRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      fromMember: serializer.fromJson<String>(json['fromMember']),
      toMember: serializer.fromJson<String>(json['toMember']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      currency: serializer.fromJson<String>(json['currency']),
      date: serializer.fromJson<DateTime>(json['date']),
      method: serializer.fromJson<String>(json['method']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'fromMember': serializer.toJson<String>(fromMember),
      'toMember': serializer.toJson<String>(toMember),
      'amountCents': serializer.toJson<int>(amountCents),
      'currency': serializer.toJson<String>(currency),
      'date': serializer.toJson<DateTime>(date),
      'method': serializer.toJson<String>(method),
    };
  }

  SettlementRow copyWith({
    String? id,
    String? groupId,
    DateTime? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? fromMember,
    String? toMember,
    int? amountCents,
    String? currency,
    DateTime? date,
    String? method,
  }) => SettlementRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    fromMember: fromMember ?? this.fromMember,
    toMember: toMember ?? this.toMember,
    amountCents: amountCents ?? this.amountCents,
    currency: currency ?? this.currency,
    date: date ?? this.date,
    method: method ?? this.method,
  );
  SettlementRow copyWithCompanion(SettlementsCompanion data) {
    return SettlementRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      fromMember: data.fromMember.present
          ? data.fromMember.value
          : this.fromMember,
      toMember: data.toMember.present ? data.toMember.value : this.toMember,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      currency: data.currency.present ? data.currency.value : this.currency,
      date: data.date.present ? data.date.value : this.date,
      method: data.method.present ? data.method.value : this.method,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettlementRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('fromMember: $fromMember, ')
          ..write('toMember: $toMember, ')
          ..write('amountCents: $amountCents, ')
          ..write('currency: $currency, ')
          ..write('date: $date, ')
          ..write('method: $method')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    fromMember,
    toMember,
    amountCents,
    currency,
    date,
    method,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettlementRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.fromMember == this.fromMember &&
          other.toMember == this.toMember &&
          other.amountCents == this.amountCents &&
          other.currency == this.currency &&
          other.date == this.date &&
          other.method == this.method);
}

class SettlementsCompanion extends UpdateCompanion<SettlementRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<DateTime> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> fromMember;
  final Value<String> toMember;
  final Value<int> amountCents;
  final Value<String> currency;
  final Value<DateTime> date;
  final Value<String> method;
  final Value<int> rowid;
  const SettlementsCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.fromMember = const Value.absent(),
    this.toMember = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.currency = const Value.absent(),
    this.date = const Value.absent(),
    this.method = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettlementsCompanion.insert({
    required String id,
    required String groupId,
    required DateTime createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String fromMember,
    required String toMember,
    required int amountCents,
    required String currency,
    required DateTime date,
    required String method,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       fromMember = Value(fromMember),
       toMember = Value(toMember),
       amountCents = Value(amountCents),
       currency = Value(currency),
       date = Value(date),
       method = Value(method);
  static Insertable<SettlementRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<DateTime>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? fromMember,
    Expression<String>? toMember,
    Expression<int>? amountCents,
    Expression<String>? currency,
    Expression<DateTime>? date,
    Expression<String>? method,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (fromMember != null) 'from_member': fromMember,
      if (toMember != null) 'to_member': toMember,
      if (amountCents != null) 'amount_cents': amountCents,
      if (currency != null) 'currency': currency,
      if (date != null) 'date': date,
      if (method != null) 'method': method,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettlementsCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<DateTime>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? fromMember,
    Value<String>? toMember,
    Value<int>? amountCents,
    Value<String>? currency,
    Value<DateTime>? date,
    Value<String>? method,
    Value<int>? rowid,
  }) {
    return SettlementsCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      fromMember: fromMember ?? this.fromMember,
      toMember: toMember ?? this.toMember,
      amountCents: amountCents ?? this.amountCents,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      method: method ?? this.method,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (fromMember.present) {
      map['from_member'] = Variable<String>(fromMember.value);
    }
    if (toMember.present) {
      map['to_member'] = Variable<String>(toMember.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (currency.present) {
      map['currency'] = Variable<String>(currency.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettlementsCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('fromMember: $fromMember, ')
          ..write('toMember: $toMember, ')
          ..write('amountCents: $amountCents, ')
          ..write('currency: $currency, ')
          ..write('date: $date, ')
          ..write('method: $method, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMemberBankTable extends LocalMemberBank
    with TableInfo<$LocalMemberBankTable, LocalMemberBankRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMemberBankTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _ibanMeta = const VerificationMeta('iban');
  @override
  late final GeneratedColumn<String> iban = GeneratedColumn<String>(
    'iban',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bicMeta = const VerificationMeta('bic');
  @override
  late final GeneratedColumn<String> bic = GeneratedColumn<String>(
    'bic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    memberId,
    iban,
    bic,
    accountName,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_member_bank';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMemberBankRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('iban')) {
      context.handle(
        _ibanMeta,
        iban.isAcceptableOrUnknown(data['iban']!, _ibanMeta),
      );
    } else if (isInserting) {
      context.missing(_ibanMeta);
    }
    if (data.containsKey('bic')) {
      context.handle(
        _bicMeta,
        bic.isAcceptableOrUnknown(data['bic']!, _bicMeta),
      );
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId};
  @override
  LocalMemberBankRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMemberBankRow(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      iban: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iban'],
      )!,
      bic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bic'],
      ),
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalMemberBankTable createAlias(String alias) {
    return $LocalMemberBankTable(attachedDatabase, alias);
  }
}

class LocalMemberBankRow extends DataClass
    implements Insertable<LocalMemberBankRow> {
  final String memberId;
  final String iban;

  /// Needed for EPC QR payloads (P4-T01).
  final String? bic;
  final String? accountName;
  final String updatedAt;
  const LocalMemberBankRow({
    required this.memberId,
    required this.iban,
    this.bic,
    this.accountName,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['iban'] = Variable<String>(iban);
    if (!nullToAbsent || bic != null) {
      map['bic'] = Variable<String>(bic);
    }
    if (!nullToAbsent || accountName != null) {
      map['account_name'] = Variable<String>(accountName);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  LocalMemberBankCompanion toCompanion(bool nullToAbsent) {
    return LocalMemberBankCompanion(
      memberId: Value(memberId),
      iban: Value(iban),
      bic: bic == null && nullToAbsent ? const Value.absent() : Value(bic),
      accountName: accountName == null && nullToAbsent
          ? const Value.absent()
          : Value(accountName),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMemberBankRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMemberBankRow(
      memberId: serializer.fromJson<String>(json['memberId']),
      iban: serializer.fromJson<String>(json['iban']),
      bic: serializer.fromJson<String?>(json['bic']),
      accountName: serializer.fromJson<String?>(json['accountName']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'iban': serializer.toJson<String>(iban),
      'bic': serializer.toJson<String?>(bic),
      'accountName': serializer.toJson<String?>(accountName),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  LocalMemberBankRow copyWith({
    String? memberId,
    String? iban,
    Value<String?> bic = const Value.absent(),
    Value<String?> accountName = const Value.absent(),
    String? updatedAt,
  }) => LocalMemberBankRow(
    memberId: memberId ?? this.memberId,
    iban: iban ?? this.iban,
    bic: bic.present ? bic.value : this.bic,
    accountName: accountName.present ? accountName.value : this.accountName,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMemberBankRow copyWithCompanion(LocalMemberBankCompanion data) {
    return LocalMemberBankRow(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      iban: data.iban.present ? data.iban.value : this.iban,
      bic: data.bic.present ? data.bic.value : this.bic,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMemberBankRow(')
          ..write('memberId: $memberId, ')
          ..write('iban: $iban, ')
          ..write('bic: $bic, ')
          ..write('accountName: $accountName, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memberId, iban, bic, accountName, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMemberBankRow &&
          other.memberId == this.memberId &&
          other.iban == this.iban &&
          other.bic == this.bic &&
          other.accountName == this.accountName &&
          other.updatedAt == this.updatedAt);
}

class LocalMemberBankCompanion extends UpdateCompanion<LocalMemberBankRow> {
  final Value<String> memberId;
  final Value<String> iban;
  final Value<String?> bic;
  final Value<String?> accountName;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const LocalMemberBankCompanion({
    this.memberId = const Value.absent(),
    this.iban = const Value.absent(),
    this.bic = const Value.absent(),
    this.accountName = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMemberBankCompanion.insert({
    required String memberId,
    required String iban,
    this.bic = const Value.absent(),
    this.accountName = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       iban = Value(iban),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMemberBankRow> custom({
    Expression<String>? memberId,
    Expression<String>? iban,
    Expression<String>? bic,
    Expression<String>? accountName,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (iban != null) 'iban': iban,
      if (bic != null) 'bic': bic,
      if (accountName != null) 'account_name': accountName,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMemberBankCompanion copyWith({
    Value<String>? memberId,
    Value<String>? iban,
    Value<String?>? bic,
    Value<String?>? accountName,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalMemberBankCompanion(
      memberId: memberId ?? this.memberId,
      iban: iban ?? this.iban,
      bic: bic ?? this.bic,
      accountName: accountName ?? this.accountName,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (iban.present) {
      map['iban'] = Variable<String>(iban.value);
    }
    if (bic.present) {
      map['bic'] = Variable<String>(bic.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMemberBankCompanion(')
          ..write('memberId: $memberId, ')
          ..write('iban: $iban, ')
          ..write('bic: $bic, ')
          ..write('accountName: $accountName, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOutboxTable extends LocalOutbox
    with TableInfo<$LocalOutboxTable, LocalOutboxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _opIdMeta = const VerificationMeta('opId');
  @override
  late final GeneratedColumn<String> opId = GeneratedColumn<String>(
    'op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _entityMeta = const VerificationMeta('entity');
  @override
  late final GeneratedColumn<String> entity = GeneratedColumn<String>(
    'entity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opMeta = const VerificationMeta('op');
  @override
  late final GeneratedColumn<String> op = GeneratedColumn<String>(
    'op',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    opId,
    groupId,
    entity,
    entityId,
    op,
    payload,
    createdAt,
    attempts,
    nextAttemptAt,
    lastErrorCode,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOutboxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    }
    if (data.containsKey('op_id')) {
      context.handle(
        _opIdMeta,
        opId.isAcceptableOrUnknown(data['op_id']!, _opIdMeta),
      );
    } else if (isInserting) {
      context.missing(_opIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('entity')) {
      context.handle(
        _entityMeta,
        entity.isAcceptableOrUnknown(data['entity']!, _entityMeta),
      );
    } else if (isInserting) {
      context.missing(_entityMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('op')) {
      context.handle(_opMeta, op.isAcceptableOrUnknown(data['op']!, _opMeta));
    } else if (isInserting) {
      context.missing(_opMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {opId},
  ];
  @override
  LocalOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOutboxRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      opId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      entity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      op: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}op'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
    );
  }

  @override
  $LocalOutboxTable createAlias(String alias) {
    return $LocalOutboxTable(attachedDatabase, alias);
  }
}

class LocalOutboxRow extends DataClass implements Insertable<LocalOutboxRow> {
  final int seq;

  /// UUIDv7, the idempotency key of the push (server ignores a replay).
  final String opId;
  final String groupId;
  final String entity;
  final String entityId;
  final String op;
  final String payload;
  final DateTime createdAt;
  final int attempts;

  /// Backoff: not before this time. Null: due now.
  final DateTime? nextAttemptAt;

  /// Stable error case name of the last failed push (ADR-27 §3).
  final String? lastErrorCode;
  const LocalOutboxRow({
    required this.seq,
    required this.opId,
    required this.groupId,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.createdAt,
    required this.attempts,
    this.nextAttemptAt,
    this.lastErrorCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['op_id'] = Variable<String>(opId);
    map['group_id'] = Variable<String>(groupId);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || nextAttemptAt != null) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    return map;
  }

  LocalOutboxCompanion toCompanion(bool nullToAbsent) {
    return LocalOutboxCompanion(
      seq: Value(seq),
      opId: Value(opId),
      groupId: Value(groupId),
      entity: Value(entity),
      entityId: Value(entityId),
      op: Value(op),
      payload: Value(payload),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
      nextAttemptAt: nextAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextAttemptAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
    );
  }

  factory LocalOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOutboxRow(
      seq: serializer.fromJson<int>(json['seq']),
      opId: serializer.fromJson<String>(json['opId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime?>(json['nextAttemptAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'opId': serializer.toJson<String>(opId),
      'groupId': serializer.toJson<String>(groupId),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime?>(nextAttemptAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
    };
  }

  LocalOutboxRow copyWith({
    int? seq,
    String? opId,
    String? groupId,
    String? entity,
    String? entityId,
    String? op,
    String? payload,
    DateTime? createdAt,
    int? attempts,
    Value<DateTime?> nextAttemptAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
  }) => LocalOutboxRow(
    seq: seq ?? this.seq,
    opId: opId ?? this.opId,
    groupId: groupId ?? this.groupId,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    createdAt: createdAt ?? this.createdAt,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt.present
        ? nextAttemptAt.value
        : this.nextAttemptAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
  );
  LocalOutboxRow copyWithCompanion(LocalOutboxCompanion data) {
    return LocalOutboxRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      opId: data.opId.present ? data.opId.value : this.opId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOutboxRow(')
          ..write('seq: $seq, ')
          ..write('opId: $opId, ')
          ..write('groupId: $groupId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    seq,
    opId,
    groupId,
    entity,
    entityId,
    op,
    payload,
    createdAt,
    attempts,
    nextAttemptAt,
    lastErrorCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOutboxRow &&
          other.seq == this.seq &&
          other.opId == this.opId &&
          other.groupId == this.groupId &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastErrorCode == this.lastErrorCode);
}

class LocalOutboxCompanion extends UpdateCompanion<LocalOutboxRow> {
  final Value<int> seq;
  final Value<String> opId;
  final Value<String> groupId;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> op;
  final Value<String> payload;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  final Value<DateTime?> nextAttemptAt;
  final Value<String?> lastErrorCode;
  const LocalOutboxCompanion({
    this.seq = const Value.absent(),
    this.opId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
  });
  LocalOutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String opId,
    required String groupId,
    required String entity,
    required String entityId,
    required String op,
    required String payload,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
  }) : opId = Value(opId),
       groupId = Value(groupId),
       entity = Value(entity),
       entityId = Value(entityId),
       op = Value(op),
       payload = Value(payload),
       createdAt = Value(createdAt);
  static Insertable<LocalOutboxRow> custom({
    Expression<int>? seq,
    Expression<String>? opId,
    Expression<String>? groupId,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastErrorCode,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (opId != null) 'op_id': opId,
      if (groupId != null) 'group_id': groupId,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
    });
  }

  LocalOutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? opId,
    Value<String>? groupId,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? op,
    Value<String>? payload,
    Value<DateTime>? createdAt,
    Value<int>? attempts,
    Value<DateTime?>? nextAttemptAt,
    Value<String?>? lastErrorCode,
  }) {
    return LocalOutboxCompanion(
      seq: seq ?? this.seq,
      opId: opId ?? this.opId,
      groupId: groupId ?? this.groupId,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (opId.present) {
      map['op_id'] = Variable<String>(opId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (entity.present) {
      map['entity'] = Variable<String>(entity.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (op.present) {
      map['op'] = Variable<String>(op.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('opId: $opId, ')
          ..write('groupId: $groupId, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastErrorCode: $lastErrorCode')
          ..write(')'))
        .toString();
  }
}

class $LocalDriverPromptsTable extends LocalDriverPrompts
    with TableInfo<$LocalDriverPromptsTable, LocalDriverPromptRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDriverPromptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _memberIdMeta = const VerificationMeta(
    'memberId',
  );
  @override
  late final GeneratedColumn<String> memberId = GeneratedColumn<String>(
    'member_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _askedAtMeta = const VerificationMeta(
    'askedAt',
  );
  @override
  late final GeneratedColumn<String> askedAt = GeneratedColumn<String>(
    'asked_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [memberId, askedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_driver_prompts';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDriverPromptRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('member_id')) {
      context.handle(
        _memberIdMeta,
        memberId.isAcceptableOrUnknown(data['member_id']!, _memberIdMeta),
      );
    } else if (isInserting) {
      context.missing(_memberIdMeta);
    }
    if (data.containsKey('asked_at')) {
      context.handle(
        _askedAtMeta,
        askedAt.isAcceptableOrUnknown(data['asked_at']!, _askedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_askedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {memberId};
  @override
  LocalDriverPromptRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDriverPromptRow(
      memberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_id'],
      )!,
      askedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asked_at'],
      )!,
    );
  }

  @override
  $LocalDriverPromptsTable createAlias(String alias) {
    return $LocalDriverPromptsTable(attachedDatabase, alias);
  }
}

class LocalDriverPromptRow extends DataClass
    implements Insertable<LocalDriverPromptRow> {
  final String memberId;
  final String askedAt;
  const LocalDriverPromptRow({required this.memberId, required this.askedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['asked_at'] = Variable<String>(askedAt);
    return map;
  }

  LocalDriverPromptsCompanion toCompanion(bool nullToAbsent) {
    return LocalDriverPromptsCompanion(
      memberId: Value(memberId),
      askedAt: Value(askedAt),
    );
  }

  factory LocalDriverPromptRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDriverPromptRow(
      memberId: serializer.fromJson<String>(json['memberId']),
      askedAt: serializer.fromJson<String>(json['askedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'askedAt': serializer.toJson<String>(askedAt),
    };
  }

  LocalDriverPromptRow copyWith({String? memberId, String? askedAt}) =>
      LocalDriverPromptRow(
        memberId: memberId ?? this.memberId,
        askedAt: askedAt ?? this.askedAt,
      );
  LocalDriverPromptRow copyWithCompanion(LocalDriverPromptsCompanion data) {
    return LocalDriverPromptRow(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      askedAt: data.askedAt.present ? data.askedAt.value : this.askedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDriverPromptRow(')
          ..write('memberId: $memberId, ')
          ..write('askedAt: $askedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memberId, askedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDriverPromptRow &&
          other.memberId == this.memberId &&
          other.askedAt == this.askedAt);
}

class LocalDriverPromptsCompanion
    extends UpdateCompanion<LocalDriverPromptRow> {
  final Value<String> memberId;
  final Value<String> askedAt;
  final Value<int> rowid;
  const LocalDriverPromptsCompanion({
    this.memberId = const Value.absent(),
    this.askedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDriverPromptsCompanion.insert({
    required String memberId,
    required String askedAt,
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       askedAt = Value(askedAt);
  static Insertable<LocalDriverPromptRow> custom({
    Expression<String>? memberId,
    Expression<String>? askedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (askedAt != null) 'asked_at': askedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDriverPromptsCompanion copyWith({
    Value<String>? memberId,
    Value<String>? askedAt,
    Value<int>? rowid,
  }) {
    return LocalDriverPromptsCompanion(
      memberId: memberId ?? this.memberId,
      askedAt: askedAt ?? this.askedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (memberId.present) {
      map['member_id'] = Variable<String>(memberId.value);
    }
    if (askedAt.present) {
      map['asked_at'] = Variable<String>(askedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDriverPromptsCompanion(')
          ..write('memberId: $memberId, ')
          ..write('askedAt: $askedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalPlacesTable extends LocalPlaces
    with TableInfo<$LocalPlacesTable, LocalPlaceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalPlacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
    'lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lngMeta = const VerificationMeta('lng');
  @override
  late final GeneratedColumn<double> lng = GeneratedColumn<double>(
    'lng',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _savedAtMeta = const VerificationMeta(
    'savedAt',
  );
  @override
  late final GeneratedColumn<String> savedAt = GeneratedColumn<String>(
    'saved_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [kind, label, lat, lng, savedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalPlaceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
        _latMeta,
        lat.isAcceptableOrUnknown(data['lat']!, _latMeta),
      );
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lng')) {
      context.handle(
        _lngMeta,
        lng.isAcceptableOrUnknown(data['lng']!, _lngMeta),
      );
    } else if (isInserting) {
      context.missing(_lngMeta);
    }
    if (data.containsKey('saved_at')) {
      context.handle(
        _savedAtMeta,
        savedAt.isAcceptableOrUnknown(data['saved_at']!, _savedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_savedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {kind};
  @override
  LocalPlaceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalPlaceRow(
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      lat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lat'],
      )!,
      lng: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lng'],
      )!,
      savedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}saved_at'],
      )!,
    );
  }

  @override
  $LocalPlacesTable createAlias(String alias) {
    return $LocalPlacesTable(attachedDatabase, alias);
  }
}

class LocalPlaceRow extends DataClass implements Insertable<LocalPlaceRow> {
  /// `home` or `work`: one place per kind.
  final String kind;
  final String label;
  final double lat;
  final double lng;
  final String savedAt;
  const LocalPlaceRow({
    required this.kind,
    required this.label,
    required this.lat,
    required this.lng,
    required this.savedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['kind'] = Variable<String>(kind);
    map['label'] = Variable<String>(label);
    map['lat'] = Variable<double>(lat);
    map['lng'] = Variable<double>(lng);
    map['saved_at'] = Variable<String>(savedAt);
    return map;
  }

  LocalPlacesCompanion toCompanion(bool nullToAbsent) {
    return LocalPlacesCompanion(
      kind: Value(kind),
      label: Value(label),
      lat: Value(lat),
      lng: Value(lng),
      savedAt: Value(savedAt),
    );
  }

  factory LocalPlaceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalPlaceRow(
      kind: serializer.fromJson<String>(json['kind']),
      label: serializer.fromJson<String>(json['label']),
      lat: serializer.fromJson<double>(json['lat']),
      lng: serializer.fromJson<double>(json['lng']),
      savedAt: serializer.fromJson<String>(json['savedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'kind': serializer.toJson<String>(kind),
      'label': serializer.toJson<String>(label),
      'lat': serializer.toJson<double>(lat),
      'lng': serializer.toJson<double>(lng),
      'savedAt': serializer.toJson<String>(savedAt),
    };
  }

  LocalPlaceRow copyWith({
    String? kind,
    String? label,
    double? lat,
    double? lng,
    String? savedAt,
  }) => LocalPlaceRow(
    kind: kind ?? this.kind,
    label: label ?? this.label,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    savedAt: savedAt ?? this.savedAt,
  );
  LocalPlaceRow copyWithCompanion(LocalPlacesCompanion data) {
    return LocalPlaceRow(
      kind: data.kind.present ? data.kind.value : this.kind,
      label: data.label.present ? data.label.value : this.label,
      lat: data.lat.present ? data.lat.value : this.lat,
      lng: data.lng.present ? data.lng.value : this.lng,
      savedAt: data.savedAt.present ? data.savedAt.value : this.savedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlaceRow(')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('savedAt: $savedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(kind, label, lat, lng, savedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalPlaceRow &&
          other.kind == this.kind &&
          other.label == this.label &&
          other.lat == this.lat &&
          other.lng == this.lng &&
          other.savedAt == this.savedAt);
}

class LocalPlacesCompanion extends UpdateCompanion<LocalPlaceRow> {
  final Value<String> kind;
  final Value<String> label;
  final Value<double> lat;
  final Value<double> lng;
  final Value<String> savedAt;
  final Value<int> rowid;
  const LocalPlacesCompanion({
    this.kind = const Value.absent(),
    this.label = const Value.absent(),
    this.lat = const Value.absent(),
    this.lng = const Value.absent(),
    this.savedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalPlacesCompanion.insert({
    required String kind,
    required String label,
    required double lat,
    required double lng,
    required String savedAt,
    this.rowid = const Value.absent(),
  }) : kind = Value(kind),
       label = Value(label),
       lat = Value(lat),
       lng = Value(lng),
       savedAt = Value(savedAt);
  static Insertable<LocalPlaceRow> custom({
    Expression<String>? kind,
    Expression<String>? label,
    Expression<double>? lat,
    Expression<double>? lng,
    Expression<String>? savedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (kind != null) 'kind': kind,
      if (label != null) 'label': label,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (savedAt != null) 'saved_at': savedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalPlacesCompanion copyWith({
    Value<String>? kind,
    Value<String>? label,
    Value<double>? lat,
    Value<double>? lng,
    Value<String>? savedAt,
    Value<int>? rowid,
  }) {
    return LocalPlacesCompanion(
      kind: kind ?? this.kind,
      label: label ?? this.label,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      savedAt: savedAt ?? this.savedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lng.present) {
      map['lng'] = Variable<double>(lng.value);
    }
    if (savedAt.present) {
      map['saved_at'] = Variable<String>(savedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalPlacesCompanion(')
          ..write('kind: $kind, ')
          ..write('label: $label, ')
          ..write('lat: $lat, ')
          ..write('lng: $lng, ')
          ..write('savedAt: $savedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VehiclesTable extends Vehicles
    with TableInfo<$VehiclesTable, VehicleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fuelTypeMeta = const VerificationMeta(
    'fuelType',
  );
  @override
  late final GeneratedColumn<String> fuelType = GeneratedColumn<String>(
    'fuel_type',
    aliasedName,
    false,
    check: () => fuelType.isIn(const ['petrol', 'diesel', 'electric', 'other']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consumptionMilliPer100kmMeta =
      const VerificationMeta('consumptionMilliPer100km');
  @override
  late final GeneratedColumn<int> consumptionMilliPer100km =
      GeneratedColumn<int>(
        'consumption_milli_per100km',
        aliasedName,
        false,
        check: () =>
            ComparableExpr(consumptionMilliPer100km).isBiggerThanValue(0),
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _wearMilliPerKmMeta = const VerificationMeta(
    'wearMilliPerKm',
  );
  @override
  late final GeneratedColumn<int> wearMilliPerKm = GeneratedColumn<int>(
    'wear_milli_per_km',
    aliasedName,
    false,
    check: () => ComparableExpr(wearMilliPerKm).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _kmRateMilliPerKmMeta = const VerificationMeta(
    'kmRateMilliPerKm',
  );
  @override
  late final GeneratedColumn<int> kmRateMilliPerKm = GeneratedColumn<int>(
    'km_rate_milli_per_km',
    aliasedName,
    true,
    check: () => ComparableExpr(kmRateMilliPerKm).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceUserVehicleIdMeta =
      const VerificationMeta('sourceUserVehicleId');
  @override
  late final GeneratedColumn<String> sourceUserVehicleId =
      GeneratedColumn<String>(
        'source_user_vehicle_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    fuelType,
    consumptionMilliPer100km,
    wearMilliPerKm,
    kmRateMilliPerKm,
    sourceUserVehicleId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<VehicleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fuel_type')) {
      context.handle(
        _fuelTypeMeta,
        fuelType.isAcceptableOrUnknown(data['fuel_type']!, _fuelTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fuelTypeMeta);
    }
    if (data.containsKey('consumption_milli_per100km')) {
      context.handle(
        _consumptionMilliPer100kmMeta,
        consumptionMilliPer100km.isAcceptableOrUnknown(
          data['consumption_milli_per100km']!,
          _consumptionMilliPer100kmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consumptionMilliPer100kmMeta);
    }
    if (data.containsKey('wear_milli_per_km')) {
      context.handle(
        _wearMilliPerKmMeta,
        wearMilliPerKm.isAcceptableOrUnknown(
          data['wear_milli_per_km']!,
          _wearMilliPerKmMeta,
        ),
      );
    }
    if (data.containsKey('km_rate_milli_per_km')) {
      context.handle(
        _kmRateMilliPerKmMeta,
        kmRateMilliPerKm.isAcceptableOrUnknown(
          data['km_rate_milli_per_km']!,
          _kmRateMilliPerKmMeta,
        ),
      );
    }
    if (data.containsKey('source_user_vehicle_id')) {
      context.handle(
        _sourceUserVehicleIdMeta,
        sourceUserVehicleId.isAcceptableOrUnknown(
          data['source_user_vehicle_id']!,
          _sourceUserVehicleIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  VehicleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VehicleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fuelType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_type'],
      )!,
      consumptionMilliPer100km: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consumption_milli_per100km'],
      )!,
      wearMilliPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_milli_per_km'],
      )!,
      kmRateMilliPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}km_rate_milli_per_km'],
      ),
      sourceUserVehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_user_vehicle_id'],
      ),
    );
  }

  @override
  $VehiclesTable createAlias(String alias) {
    return $VehiclesTable(attachedDatabase, alias);
  }
}

class VehicleRow extends DataClass implements Insertable<VehicleRow> {
  /// UUIDv7 generated on the client.
  final String id;
  final String groupId;

  /// Creation time, UTC.
  final DateTime createdAt;

  /// Hybrid logical clock string.
  final String updatedAt;

  /// Soft delete marker; null while the row is live.
  final DateTime? deletedAt;
  final String name;
  final String fuelType;

  /// Litres or kWh per 100 km times 1000.
  final int consumptionMilliPer100km;

  /// Thousandths of the major currency unit per km.
  final int wearMilliPerKm;

  /// If set, rides with this vehicle default to km-rate mode.
  final int? kmRateMilliPerKm;

  /// Id of the personal [UserVehicles] row this group copy is linked to
  /// (ADR-25, schema v7). Local only: never pushed (the outbox payload uses
  /// server columns) and not on the server. Null for plain group vehicles.
  final String? sourceUserVehicleId;
  const VehicleRow({
    required this.id,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.fuelType,
    required this.consumptionMilliPer100km,
    required this.wearMilliPerKm,
    this.kmRateMilliPerKm,
    this.sourceUserVehicleId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['fuel_type'] = Variable<String>(fuelType);
    map['consumption_milli_per100km'] = Variable<int>(consumptionMilliPer100km);
    map['wear_milli_per_km'] = Variable<int>(wearMilliPerKm);
    if (!nullToAbsent || kmRateMilliPerKm != null) {
      map['km_rate_milli_per_km'] = Variable<int>(kmRateMilliPerKm);
    }
    if (!nullToAbsent || sourceUserVehicleId != null) {
      map['source_user_vehicle_id'] = Variable<String>(sourceUserVehicleId);
    }
    return map;
  }

  VehiclesCompanion toCompanion(bool nullToAbsent) {
    return VehiclesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      fuelType: Value(fuelType),
      consumptionMilliPer100km: Value(consumptionMilliPer100km),
      wearMilliPerKm: Value(wearMilliPerKm),
      kmRateMilliPerKm: kmRateMilliPerKm == null && nullToAbsent
          ? const Value.absent()
          : Value(kmRateMilliPerKm),
      sourceUserVehicleId: sourceUserVehicleId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceUserVehicleId),
    );
  }

  factory VehicleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VehicleRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      fuelType: serializer.fromJson<String>(json['fuelType']),
      consumptionMilliPer100km: serializer.fromJson<int>(
        json['consumptionMilliPer100km'],
      ),
      wearMilliPerKm: serializer.fromJson<int>(json['wearMilliPerKm']),
      kmRateMilliPerKm: serializer.fromJson<int?>(json['kmRateMilliPerKm']),
      sourceUserVehicleId: serializer.fromJson<String?>(
        json['sourceUserVehicleId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'fuelType': serializer.toJson<String>(fuelType),
      'consumptionMilliPer100km': serializer.toJson<int>(
        consumptionMilliPer100km,
      ),
      'wearMilliPerKm': serializer.toJson<int>(wearMilliPerKm),
      'kmRateMilliPerKm': serializer.toJson<int?>(kmRateMilliPerKm),
      'sourceUserVehicleId': serializer.toJson<String?>(sourceUserVehicleId),
    };
  }

  VehicleRow copyWith({
    String? id,
    String? groupId,
    DateTime? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    String? fuelType,
    int? consumptionMilliPer100km,
    int? wearMilliPerKm,
    Value<int?> kmRateMilliPerKm = const Value.absent(),
    Value<String?> sourceUserVehicleId = const Value.absent(),
  }) => VehicleRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    fuelType: fuelType ?? this.fuelType,
    consumptionMilliPer100km:
        consumptionMilliPer100km ?? this.consumptionMilliPer100km,
    wearMilliPerKm: wearMilliPerKm ?? this.wearMilliPerKm,
    kmRateMilliPerKm: kmRateMilliPerKm.present
        ? kmRateMilliPerKm.value
        : this.kmRateMilliPerKm,
    sourceUserVehicleId: sourceUserVehicleId.present
        ? sourceUserVehicleId.value
        : this.sourceUserVehicleId,
  );
  VehicleRow copyWithCompanion(VehiclesCompanion data) {
    return VehicleRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      consumptionMilliPer100km: data.consumptionMilliPer100km.present
          ? data.consumptionMilliPer100km.value
          : this.consumptionMilliPer100km,
      wearMilliPerKm: data.wearMilliPerKm.present
          ? data.wearMilliPerKm.value
          : this.wearMilliPerKm,
      kmRateMilliPerKm: data.kmRateMilliPerKm.present
          ? data.kmRateMilliPerKm.value
          : this.kmRateMilliPerKm,
      sourceUserVehicleId: data.sourceUserVehicleId.present
          ? data.sourceUserVehicleId.value
          : this.sourceUserVehicleId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VehicleRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('fuelType: $fuelType, ')
          ..write('consumptionMilliPer100km: $consumptionMilliPer100km, ')
          ..write('wearMilliPerKm: $wearMilliPerKm, ')
          ..write('kmRateMilliPerKm: $kmRateMilliPerKm, ')
          ..write('sourceUserVehicleId: $sourceUserVehicleId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    fuelType,
    consumptionMilliPer100km,
    wearMilliPerKm,
    kmRateMilliPerKm,
    sourceUserVehicleId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VehicleRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.fuelType == this.fuelType &&
          other.consumptionMilliPer100km == this.consumptionMilliPer100km &&
          other.wearMilliPerKm == this.wearMilliPerKm &&
          other.kmRateMilliPerKm == this.kmRateMilliPerKm &&
          other.sourceUserVehicleId == this.sourceUserVehicleId);
}

class VehiclesCompanion extends UpdateCompanion<VehicleRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<DateTime> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String> fuelType;
  final Value<int> consumptionMilliPer100km;
  final Value<int> wearMilliPerKm;
  final Value<int?> kmRateMilliPerKm;
  final Value<String?> sourceUserVehicleId;
  final Value<int> rowid;
  const VehiclesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.consumptionMilliPer100km = const Value.absent(),
    this.wearMilliPerKm = const Value.absent(),
    this.kmRateMilliPerKm = const Value.absent(),
    this.sourceUserVehicleId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VehiclesCompanion.insert({
    required String id,
    required String groupId,
    required DateTime createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required String fuelType,
    required int consumptionMilliPer100km,
    this.wearMilliPerKm = const Value.absent(),
    this.kmRateMilliPerKm = const Value.absent(),
    this.sourceUserVehicleId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       fuelType = Value(fuelType),
       consumptionMilliPer100km = Value(consumptionMilliPer100km);
  static Insertable<VehicleRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<DateTime>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? fuelType,
    Expression<int>? consumptionMilliPer100km,
    Expression<int>? wearMilliPerKm,
    Expression<int>? kmRateMilliPerKm,
    Expression<String>? sourceUserVehicleId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (fuelType != null) 'fuel_type': fuelType,
      if (consumptionMilliPer100km != null)
        'consumption_milli_per100km': consumptionMilliPer100km,
      if (wearMilliPerKm != null) 'wear_milli_per_km': wearMilliPerKm,
      if (kmRateMilliPerKm != null) 'km_rate_milli_per_km': kmRateMilliPerKm,
      if (sourceUserVehicleId != null)
        'source_user_vehicle_id': sourceUserVehicleId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VehiclesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<DateTime>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String>? fuelType,
    Value<int>? consumptionMilliPer100km,
    Value<int>? wearMilliPerKm,
    Value<int?>? kmRateMilliPerKm,
    Value<String?>? sourceUserVehicleId,
    Value<int>? rowid,
  }) {
    return VehiclesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      fuelType: fuelType ?? this.fuelType,
      consumptionMilliPer100km:
          consumptionMilliPer100km ?? this.consumptionMilliPer100km,
      wearMilliPerKm: wearMilliPerKm ?? this.wearMilliPerKm,
      kmRateMilliPerKm: kmRateMilliPerKm ?? this.kmRateMilliPerKm,
      sourceUserVehicleId: sourceUserVehicleId ?? this.sourceUserVehicleId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(fuelType.value);
    }
    if (consumptionMilliPer100km.present) {
      map['consumption_milli_per100km'] = Variable<int>(
        consumptionMilliPer100km.value,
      );
    }
    if (wearMilliPerKm.present) {
      map['wear_milli_per_km'] = Variable<int>(wearMilliPerKm.value);
    }
    if (kmRateMilliPerKm.present) {
      map['km_rate_milli_per_km'] = Variable<int>(kmRateMilliPerKm.value);
    }
    if (sourceUserVehicleId.present) {
      map['source_user_vehicle_id'] = Variable<String>(
        sourceUserVehicleId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VehiclesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('fuelType: $fuelType, ')
          ..write('consumptionMilliPer100km: $consumptionMilliPer100km, ')
          ..write('wearMilliPerKm: $wearMilliPerKm, ')
          ..write('kmRateMilliPerKm: $kmRateMilliPerKm, ')
          ..write('sourceUserVehicleId: $sourceUserVehicleId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RideTemplatesTable extends RideTemplates
    with TableInfo<$RideTemplatesTable, RideTemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RideTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<int> distanceMeters = GeneratedColumn<int>(
    'distance_meters',
    aliasedName,
    false,
    check: () => ComparableExpr(distanceMeters).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundTripMeta = const VerificationMeta(
    'roundTrip',
  );
  @override
  late final GeneratedColumn<bool> roundTrip = GeneratedColumn<bool>(
    'round_trip',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("round_trip" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id)',
    ),
  );
  static const VerificationMeta _defaultDriverIdMeta = const VerificationMeta(
    'defaultDriverId',
  );
  @override
  late final GeneratedColumn<String> defaultDriverId = GeneratedColumn<String>(
    'default_driver_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _defaultPassengerIdsMeta =
      const VerificationMeta('defaultPassengerIds');
  @override
  late final GeneratedColumn<String> defaultPassengerIds =
      GeneratedColumn<String>(
        'default_passenger_ids',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('[]'),
      );
  static const VerificationMeta _tollsCentsMeta = const VerificationMeta(
    'tollsCents',
  );
  @override
  late final GeneratedColumn<int> tollsCents = GeneratedColumn<int>(
    'tolls_cents',
    aliasedName,
    false,
    check: () => ComparableExpr(tollsCents).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    distanceMeters,
    roundTrip,
    vehicleId,
    defaultDriverId,
    defaultPassengerIds,
    tollsCents,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ride_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<RideTemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('round_trip')) {
      context.handle(
        _roundTripMeta,
        roundTrip.isAcceptableOrUnknown(data['round_trip']!, _roundTripMeta),
      );
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('default_driver_id')) {
      context.handle(
        _defaultDriverIdMeta,
        defaultDriverId.isAcceptableOrUnknown(
          data['default_driver_id']!,
          _defaultDriverIdMeta,
        ),
      );
    }
    if (data.containsKey('default_passenger_ids')) {
      context.handle(
        _defaultPassengerIdsMeta,
        defaultPassengerIds.isAcceptableOrUnknown(
          data['default_passenger_ids']!,
          _defaultPassengerIdsMeta,
        ),
      );
    }
    if (data.containsKey('tolls_cents')) {
      context.handle(
        _tollsCentsMeta,
        tollsCents.isAcceptableOrUnknown(data['tolls_cents']!, _tollsCentsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RideTemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RideTemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_meters'],
      )!,
      roundTrip: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}round_trip'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      defaultDriverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_driver_id'],
      ),
      defaultPassengerIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_passenger_ids'],
      )!,
      tollsCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tolls_cents'],
      )!,
    );
  }

  @override
  $RideTemplatesTable createAlias(String alias) {
    return $RideTemplatesTable(attachedDatabase, alias);
  }
}

class RideTemplateRow extends DataClass implements Insertable<RideTemplateRow> {
  /// UUIDv7 generated on the client.
  final String id;
  final String groupId;

  /// Creation time, UTC.
  final DateTime createdAt;

  /// Hybrid logical clock string.
  final String updatedAt;

  /// Soft delete marker; null while the row is live.
  final DateTime? deletedAt;
  final String name;

  /// One-way distance in metres.
  final int distanceMeters;
  final bool roundTrip;
  final String vehicleId;
  final String? defaultDriverId;

  /// JSON array of member ids, sorted (aggregate-level sync, no child table).
  final String defaultPassengerIds;
  final int tollsCents;
  const RideTemplateRow({
    required this.id,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.distanceMeters,
    required this.roundTrip,
    required this.vehicleId,
    this.defaultDriverId,
    required this.defaultPassengerIds,
    required this.tollsCents,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['distance_meters'] = Variable<int>(distanceMeters);
    map['round_trip'] = Variable<bool>(roundTrip);
    map['vehicle_id'] = Variable<String>(vehicleId);
    if (!nullToAbsent || defaultDriverId != null) {
      map['default_driver_id'] = Variable<String>(defaultDriverId);
    }
    map['default_passenger_ids'] = Variable<String>(defaultPassengerIds);
    map['tolls_cents'] = Variable<int>(tollsCents);
    return map;
  }

  RideTemplatesCompanion toCompanion(bool nullToAbsent) {
    return RideTemplatesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      distanceMeters: Value(distanceMeters),
      roundTrip: Value(roundTrip),
      vehicleId: Value(vehicleId),
      defaultDriverId: defaultDriverId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultDriverId),
      defaultPassengerIds: Value(defaultPassengerIds),
      tollsCents: Value(tollsCents),
    );
  }

  factory RideTemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RideTemplateRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      distanceMeters: serializer.fromJson<int>(json['distanceMeters']),
      roundTrip: serializer.fromJson<bool>(json['roundTrip']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      defaultDriverId: serializer.fromJson<String?>(json['defaultDriverId']),
      defaultPassengerIds: serializer.fromJson<String>(
        json['defaultPassengerIds'],
      ),
      tollsCents: serializer.fromJson<int>(json['tollsCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'distanceMeters': serializer.toJson<int>(distanceMeters),
      'roundTrip': serializer.toJson<bool>(roundTrip),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'defaultDriverId': serializer.toJson<String?>(defaultDriverId),
      'defaultPassengerIds': serializer.toJson<String>(defaultPassengerIds),
      'tollsCents': serializer.toJson<int>(tollsCents),
    };
  }

  RideTemplateRow copyWith({
    String? id,
    String? groupId,
    DateTime? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    int? distanceMeters,
    bool? roundTrip,
    String? vehicleId,
    Value<String?> defaultDriverId = const Value.absent(),
    String? defaultPassengerIds,
    int? tollsCents,
  }) => RideTemplateRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    roundTrip: roundTrip ?? this.roundTrip,
    vehicleId: vehicleId ?? this.vehicleId,
    defaultDriverId: defaultDriverId.present
        ? defaultDriverId.value
        : this.defaultDriverId,
    defaultPassengerIds: defaultPassengerIds ?? this.defaultPassengerIds,
    tollsCents: tollsCents ?? this.tollsCents,
  );
  RideTemplateRow copyWithCompanion(RideTemplatesCompanion data) {
    return RideTemplateRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      roundTrip: data.roundTrip.present ? data.roundTrip.value : this.roundTrip,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      defaultDriverId: data.defaultDriverId.present
          ? data.defaultDriverId.value
          : this.defaultDriverId,
      defaultPassengerIds: data.defaultPassengerIds.present
          ? data.defaultPassengerIds.value
          : this.defaultPassengerIds,
      tollsCents: data.tollsCents.present
          ? data.tollsCents.value
          : this.tollsCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RideTemplateRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('roundTrip: $roundTrip, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('defaultDriverId: $defaultDriverId, ')
          ..write('defaultPassengerIds: $defaultPassengerIds, ')
          ..write('tollsCents: $tollsCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    name,
    distanceMeters,
    roundTrip,
    vehicleId,
    defaultDriverId,
    defaultPassengerIds,
    tollsCents,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RideTemplateRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.distanceMeters == this.distanceMeters &&
          other.roundTrip == this.roundTrip &&
          other.vehicleId == this.vehicleId &&
          other.defaultDriverId == this.defaultDriverId &&
          other.defaultPassengerIds == this.defaultPassengerIds &&
          other.tollsCents == this.tollsCents);
}

class RideTemplatesCompanion extends UpdateCompanion<RideTemplateRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<DateTime> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<int> distanceMeters;
  final Value<bool> roundTrip;
  final Value<String> vehicleId;
  final Value<String?> defaultDriverId;
  final Value<String> defaultPassengerIds;
  final Value<int> tollsCents;
  final Value<int> rowid;
  const RideTemplatesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.roundTrip = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.defaultDriverId = const Value.absent(),
    this.defaultPassengerIds = const Value.absent(),
    this.tollsCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RideTemplatesCompanion.insert({
    required String id,
    required String groupId,
    required DateTime createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required int distanceMeters,
    this.roundTrip = const Value.absent(),
    required String vehicleId,
    this.defaultDriverId = const Value.absent(),
    this.defaultPassengerIds = const Value.absent(),
    this.tollsCents = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       distanceMeters = Value(distanceMeters),
       vehicleId = Value(vehicleId);
  static Insertable<RideTemplateRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<DateTime>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<int>? distanceMeters,
    Expression<bool>? roundTrip,
    Expression<String>? vehicleId,
    Expression<String>? defaultDriverId,
    Expression<String>? defaultPassengerIds,
    Expression<int>? tollsCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (roundTrip != null) 'round_trip': roundTrip,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (defaultDriverId != null) 'default_driver_id': defaultDriverId,
      if (defaultPassengerIds != null)
        'default_passenger_ids': defaultPassengerIds,
      if (tollsCents != null) 'tolls_cents': tollsCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RideTemplatesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<DateTime>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<int>? distanceMeters,
    Value<bool>? roundTrip,
    Value<String>? vehicleId,
    Value<String?>? defaultDriverId,
    Value<String>? defaultPassengerIds,
    Value<int>? tollsCents,
    Value<int>? rowid,
  }) {
    return RideTemplatesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      roundTrip: roundTrip ?? this.roundTrip,
      vehicleId: vehicleId ?? this.vehicleId,
      defaultDriverId: defaultDriverId ?? this.defaultDriverId,
      defaultPassengerIds: defaultPassengerIds ?? this.defaultPassengerIds,
      tollsCents: tollsCents ?? this.tollsCents,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<int>(distanceMeters.value);
    }
    if (roundTrip.present) {
      map['round_trip'] = Variable<bool>(roundTrip.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (defaultDriverId.present) {
      map['default_driver_id'] = Variable<String>(defaultDriverId.value);
    }
    if (defaultPassengerIds.present) {
      map['default_passenger_ids'] = Variable<String>(
        defaultPassengerIds.value,
      );
    }
    if (tollsCents.present) {
      map['tolls_cents'] = Variable<int>(tollsCents.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RideTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('roundTrip: $roundTrip, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('defaultDriverId: $defaultDriverId, ')
          ..write('defaultPassengerIds: $defaultPassengerIds, ')
          ..write('tollsCents: $tollsCents, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RidesTable extends Rides with TableInfo<$RidesTable, RideRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RidesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMetersMeta = const VerificationMeta(
    'distanceMeters',
  );
  @override
  late final GeneratedColumn<int> distanceMeters = GeneratedColumn<int>(
    'distance_meters',
    aliasedName,
    false,
    check: () => ComparableExpr(distanceMeters).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _roundTripMeta = const VerificationMeta(
    'roundTrip',
  );
  @override
  late final GeneratedColumn<bool> roundTrip = GeneratedColumn<bool>(
    'round_trip',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("round_trip" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _tollsCentsMeta = const VerificationMeta(
    'tollsCents',
  );
  @override
  late final GeneratedColumn<int> tollsCents = GeneratedColumn<int>(
    'tolls_cents',
    aliasedName,
    false,
    check: () => ComparableExpr(tollsCents).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vehicleIdMeta = const VerificationMeta(
    'vehicleId',
  );
  @override
  late final GeneratedColumn<String> vehicleId = GeneratedColumn<String>(
    'vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES vehicles (id)',
    ),
  );
  static const VerificationMeta _driverIdMeta = const VerificationMeta(
    'driverId',
  );
  @override
  late final GeneratedColumn<String> driverId = GeneratedColumn<String>(
    'driver_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES members (id)',
    ),
  );
  static const VerificationMeta _passengerIdsMeta = const VerificationMeta(
    'passengerIds',
  );
  @override
  late final GeneratedColumn<String> passengerIds = GeneratedColumn<String>(
    'passenger_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _driverCountsMeta = const VerificationMeta(
    'driverCounts',
  );
  @override
  late final GeneratedColumn<bool> driverCounts = GeneratedColumn<bool>(
    'driver_counts',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("driver_counts" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _pricePerUnitMilliMeta = const VerificationMeta(
    'pricePerUnitMilli',
  );
  @override
  late final GeneratedColumn<int> pricePerUnitMilli = GeneratedColumn<int>(
    'price_per_unit_milli',
    aliasedName,
    false,
    check: () => ComparableExpr(pricePerUnitMilli).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _useKmRateMeta = const VerificationMeta(
    'useKmRate',
  );
  @override
  late final GeneratedColumn<bool> useKmRate = GeneratedColumn<bool>(
    'use_km_rate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("use_km_rate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _settledExpenseIdMeta = const VerificationMeta(
    'settledExpenseId',
  );
  @override
  late final GeneratedColumn<String> settledExpenseId = GeneratedColumn<String>(
    'settled_expense_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expenses (id)',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    date,
    distanceMeters,
    roundTrip,
    tollsCents,
    vehicleId,
    driverId,
    passengerIds,
    driverCounts,
    pricePerUnitMilli,
    useKmRate,
    settledExpenseId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rides';
  @override
  VerificationContext validateIntegrity(
    Insertable<RideRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
        _distanceMetersMeta,
        distanceMeters.isAcceptableOrUnknown(
          data['distance_meters']!,
          _distanceMetersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('round_trip')) {
      context.handle(
        _roundTripMeta,
        roundTrip.isAcceptableOrUnknown(data['round_trip']!, _roundTripMeta),
      );
    }
    if (data.containsKey('tolls_cents')) {
      context.handle(
        _tollsCentsMeta,
        tollsCents.isAcceptableOrUnknown(data['tolls_cents']!, _tollsCentsMeta),
      );
    }
    if (data.containsKey('vehicle_id')) {
      context.handle(
        _vehicleIdMeta,
        vehicleId.isAcceptableOrUnknown(data['vehicle_id']!, _vehicleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vehicleIdMeta);
    }
    if (data.containsKey('driver_id')) {
      context.handle(
        _driverIdMeta,
        driverId.isAcceptableOrUnknown(data['driver_id']!, _driverIdMeta),
      );
    } else if (isInserting) {
      context.missing(_driverIdMeta);
    }
    if (data.containsKey('passenger_ids')) {
      context.handle(
        _passengerIdsMeta,
        passengerIds.isAcceptableOrUnknown(
          data['passenger_ids']!,
          _passengerIdsMeta,
        ),
      );
    }
    if (data.containsKey('driver_counts')) {
      context.handle(
        _driverCountsMeta,
        driverCounts.isAcceptableOrUnknown(
          data['driver_counts']!,
          _driverCountsMeta,
        ),
      );
    }
    if (data.containsKey('price_per_unit_milli')) {
      context.handle(
        _pricePerUnitMilliMeta,
        pricePerUnitMilli.isAcceptableOrUnknown(
          data['price_per_unit_milli']!,
          _pricePerUnitMilliMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_pricePerUnitMilliMeta);
    }
    if (data.containsKey('use_km_rate')) {
      context.handle(
        _useKmRateMeta,
        useKmRate.isAcceptableOrUnknown(data['use_km_rate']!, _useKmRateMeta),
      );
    }
    if (data.containsKey('settled_expense_id')) {
      context.handle(
        _settledExpenseIdMeta,
        settledExpenseId.isAcceptableOrUnknown(
          data['settled_expense_id']!,
          _settledExpenseIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RideRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RideRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      distanceMeters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_meters'],
      )!,
      roundTrip: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}round_trip'],
      )!,
      tollsCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tolls_cents'],
      )!,
      vehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vehicle_id'],
      )!,
      driverId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}driver_id'],
      )!,
      passengerIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}passenger_ids'],
      )!,
      driverCounts: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}driver_counts'],
      )!,
      pricePerUnitMilli: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_per_unit_milli'],
      )!,
      useKmRate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}use_km_rate'],
      )!,
      settledExpenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settled_expense_id'],
      ),
    );
  }

  @override
  $RidesTable createAlias(String alias) {
    return $RidesTable(attachedDatabase, alias);
  }
}

class RideRow extends DataClass implements Insertable<RideRow> {
  /// UUIDv7 generated on the client.
  final String id;
  final String groupId;

  /// Creation time, UTC.
  final DateTime createdAt;

  /// Hybrid logical clock string.
  final String updatedAt;

  /// Soft delete marker; null while the row is live.
  final DateTime? deletedAt;

  /// Calendar date stored as UTC midnight.
  final DateTime date;

  /// One-way distance in metres.
  final int distanceMeters;
  final bool roundTrip;
  final int tollsCents;
  final String vehicleId;
  final String driverId;

  /// JSON array of member ids, sorted (aggregate-level sync, no child table).
  final String passengerIds;
  final bool driverCounts;

  /// Fuel price per litre or kWh in thousandths, frozen when logged.
  final int pricePerUnitMilli;
  final bool useKmRate;

  /// Set when a period is settled (P3r-T06); the ride is then locked.
  final String? settledExpenseId;
  const RideRow({
    required this.id,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.date,
    required this.distanceMeters,
    required this.roundTrip,
    required this.tollsCents,
    required this.vehicleId,
    required this.driverId,
    required this.passengerIds,
    required this.driverCounts,
    required this.pricePerUnitMilli,
    required this.useKmRate,
    this.settledExpenseId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['date'] = Variable<DateTime>(date);
    map['distance_meters'] = Variable<int>(distanceMeters);
    map['round_trip'] = Variable<bool>(roundTrip);
    map['tolls_cents'] = Variable<int>(tollsCents);
    map['vehicle_id'] = Variable<String>(vehicleId);
    map['driver_id'] = Variable<String>(driverId);
    map['passenger_ids'] = Variable<String>(passengerIds);
    map['driver_counts'] = Variable<bool>(driverCounts);
    map['price_per_unit_milli'] = Variable<int>(pricePerUnitMilli);
    map['use_km_rate'] = Variable<bool>(useKmRate);
    if (!nullToAbsent || settledExpenseId != null) {
      map['settled_expense_id'] = Variable<String>(settledExpenseId);
    }
    return map;
  }

  RidesCompanion toCompanion(bool nullToAbsent) {
    return RidesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      date: Value(date),
      distanceMeters: Value(distanceMeters),
      roundTrip: Value(roundTrip),
      tollsCents: Value(tollsCents),
      vehicleId: Value(vehicleId),
      driverId: Value(driverId),
      passengerIds: Value(passengerIds),
      driverCounts: Value(driverCounts),
      pricePerUnitMilli: Value(pricePerUnitMilli),
      useKmRate: Value(useKmRate),
      settledExpenseId: settledExpenseId == null && nullToAbsent
          ? const Value.absent()
          : Value(settledExpenseId),
    );
  }

  factory RideRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RideRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      date: serializer.fromJson<DateTime>(json['date']),
      distanceMeters: serializer.fromJson<int>(json['distanceMeters']),
      roundTrip: serializer.fromJson<bool>(json['roundTrip']),
      tollsCents: serializer.fromJson<int>(json['tollsCents']),
      vehicleId: serializer.fromJson<String>(json['vehicleId']),
      driverId: serializer.fromJson<String>(json['driverId']),
      passengerIds: serializer.fromJson<String>(json['passengerIds']),
      driverCounts: serializer.fromJson<bool>(json['driverCounts']),
      pricePerUnitMilli: serializer.fromJson<int>(json['pricePerUnitMilli']),
      useKmRate: serializer.fromJson<bool>(json['useKmRate']),
      settledExpenseId: serializer.fromJson<String?>(json['settledExpenseId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'date': serializer.toJson<DateTime>(date),
      'distanceMeters': serializer.toJson<int>(distanceMeters),
      'roundTrip': serializer.toJson<bool>(roundTrip),
      'tollsCents': serializer.toJson<int>(tollsCents),
      'vehicleId': serializer.toJson<String>(vehicleId),
      'driverId': serializer.toJson<String>(driverId),
      'passengerIds': serializer.toJson<String>(passengerIds),
      'driverCounts': serializer.toJson<bool>(driverCounts),
      'pricePerUnitMilli': serializer.toJson<int>(pricePerUnitMilli),
      'useKmRate': serializer.toJson<bool>(useKmRate),
      'settledExpenseId': serializer.toJson<String?>(settledExpenseId),
    };
  }

  RideRow copyWith({
    String? id,
    String? groupId,
    DateTime? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? date,
    int? distanceMeters,
    bool? roundTrip,
    int? tollsCents,
    String? vehicleId,
    String? driverId,
    String? passengerIds,
    bool? driverCounts,
    int? pricePerUnitMilli,
    bool? useKmRate,
    Value<String?> settledExpenseId = const Value.absent(),
  }) => RideRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    date: date ?? this.date,
    distanceMeters: distanceMeters ?? this.distanceMeters,
    roundTrip: roundTrip ?? this.roundTrip,
    tollsCents: tollsCents ?? this.tollsCents,
    vehicleId: vehicleId ?? this.vehicleId,
    driverId: driverId ?? this.driverId,
    passengerIds: passengerIds ?? this.passengerIds,
    driverCounts: driverCounts ?? this.driverCounts,
    pricePerUnitMilli: pricePerUnitMilli ?? this.pricePerUnitMilli,
    useKmRate: useKmRate ?? this.useKmRate,
    settledExpenseId: settledExpenseId.present
        ? settledExpenseId.value
        : this.settledExpenseId,
  );
  RideRow copyWithCompanion(RidesCompanion data) {
    return RideRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      date: data.date.present ? data.date.value : this.date,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      roundTrip: data.roundTrip.present ? data.roundTrip.value : this.roundTrip,
      tollsCents: data.tollsCents.present
          ? data.tollsCents.value
          : this.tollsCents,
      vehicleId: data.vehicleId.present ? data.vehicleId.value : this.vehicleId,
      driverId: data.driverId.present ? data.driverId.value : this.driverId,
      passengerIds: data.passengerIds.present
          ? data.passengerIds.value
          : this.passengerIds,
      driverCounts: data.driverCounts.present
          ? data.driverCounts.value
          : this.driverCounts,
      pricePerUnitMilli: data.pricePerUnitMilli.present
          ? data.pricePerUnitMilli.value
          : this.pricePerUnitMilli,
      useKmRate: data.useKmRate.present ? data.useKmRate.value : this.useKmRate,
      settledExpenseId: data.settledExpenseId.present
          ? data.settledExpenseId.value
          : this.settledExpenseId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RideRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('date: $date, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('roundTrip: $roundTrip, ')
          ..write('tollsCents: $tollsCents, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('driverId: $driverId, ')
          ..write('passengerIds: $passengerIds, ')
          ..write('driverCounts: $driverCounts, ')
          ..write('pricePerUnitMilli: $pricePerUnitMilli, ')
          ..write('useKmRate: $useKmRate, ')
          ..write('settledExpenseId: $settledExpenseId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
    date,
    distanceMeters,
    roundTrip,
    tollsCents,
    vehicleId,
    driverId,
    passengerIds,
    driverCounts,
    pricePerUnitMilli,
    useKmRate,
    settledExpenseId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RideRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.date == this.date &&
          other.distanceMeters == this.distanceMeters &&
          other.roundTrip == this.roundTrip &&
          other.tollsCents == this.tollsCents &&
          other.vehicleId == this.vehicleId &&
          other.driverId == this.driverId &&
          other.passengerIds == this.passengerIds &&
          other.driverCounts == this.driverCounts &&
          other.pricePerUnitMilli == this.pricePerUnitMilli &&
          other.useKmRate == this.useKmRate &&
          other.settledExpenseId == this.settledExpenseId);
}

class RidesCompanion extends UpdateCompanion<RideRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<DateTime> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> date;
  final Value<int> distanceMeters;
  final Value<bool> roundTrip;
  final Value<int> tollsCents;
  final Value<String> vehicleId;
  final Value<String> driverId;
  final Value<String> passengerIds;
  final Value<bool> driverCounts;
  final Value<int> pricePerUnitMilli;
  final Value<bool> useKmRate;
  final Value<String?> settledExpenseId;
  final Value<int> rowid;
  const RidesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.date = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.roundTrip = const Value.absent(),
    this.tollsCents = const Value.absent(),
    this.vehicleId = const Value.absent(),
    this.driverId = const Value.absent(),
    this.passengerIds = const Value.absent(),
    this.driverCounts = const Value.absent(),
    this.pricePerUnitMilli = const Value.absent(),
    this.useKmRate = const Value.absent(),
    this.settledExpenseId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RidesCompanion.insert({
    required String id,
    required String groupId,
    required DateTime createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required DateTime date,
    required int distanceMeters,
    this.roundTrip = const Value.absent(),
    this.tollsCents = const Value.absent(),
    required String vehicleId,
    required String driverId,
    this.passengerIds = const Value.absent(),
    this.driverCounts = const Value.absent(),
    required int pricePerUnitMilli,
    this.useKmRate = const Value.absent(),
    this.settledExpenseId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       date = Value(date),
       distanceMeters = Value(distanceMeters),
       vehicleId = Value(vehicleId),
       driverId = Value(driverId),
       pricePerUnitMilli = Value(pricePerUnitMilli);
  static Insertable<RideRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<DateTime>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? date,
    Expression<int>? distanceMeters,
    Expression<bool>? roundTrip,
    Expression<int>? tollsCents,
    Expression<String>? vehicleId,
    Expression<String>? driverId,
    Expression<String>? passengerIds,
    Expression<bool>? driverCounts,
    Expression<int>? pricePerUnitMilli,
    Expression<bool>? useKmRate,
    Expression<String>? settledExpenseId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (date != null) 'date': date,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (roundTrip != null) 'round_trip': roundTrip,
      if (tollsCents != null) 'tolls_cents': tollsCents,
      if (vehicleId != null) 'vehicle_id': vehicleId,
      if (driverId != null) 'driver_id': driverId,
      if (passengerIds != null) 'passenger_ids': passengerIds,
      if (driverCounts != null) 'driver_counts': driverCounts,
      if (pricePerUnitMilli != null) 'price_per_unit_milli': pricePerUnitMilli,
      if (useKmRate != null) 'use_km_rate': useKmRate,
      if (settledExpenseId != null) 'settled_expense_id': settledExpenseId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RidesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<DateTime>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? date,
    Value<int>? distanceMeters,
    Value<bool>? roundTrip,
    Value<int>? tollsCents,
    Value<String>? vehicleId,
    Value<String>? driverId,
    Value<String>? passengerIds,
    Value<bool>? driverCounts,
    Value<int>? pricePerUnitMilli,
    Value<bool>? useKmRate,
    Value<String?>? settledExpenseId,
    Value<int>? rowid,
  }) {
    return RidesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      date: date ?? this.date,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      roundTrip: roundTrip ?? this.roundTrip,
      tollsCents: tollsCents ?? this.tollsCents,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      passengerIds: passengerIds ?? this.passengerIds,
      driverCounts: driverCounts ?? this.driverCounts,
      pricePerUnitMilli: pricePerUnitMilli ?? this.pricePerUnitMilli,
      useKmRate: useKmRate ?? this.useKmRate,
      settledExpenseId: settledExpenseId ?? this.settledExpenseId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<int>(distanceMeters.value);
    }
    if (roundTrip.present) {
      map['round_trip'] = Variable<bool>(roundTrip.value);
    }
    if (tollsCents.present) {
      map['tolls_cents'] = Variable<int>(tollsCents.value);
    }
    if (vehicleId.present) {
      map['vehicle_id'] = Variable<String>(vehicleId.value);
    }
    if (driverId.present) {
      map['driver_id'] = Variable<String>(driverId.value);
    }
    if (passengerIds.present) {
      map['passenger_ids'] = Variable<String>(passengerIds.value);
    }
    if (driverCounts.present) {
      map['driver_counts'] = Variable<bool>(driverCounts.value);
    }
    if (pricePerUnitMilli.present) {
      map['price_per_unit_milli'] = Variable<int>(pricePerUnitMilli.value);
    }
    if (useKmRate.present) {
      map['use_km_rate'] = Variable<bool>(useKmRate.value);
    }
    if (settledExpenseId.present) {
      map['settled_expense_id'] = Variable<String>(settledExpenseId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RidesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('date: $date, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('roundTrip: $roundTrip, ')
          ..write('tollsCents: $tollsCents, ')
          ..write('vehicleId: $vehicleId, ')
          ..write('driverId: $driverId, ')
          ..write('passengerIds: $passengerIds, ')
          ..write('driverCounts: $driverCounts, ')
          ..write('pricePerUnitMilli: $pricePerUnitMilli, ')
          ..write('useKmRate: $useKmRate, ')
          ..write('settledExpenseId: $settledExpenseId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExpenseRevisionsTable extends ExpenseRevisions
    with TableInfo<$ExpenseRevisionsTable, ExpenseRevisionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpenseRevisionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expenseIdMeta = const VerificationMeta(
    'expenseId',
  );
  @override
  late final GeneratedColumn<String> expenseId = GeneratedColumn<String>(
    'expense_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES expenses (id)',
    ),
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    check: () => ComparableExpr(revision).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _authorMemberIdMeta = const VerificationMeta(
    'authorMemberId',
  );
  @override
  late final GeneratedColumn<String> authorMemberId = GeneratedColumn<String>(
    'author_member_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snapshotMeta = const VerificationMeta(
    'snapshot',
  );
  @override
  late final GeneratedColumn<String> snapshot = GeneratedColumn<String>(
    'snapshot',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    expenseId,
    groupId,
    revision,
    changedAt,
    authorMemberId,
    snapshot,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expense_revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExpenseRevisionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('expense_id')) {
      context.handle(
        _expenseIdMeta,
        expenseId.isAcceptableOrUnknown(data['expense_id']!, _expenseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_expenseIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    if (data.containsKey('author_member_id')) {
      context.handle(
        _authorMemberIdMeta,
        authorMemberId.isAcceptableOrUnknown(
          data['author_member_id']!,
          _authorMemberIdMeta,
        ),
      );
    }
    if (data.containsKey('snapshot')) {
      context.handle(
        _snapshotMeta,
        snapshot.isAcceptableOrUnknown(data['snapshot']!, _snapshotMeta),
      );
    } else if (isInserting) {
      context.missing(_snapshotMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ExpenseRevisionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseRevisionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      expenseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expense_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      authorMemberId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author_member_id'],
      ),
      snapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}snapshot'],
      )!,
    );
  }

  @override
  $ExpenseRevisionsTable createAlias(String alias) {
    return $ExpenseRevisionsTable(attachedDatabase, alias);
  }
}

class ExpenseRevisionRow extends DataClass
    implements Insertable<ExpenseRevisionRow> {
  final String id;
  final String expenseId;
  final String groupId;

  /// 1 for the first change of an expense, then increasing.
  final int revision;
  final DateTime changedAt;

  /// Null while nobody is signed in (no accounts yet).
  final String? authorMemberId;

  /// JSON of an `ExpenseSnapshot`. Never contains bank data.
  final String snapshot;
  const ExpenseRevisionRow({
    required this.id,
    required this.expenseId,
    required this.groupId,
    required this.revision,
    required this.changedAt,
    this.authorMemberId,
    required this.snapshot,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['expense_id'] = Variable<String>(expenseId);
    map['group_id'] = Variable<String>(groupId);
    map['revision'] = Variable<int>(revision);
    map['changed_at'] = Variable<DateTime>(changedAt);
    if (!nullToAbsent || authorMemberId != null) {
      map['author_member_id'] = Variable<String>(authorMemberId);
    }
    map['snapshot'] = Variable<String>(snapshot);
    return map;
  }

  ExpenseRevisionsCompanion toCompanion(bool nullToAbsent) {
    return ExpenseRevisionsCompanion(
      id: Value(id),
      expenseId: Value(expenseId),
      groupId: Value(groupId),
      revision: Value(revision),
      changedAt: Value(changedAt),
      authorMemberId: authorMemberId == null && nullToAbsent
          ? const Value.absent()
          : Value(authorMemberId),
      snapshot: Value(snapshot),
    );
  }

  factory ExpenseRevisionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExpenseRevisionRow(
      id: serializer.fromJson<String>(json['id']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      groupId: serializer.fromJson<String>(json['groupId']),
      revision: serializer.fromJson<int>(json['revision']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      authorMemberId: serializer.fromJson<String?>(json['authorMemberId']),
      snapshot: serializer.fromJson<String>(json['snapshot']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'expenseId': serializer.toJson<String>(expenseId),
      'groupId': serializer.toJson<String>(groupId),
      'revision': serializer.toJson<int>(revision),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'authorMemberId': serializer.toJson<String?>(authorMemberId),
      'snapshot': serializer.toJson<String>(snapshot),
    };
  }

  ExpenseRevisionRow copyWith({
    String? id,
    String? expenseId,
    String? groupId,
    int? revision,
    DateTime? changedAt,
    Value<String?> authorMemberId = const Value.absent(),
    String? snapshot,
  }) => ExpenseRevisionRow(
    id: id ?? this.id,
    expenseId: expenseId ?? this.expenseId,
    groupId: groupId ?? this.groupId,
    revision: revision ?? this.revision,
    changedAt: changedAt ?? this.changedAt,
    authorMemberId: authorMemberId.present
        ? authorMemberId.value
        : this.authorMemberId,
    snapshot: snapshot ?? this.snapshot,
  );
  ExpenseRevisionRow copyWithCompanion(ExpenseRevisionsCompanion data) {
    return ExpenseRevisionRow(
      id: data.id.present ? data.id.value : this.id,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      revision: data.revision.present ? data.revision.value : this.revision,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      authorMemberId: data.authorMemberId.present
          ? data.authorMemberId.value
          : this.authorMemberId,
      snapshot: data.snapshot.present ? data.snapshot.value : this.snapshot,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRevisionRow(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('groupId: $groupId, ')
          ..write('revision: $revision, ')
          ..write('changedAt: $changedAt, ')
          ..write('authorMemberId: $authorMemberId, ')
          ..write('snapshot: $snapshot')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    expenseId,
    groupId,
    revision,
    changedAt,
    authorMemberId,
    snapshot,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseRevisionRow &&
          other.id == this.id &&
          other.expenseId == this.expenseId &&
          other.groupId == this.groupId &&
          other.revision == this.revision &&
          other.changedAt == this.changedAt &&
          other.authorMemberId == this.authorMemberId &&
          other.snapshot == this.snapshot);
}

class ExpenseRevisionsCompanion extends UpdateCompanion<ExpenseRevisionRow> {
  final Value<String> id;
  final Value<String> expenseId;
  final Value<String> groupId;
  final Value<int> revision;
  final Value<DateTime> changedAt;
  final Value<String?> authorMemberId;
  final Value<String> snapshot;
  final Value<int> rowid;
  const ExpenseRevisionsCompanion({
    this.id = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.revision = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.authorMemberId = const Value.absent(),
    this.snapshot = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseRevisionsCompanion.insert({
    required String id,
    required String expenseId,
    required String groupId,
    required int revision,
    required DateTime changedAt,
    this.authorMemberId = const Value.absent(),
    required String snapshot,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       expenseId = Value(expenseId),
       groupId = Value(groupId),
       revision = Value(revision),
       changedAt = Value(changedAt),
       snapshot = Value(snapshot);
  static Insertable<ExpenseRevisionRow> custom({
    Expression<String>? id,
    Expression<String>? expenseId,
    Expression<String>? groupId,
    Expression<int>? revision,
    Expression<DateTime>? changedAt,
    Expression<String>? authorMemberId,
    Expression<String>? snapshot,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (expenseId != null) 'expense_id': expenseId,
      if (groupId != null) 'group_id': groupId,
      if (revision != null) 'revision': revision,
      if (changedAt != null) 'changed_at': changedAt,
      if (authorMemberId != null) 'author_member_id': authorMemberId,
      if (snapshot != null) 'snapshot': snapshot,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseRevisionsCompanion copyWith({
    Value<String>? id,
    Value<String>? expenseId,
    Value<String>? groupId,
    Value<int>? revision,
    Value<DateTime>? changedAt,
    Value<String?>? authorMemberId,
    Value<String>? snapshot,
    Value<int>? rowid,
  }) {
    return ExpenseRevisionsCompanion(
      id: id ?? this.id,
      expenseId: expenseId ?? this.expenseId,
      groupId: groupId ?? this.groupId,
      revision: revision ?? this.revision,
      changedAt: changedAt ?? this.changedAt,
      authorMemberId: authorMemberId ?? this.authorMemberId,
      snapshot: snapshot ?? this.snapshot,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (expenseId.present) {
      map['expense_id'] = Variable<String>(expenseId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (authorMemberId.present) {
      map['author_member_id'] = Variable<String>(authorMemberId.value);
    }
    if (snapshot.present) {
      map['snapshot'] = Variable<String>(snapshot.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpenseRevisionsCompanion(')
          ..write('id: $id, ')
          ..write('expenseId: $expenseId, ')
          ..write('groupId: $groupId, ')
          ..write('revision: $revision, ')
          ..write('changedAt: $changedAt, ')
          ..write('authorMemberId: $authorMemberId, ')
          ..write('snapshot: $snapshot, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalGroupSyncTable extends LocalGroupSync
    with TableInfo<$LocalGroupSyncTable, LocalGroupSyncRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalGroupSyncTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _lastPushAtMeta = const VerificationMeta(
    'lastPushAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPushAt = GeneratedColumn<DateTime>(
    'last_push_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastPullAtMeta = const VerificationMeta(
    'lastPullAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastPullAt = GeneratedColumn<DateTime>(
    'last_pull_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorCodeMeta = const VerificationMeta(
    'lastErrorCode',
  );
  @override
  late final GeneratedColumn<String> lastErrorCode = GeneratedColumn<String>(
    'last_error_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorAtMeta = const VerificationMeta(
    'lastErrorAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastErrorAt = GeneratedColumn<DateTime>(
    'last_error_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    groupId,
    state,
    role,
    lastPushAt,
    lastPullAt,
    lastErrorCode,
    lastErrorAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_group_sync';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalGroupSyncRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('role')) {
      context.handle(
        _roleMeta,
        role.isAcceptableOrUnknown(data['role']!, _roleMeta),
      );
    }
    if (data.containsKey('last_push_at')) {
      context.handle(
        _lastPushAtMeta,
        lastPushAt.isAcceptableOrUnknown(
          data['last_push_at']!,
          _lastPushAtMeta,
        ),
      );
    }
    if (data.containsKey('last_pull_at')) {
      context.handle(
        _lastPullAtMeta,
        lastPullAt.isAcceptableOrUnknown(
          data['last_pull_at']!,
          _lastPullAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error_code')) {
      context.handle(
        _lastErrorCodeMeta,
        lastErrorCode.isAcceptableOrUnknown(
          data['last_error_code']!,
          _lastErrorCodeMeta,
        ),
      );
    }
    if (data.containsKey('last_error_at')) {
      context.handle(
        _lastErrorAtMeta,
        lastErrorAt.isAcceptableOrUnknown(
          data['last_error_at']!,
          _lastErrorAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  LocalGroupSyncRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalGroupSyncRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      role: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}role'],
      ),
      lastPushAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_push_at'],
      ),
      lastPullAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_pull_at'],
      ),
      lastErrorCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error_code'],
      ),
      lastErrorAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_error_at'],
      ),
    );
  }

  @override
  $LocalGroupSyncTable createAlias(String alias) {
    return $LocalGroupSyncTable(attachedDatabase, alias);
  }
}

class LocalGroupSyncRow extends DataClass
    implements Insertable<LocalGroupSyncRow> {
  final String groupId;

  /// `shared` / `uploading` / `removed` (`SyncState` in `sync_state_dao.dart`).
  final String state;

  /// `owner` / `member`; null until known.
  final String? role;
  final DateTime? lastPushAt;
  final DateTime? lastPullAt;

  /// Stable error case name of the last failure (ADR-27 §3).
  final String? lastErrorCode;
  final DateTime? lastErrorAt;
  const LocalGroupSyncRow({
    required this.groupId,
    required this.state,
    this.role,
    this.lastPushAt,
    this.lastPullAt,
    this.lastErrorCode,
    this.lastErrorAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || role != null) {
      map['role'] = Variable<String>(role);
    }
    if (!nullToAbsent || lastPushAt != null) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt);
    }
    if (!nullToAbsent || lastPullAt != null) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt);
    }
    if (!nullToAbsent || lastErrorCode != null) {
      map['last_error_code'] = Variable<String>(lastErrorCode);
    }
    if (!nullToAbsent || lastErrorAt != null) {
      map['last_error_at'] = Variable<DateTime>(lastErrorAt);
    }
    return map;
  }

  LocalGroupSyncCompanion toCompanion(bool nullToAbsent) {
    return LocalGroupSyncCompanion(
      groupId: Value(groupId),
      state: Value(state),
      role: role == null && nullToAbsent ? const Value.absent() : Value(role),
      lastPushAt: lastPushAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPushAt),
      lastPullAt: lastPullAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastPullAt),
      lastErrorCode: lastErrorCode == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorCode),
      lastErrorAt: lastErrorAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastErrorAt),
    );
  }

  factory LocalGroupSyncRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalGroupSyncRow(
      groupId: serializer.fromJson<String>(json['groupId']),
      state: serializer.fromJson<String>(json['state']),
      role: serializer.fromJson<String?>(json['role']),
      lastPushAt: serializer.fromJson<DateTime?>(json['lastPushAt']),
      lastPullAt: serializer.fromJson<DateTime?>(json['lastPullAt']),
      lastErrorCode: serializer.fromJson<String?>(json['lastErrorCode']),
      lastErrorAt: serializer.fromJson<DateTime?>(json['lastErrorAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'state': serializer.toJson<String>(state),
      'role': serializer.toJson<String?>(role),
      'lastPushAt': serializer.toJson<DateTime?>(lastPushAt),
      'lastPullAt': serializer.toJson<DateTime?>(lastPullAt),
      'lastErrorCode': serializer.toJson<String?>(lastErrorCode),
      'lastErrorAt': serializer.toJson<DateTime?>(lastErrorAt),
    };
  }

  LocalGroupSyncRow copyWith({
    String? groupId,
    String? state,
    Value<String?> role = const Value.absent(),
    Value<DateTime?> lastPushAt = const Value.absent(),
    Value<DateTime?> lastPullAt = const Value.absent(),
    Value<String?> lastErrorCode = const Value.absent(),
    Value<DateTime?> lastErrorAt = const Value.absent(),
  }) => LocalGroupSyncRow(
    groupId: groupId ?? this.groupId,
    state: state ?? this.state,
    role: role.present ? role.value : this.role,
    lastPushAt: lastPushAt.present ? lastPushAt.value : this.lastPushAt,
    lastPullAt: lastPullAt.present ? lastPullAt.value : this.lastPullAt,
    lastErrorCode: lastErrorCode.present
        ? lastErrorCode.value
        : this.lastErrorCode,
    lastErrorAt: lastErrorAt.present ? lastErrorAt.value : this.lastErrorAt,
  );
  LocalGroupSyncRow copyWithCompanion(LocalGroupSyncCompanion data) {
    return LocalGroupSyncRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      state: data.state.present ? data.state.value : this.state,
      role: data.role.present ? data.role.value : this.role,
      lastPushAt: data.lastPushAt.present
          ? data.lastPushAt.value
          : this.lastPushAt,
      lastPullAt: data.lastPullAt.present
          ? data.lastPullAt.value
          : this.lastPullAt,
      lastErrorCode: data.lastErrorCode.present
          ? data.lastErrorCode.value
          : this.lastErrorCode,
      lastErrorAt: data.lastErrorAt.present
          ? data.lastErrorAt.value
          : this.lastErrorAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalGroupSyncRow(')
          ..write('groupId: $groupId, ')
          ..write('state: $state, ')
          ..write('role: $role, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorAt: $lastErrorAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    state,
    role,
    lastPushAt,
    lastPullAt,
    lastErrorCode,
    lastErrorAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalGroupSyncRow &&
          other.groupId == this.groupId &&
          other.state == this.state &&
          other.role == this.role &&
          other.lastPushAt == this.lastPushAt &&
          other.lastPullAt == this.lastPullAt &&
          other.lastErrorCode == this.lastErrorCode &&
          other.lastErrorAt == this.lastErrorAt);
}

class LocalGroupSyncCompanion extends UpdateCompanion<LocalGroupSyncRow> {
  final Value<String> groupId;
  final Value<String> state;
  final Value<String?> role;
  final Value<DateTime?> lastPushAt;
  final Value<DateTime?> lastPullAt;
  final Value<String?> lastErrorCode;
  final Value<DateTime?> lastErrorAt;
  final Value<int> rowid;
  const LocalGroupSyncCompanion({
    this.groupId = const Value.absent(),
    this.state = const Value.absent(),
    this.role = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalGroupSyncCompanion.insert({
    required String groupId,
    required String state,
    this.role = const Value.absent(),
    this.lastPushAt = const Value.absent(),
    this.lastPullAt = const Value.absent(),
    this.lastErrorCode = const Value.absent(),
    this.lastErrorAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       state = Value(state);
  static Insertable<LocalGroupSyncRow> custom({
    Expression<String>? groupId,
    Expression<String>? state,
    Expression<String>? role,
    Expression<DateTime>? lastPushAt,
    Expression<DateTime>? lastPullAt,
    Expression<String>? lastErrorCode,
    Expression<DateTime>? lastErrorAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (state != null) 'state': state,
      if (role != null) 'role': role,
      if (lastPushAt != null) 'last_push_at': lastPushAt,
      if (lastPullAt != null) 'last_pull_at': lastPullAt,
      if (lastErrorCode != null) 'last_error_code': lastErrorCode,
      if (lastErrorAt != null) 'last_error_at': lastErrorAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalGroupSyncCompanion copyWith({
    Value<String>? groupId,
    Value<String>? state,
    Value<String?>? role,
    Value<DateTime?>? lastPushAt,
    Value<DateTime?>? lastPullAt,
    Value<String?>? lastErrorCode,
    Value<DateTime?>? lastErrorAt,
    Value<int>? rowid,
  }) {
    return LocalGroupSyncCompanion(
      groupId: groupId ?? this.groupId,
      state: state ?? this.state,
      role: role ?? this.role,
      lastPushAt: lastPushAt ?? this.lastPushAt,
      lastPullAt: lastPullAt ?? this.lastPullAt,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorAt: lastErrorAt ?? this.lastErrorAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (role.present) {
      map['role'] = Variable<String>(role.value);
    }
    if (lastPushAt.present) {
      map['last_push_at'] = Variable<DateTime>(lastPushAt.value);
    }
    if (lastPullAt.present) {
      map['last_pull_at'] = Variable<DateTime>(lastPullAt.value);
    }
    if (lastErrorCode.present) {
      map['last_error_code'] = Variable<String>(lastErrorCode.value);
    }
    if (lastErrorAt.present) {
      map['last_error_at'] = Variable<DateTime>(lastErrorAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalGroupSyncCompanion(')
          ..write('groupId: $groupId, ')
          ..write('state: $state, ')
          ..write('role: $role, ')
          ..write('lastPushAt: $lastPushAt, ')
          ..write('lastPullAt: $lastPullAt, ')
          ..write('lastErrorCode: $lastErrorCode, ')
          ..write('lastErrorAt: $lastErrorAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncCursorTable extends LocalSyncCursor
    with TableInfo<$LocalSyncCursorTable, LocalSyncCursorRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncCursorTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES "groups" (id)',
    ),
  );
  static const VerificationMeta _syncedTableMeta = const VerificationMeta(
    'syncedTable',
  );
  @override
  late final GeneratedColumn<String> syncedTable = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, syncedTable, cursor];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_cursor';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncCursorRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('table_name')) {
      context.handle(
        _syncedTableMeta,
        syncedTable.isAcceptableOrUnknown(
          data['table_name']!,
          _syncedTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncedTableMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, syncedTable};
  @override
  LocalSyncCursorRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncCursorRow(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      syncedTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor'],
      )!,
    );
  }

  @override
  $LocalSyncCursorTable createAlias(String alias) {
    return $LocalSyncCursorTable(attachedDatabase, alias);
  }
}

class LocalSyncCursorRow extends DataClass
    implements Insertable<LocalSyncCursorRow> {
  final String groupId;

  /// SQL column `table_name` (`tableName` clashes with `Table.tableName`).
  final String syncedTable;
  final int cursor;
  const LocalSyncCursorRow({
    required this.groupId,
    required this.syncedTable,
    required this.cursor,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['table_name'] = Variable<String>(syncedTable);
    map['cursor'] = Variable<int>(cursor);
    return map;
  }

  LocalSyncCursorCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncCursorCompanion(
      groupId: Value(groupId),
      syncedTable: Value(syncedTable),
      cursor: Value(cursor),
    );
  }

  factory LocalSyncCursorRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncCursorRow(
      groupId: serializer.fromJson<String>(json['groupId']),
      syncedTable: serializer.fromJson<String>(json['syncedTable']),
      cursor: serializer.fromJson<int>(json['cursor']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'groupId': serializer.toJson<String>(groupId),
      'syncedTable': serializer.toJson<String>(syncedTable),
      'cursor': serializer.toJson<int>(cursor),
    };
  }

  LocalSyncCursorRow copyWith({
    String? groupId,
    String? syncedTable,
    int? cursor,
  }) => LocalSyncCursorRow(
    groupId: groupId ?? this.groupId,
    syncedTable: syncedTable ?? this.syncedTable,
    cursor: cursor ?? this.cursor,
  );
  LocalSyncCursorRow copyWithCompanion(LocalSyncCursorCompanion data) {
    return LocalSyncCursorRow(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      syncedTable: data.syncedTable.present
          ? data.syncedTable.value
          : this.syncedTable,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncCursorRow(')
          ..write('groupId: $groupId, ')
          ..write('syncedTable: $syncedTable, ')
          ..write('cursor: $cursor')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, syncedTable, cursor);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncCursorRow &&
          other.groupId == this.groupId &&
          other.syncedTable == this.syncedTable &&
          other.cursor == this.cursor);
}

class LocalSyncCursorCompanion extends UpdateCompanion<LocalSyncCursorRow> {
  final Value<String> groupId;
  final Value<String> syncedTable;
  final Value<int> cursor;
  final Value<int> rowid;
  const LocalSyncCursorCompanion({
    this.groupId = const Value.absent(),
    this.syncedTable = const Value.absent(),
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncCursorCompanion.insert({
    required String groupId,
    required String syncedTable,
    this.cursor = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       syncedTable = Value(syncedTable);
  static Insertable<LocalSyncCursorRow> custom({
    Expression<String>? groupId,
    Expression<String>? syncedTable,
    Expression<int>? cursor,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (syncedTable != null) 'table_name': syncedTable,
      if (cursor != null) 'cursor': cursor,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncCursorCompanion copyWith({
    Value<String>? groupId,
    Value<String>? syncedTable,
    Value<int>? cursor,
    Value<int>? rowid,
  }) {
    return LocalSyncCursorCompanion(
      groupId: groupId ?? this.groupId,
      syncedTable: syncedTable ?? this.syncedTable,
      cursor: cursor ?? this.cursor,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (syncedTable.present) {
      map['table_name'] = Variable<String>(syncedTable.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncCursorCompanion(')
          ..write('groupId: $groupId, ')
          ..write('syncedTable: $syncedTable, ')
          ..write('cursor: $cursor, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSettingsTable extends LocalSettings
    with TableInfo<$LocalSettingsTable, LocalSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalSettingsTable createAlias(String alias) {
    return $LocalSettingsTable(attachedDatabase, alias);
  }
}

class LocalSettingRow extends DataClass implements Insertable<LocalSettingRow> {
  final String key;
  final String value;
  const LocalSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  LocalSettingsCompanion toCompanion(bool nullToAbsent) {
    return LocalSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  LocalSettingRow copyWith({String? key, String? value}) =>
      LocalSettingRow(key: key ?? this.key, value: value ?? this.value);
  LocalSettingRow copyWithCompanion(LocalSettingsCompanion data) {
    return LocalSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSettingsCompanion extends UpdateCompanion<LocalSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const LocalSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return LocalSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProfileTable extends Profile with TableInfo<$ProfileTable, ProfileRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    check: () => id.equals(profileRowId),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarColorMeta = const VerificationMeta(
    'avatarColor',
  );
  @override
  late final GeneratedColumn<int> avatarColor = GeneratedColumn<int>(
    'avatar_color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _avatarEmojiMeta = const VerificationMeta(
    'avatarEmoji',
  );
  @override
  late final GeneratedColumn<String> avatarEmoji = GeneratedColumn<String>(
    'avatar_emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paypalMeMeta = const VerificationMeta(
    'paypalMe',
  );
  @override
  late final GeneratedColumn<String> paypalMe = GeneratedColumn<String>(
    'paypal_me',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    displayName,
    avatarColor,
    avatarEmoji,
    paypalMe,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profile';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProfileRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('avatar_color')) {
      context.handle(
        _avatarColorMeta,
        avatarColor.isAcceptableOrUnknown(
          data['avatar_color']!,
          _avatarColorMeta,
        ),
      );
    }
    if (data.containsKey('avatar_emoji')) {
      context.handle(
        _avatarEmojiMeta,
        avatarEmoji.isAcceptableOrUnknown(
          data['avatar_emoji']!,
          _avatarEmojiMeta,
        ),
      );
    }
    if (data.containsKey('paypal_me')) {
      context.handle(
        _paypalMeMeta,
        paypalMe.isAcceptableOrUnknown(data['paypal_me']!, _paypalMeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProfileRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProfileRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      avatarColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}avatar_color'],
      ),
      avatarEmoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_emoji'],
      ),
      paypalMe: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paypal_me'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProfileTable createAlias(String alias) {
    return $ProfileTable(attachedDatabase, alias);
  }
}

class ProfileRow extends DataClass implements Insertable<ProfileRow> {
  final String id;
  final String displayName;

  /// Colour of the initials avatar as ARGB int; null = derived default.
  final int? avatarColor;
  final String? avatarEmoji;

  /// Normalised PayPal.Me handle.
  final String? paypalMe;
  final String updatedAt;
  const ProfileRow({
    required this.id,
    required this.displayName,
    this.avatarColor,
    this.avatarEmoji,
    this.paypalMe,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['display_name'] = Variable<String>(displayName);
    if (!nullToAbsent || avatarColor != null) {
      map['avatar_color'] = Variable<int>(avatarColor);
    }
    if (!nullToAbsent || avatarEmoji != null) {
      map['avatar_emoji'] = Variable<String>(avatarEmoji);
    }
    if (!nullToAbsent || paypalMe != null) {
      map['paypal_me'] = Variable<String>(paypalMe);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  ProfileCompanion toCompanion(bool nullToAbsent) {
    return ProfileCompanion(
      id: Value(id),
      displayName: Value(displayName),
      avatarColor: avatarColor == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarColor),
      avatarEmoji: avatarEmoji == null && nullToAbsent
          ? const Value.absent()
          : Value(avatarEmoji),
      paypalMe: paypalMe == null && nullToAbsent
          ? const Value.absent()
          : Value(paypalMe),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProfileRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProfileRow(
      id: serializer.fromJson<String>(json['id']),
      displayName: serializer.fromJson<String>(json['displayName']),
      avatarColor: serializer.fromJson<int?>(json['avatarColor']),
      avatarEmoji: serializer.fromJson<String?>(json['avatarEmoji']),
      paypalMe: serializer.fromJson<String?>(json['paypalMe']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'displayName': serializer.toJson<String>(displayName),
      'avatarColor': serializer.toJson<int?>(avatarColor),
      'avatarEmoji': serializer.toJson<String?>(avatarEmoji),
      'paypalMe': serializer.toJson<String?>(paypalMe),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  ProfileRow copyWith({
    String? id,
    String? displayName,
    Value<int?> avatarColor = const Value.absent(),
    Value<String?> avatarEmoji = const Value.absent(),
    Value<String?> paypalMe = const Value.absent(),
    String? updatedAt,
  }) => ProfileRow(
    id: id ?? this.id,
    displayName: displayName ?? this.displayName,
    avatarColor: avatarColor.present ? avatarColor.value : this.avatarColor,
    avatarEmoji: avatarEmoji.present ? avatarEmoji.value : this.avatarEmoji,
    paypalMe: paypalMe.present ? paypalMe.value : this.paypalMe,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProfileRow copyWithCompanion(ProfileCompanion data) {
    return ProfileRow(
      id: data.id.present ? data.id.value : this.id,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      avatarColor: data.avatarColor.present
          ? data.avatarColor.value
          : this.avatarColor,
      avatarEmoji: data.avatarEmoji.present
          ? data.avatarEmoji.value
          : this.avatarEmoji,
      paypalMe: data.paypalMe.present ? data.paypalMe.value : this.paypalMe,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProfileRow(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('paypalMe: $paypalMe, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    displayName,
    avatarColor,
    avatarEmoji,
    paypalMe,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProfileRow &&
          other.id == this.id &&
          other.displayName == this.displayName &&
          other.avatarColor == this.avatarColor &&
          other.avatarEmoji == this.avatarEmoji &&
          other.paypalMe == this.paypalMe &&
          other.updatedAt == this.updatedAt);
}

class ProfileCompanion extends UpdateCompanion<ProfileRow> {
  final Value<String> id;
  final Value<String> displayName;
  final Value<int?> avatarColor;
  final Value<String?> avatarEmoji;
  final Value<String?> paypalMe;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const ProfileCompanion({
    this.id = const Value.absent(),
    this.displayName = const Value.absent(),
    this.avatarColor = const Value.absent(),
    this.avatarEmoji = const Value.absent(),
    this.paypalMe = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProfileCompanion.insert({
    required String id,
    required String displayName,
    this.avatarColor = const Value.absent(),
    this.avatarEmoji = const Value.absent(),
    this.paypalMe = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       displayName = Value(displayName),
       updatedAt = Value(updatedAt);
  static Insertable<ProfileRow> custom({
    Expression<String>? id,
    Expression<String>? displayName,
    Expression<int>? avatarColor,
    Expression<String>? avatarEmoji,
    Expression<String>? paypalMe,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (displayName != null) 'display_name': displayName,
      if (avatarColor != null) 'avatar_color': avatarColor,
      if (avatarEmoji != null) 'avatar_emoji': avatarEmoji,
      if (paypalMe != null) 'paypal_me': paypalMe,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProfileCompanion copyWith({
    Value<String>? id,
    Value<String>? displayName,
    Value<int?>? avatarColor,
    Value<String?>? avatarEmoji,
    Value<String?>? paypalMe,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProfileCompanion(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      paypalMe: paypalMe ?? this.paypalMe,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (avatarColor.present) {
      map['avatar_color'] = Variable<int>(avatarColor.value);
    }
    if (avatarEmoji.present) {
      map['avatar_emoji'] = Variable<String>(avatarEmoji.value);
    }
    if (paypalMe.present) {
      map['paypal_me'] = Variable<String>(paypalMe.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProfileCompanion(')
          ..write('id: $id, ')
          ..write('displayName: $displayName, ')
          ..write('avatarColor: $avatarColor, ')
          ..write('avatarEmoji: $avatarEmoji, ')
          ..write('paypalMe: $paypalMe, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalProfileBankTable extends LocalProfileBank
    with TableInfo<$LocalProfileBankTable, LocalProfileBankRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalProfileBankTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES profile (id)',
    ),
  );
  static const VerificationMeta _ibanMeta = const VerificationMeta('iban');
  @override
  late final GeneratedColumn<String> iban = GeneratedColumn<String>(
    'iban',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bicMeta = const VerificationMeta('bic');
  @override
  late final GeneratedColumn<String> bic = GeneratedColumn<String>(
    'bic',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    iban,
    bic,
    accountName,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_profile_bank';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalProfileBankRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('iban')) {
      context.handle(
        _ibanMeta,
        iban.isAcceptableOrUnknown(data['iban']!, _ibanMeta),
      );
    } else if (isInserting) {
      context.missing(_ibanMeta);
    }
    if (data.containsKey('bic')) {
      context.handle(
        _bicMeta,
        bic.isAcceptableOrUnknown(data['bic']!, _bicMeta),
      );
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId};
  @override
  LocalProfileBankRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalProfileBankRow(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      iban: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}iban'],
      )!,
      bic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}bic'],
      ),
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalProfileBankTable createAlias(String alias) {
    return $LocalProfileBankTable(attachedDatabase, alias);
  }
}

class LocalProfileBankRow extends DataClass
    implements Insertable<LocalProfileBankRow> {
  final String profileId;
  final String iban;
  final String? bic;
  final String? accountName;
  final String updatedAt;
  const LocalProfileBankRow({
    required this.profileId,
    required this.iban,
    this.bic,
    this.accountName,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<String>(profileId);
    map['iban'] = Variable<String>(iban);
    if (!nullToAbsent || bic != null) {
      map['bic'] = Variable<String>(bic);
    }
    if (!nullToAbsent || accountName != null) {
      map['account_name'] = Variable<String>(accountName);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  LocalProfileBankCompanion toCompanion(bool nullToAbsent) {
    return LocalProfileBankCompanion(
      profileId: Value(profileId),
      iban: Value(iban),
      bic: bic == null && nullToAbsent ? const Value.absent() : Value(bic),
      accountName: accountName == null && nullToAbsent
          ? const Value.absent()
          : Value(accountName),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalProfileBankRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalProfileBankRow(
      profileId: serializer.fromJson<String>(json['profileId']),
      iban: serializer.fromJson<String>(json['iban']),
      bic: serializer.fromJson<String?>(json['bic']),
      accountName: serializer.fromJson<String?>(json['accountName']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<String>(profileId),
      'iban': serializer.toJson<String>(iban),
      'bic': serializer.toJson<String?>(bic),
      'accountName': serializer.toJson<String?>(accountName),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  LocalProfileBankRow copyWith({
    String? profileId,
    String? iban,
    Value<String?> bic = const Value.absent(),
    Value<String?> accountName = const Value.absent(),
    String? updatedAt,
  }) => LocalProfileBankRow(
    profileId: profileId ?? this.profileId,
    iban: iban ?? this.iban,
    bic: bic.present ? bic.value : this.bic,
    accountName: accountName.present ? accountName.value : this.accountName,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalProfileBankRow copyWithCompanion(LocalProfileBankCompanion data) {
    return LocalProfileBankRow(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      iban: data.iban.present ? data.iban.value : this.iban,
      bic: data.bic.present ? data.bic.value : this.bic,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfileBankRow(')
          ..write('profileId: $profileId, ')
          ..write('iban: $iban, ')
          ..write('bic: $bic, ')
          ..write('accountName: $accountName, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(profileId, iban, bic, accountName, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalProfileBankRow &&
          other.profileId == this.profileId &&
          other.iban == this.iban &&
          other.bic == this.bic &&
          other.accountName == this.accountName &&
          other.updatedAt == this.updatedAt);
}

class LocalProfileBankCompanion extends UpdateCompanion<LocalProfileBankRow> {
  final Value<String> profileId;
  final Value<String> iban;
  final Value<String?> bic;
  final Value<String?> accountName;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const LocalProfileBankCompanion({
    this.profileId = const Value.absent(),
    this.iban = const Value.absent(),
    this.bic = const Value.absent(),
    this.accountName = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalProfileBankCompanion.insert({
    required String profileId,
    required String iban,
    this.bic = const Value.absent(),
    this.accountName = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId),
       iban = Value(iban),
       updatedAt = Value(updatedAt);
  static Insertable<LocalProfileBankRow> custom({
    Expression<String>? profileId,
    Expression<String>? iban,
    Expression<String>? bic,
    Expression<String>? accountName,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (iban != null) 'iban': iban,
      if (bic != null) 'bic': bic,
      if (accountName != null) 'account_name': accountName,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalProfileBankCompanion copyWith({
    Value<String>? profileId,
    Value<String>? iban,
    Value<String?>? bic,
    Value<String?>? accountName,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalProfileBankCompanion(
      profileId: profileId ?? this.profileId,
      iban: iban ?? this.iban,
      bic: bic ?? this.bic,
      accountName: accountName ?? this.accountName,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (iban.present) {
      map['iban'] = Variable<String>(iban.value);
    }
    if (bic.present) {
      map['bic'] = Variable<String>(bic.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalProfileBankCompanion(')
          ..write('profileId: $profileId, ')
          ..write('iban: $iban, ')
          ..write('bic: $bic, ')
          ..write('accountName: $accountName, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserVehiclesTable extends UserVehicles
    with TableInfo<$UserVehiclesTable, UserVehicleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserVehiclesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fuelTypeMeta = const VerificationMeta(
    'fuelType',
  );
  @override
  late final GeneratedColumn<String> fuelType = GeneratedColumn<String>(
    'fuel_type',
    aliasedName,
    false,
    check: () => fuelType.isIn(const ['petrol', 'diesel', 'electric', 'other']),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _consumptionMilliPer100kmMeta =
      const VerificationMeta('consumptionMilliPer100km');
  @override
  late final GeneratedColumn<int> consumptionMilliPer100km =
      GeneratedColumn<int>(
        'consumption_milli_per100km',
        aliasedName,
        false,
        check: () =>
            ComparableExpr(consumptionMilliPer100km).isBiggerThanValue(0),
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _wearMilliPerKmMeta = const VerificationMeta(
    'wearMilliPerKm',
  );
  @override
  late final GeneratedColumn<int> wearMilliPerKm = GeneratedColumn<int>(
    'wear_milli_per_km',
    aliasedName,
    false,
    check: () => ComparableExpr(wearMilliPerKm).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _kmRateMilliPerKmMeta = const VerificationMeta(
    'kmRateMilliPerKm',
  );
  @override
  late final GeneratedColumn<int> kmRateMilliPerKm = GeneratedColumn<int>(
    'km_rate_milli_per_km',
    aliasedName,
    true,
    check: () => ComparableExpr(kmRateMilliPerKm).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    fuelType,
    consumptionMilliPer100km,
    wearMilliPerKm,
    kmRateMilliPerKm,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_vehicles';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserVehicleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('fuel_type')) {
      context.handle(
        _fuelTypeMeta,
        fuelType.isAcceptableOrUnknown(data['fuel_type']!, _fuelTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fuelTypeMeta);
    }
    if (data.containsKey('consumption_milli_per100km')) {
      context.handle(
        _consumptionMilliPer100kmMeta,
        consumptionMilliPer100km.isAcceptableOrUnknown(
          data['consumption_milli_per100km']!,
          _consumptionMilliPer100kmMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_consumptionMilliPer100kmMeta);
    }
    if (data.containsKey('wear_milli_per_km')) {
      context.handle(
        _wearMilliPerKmMeta,
        wearMilliPerKm.isAcceptableOrUnknown(
          data['wear_milli_per_km']!,
          _wearMilliPerKmMeta,
        ),
      );
    }
    if (data.containsKey('km_rate_milli_per_km')) {
      context.handle(
        _kmRateMilliPerKmMeta,
        kmRateMilliPerKm.isAcceptableOrUnknown(
          data['km_rate_milli_per_km']!,
          _kmRateMilliPerKmMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserVehicleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserVehicleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      fuelType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fuel_type'],
      )!,
      consumptionMilliPer100km: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}consumption_milli_per100km'],
      )!,
      wearMilliPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wear_milli_per_km'],
      )!,
      kmRateMilliPerKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}km_rate_milli_per_km'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $UserVehiclesTable createAlias(String alias) {
    return $UserVehiclesTable(attachedDatabase, alias);
  }
}

class UserVehicleRow extends DataClass implements Insertable<UserVehicleRow> {
  final String id;
  final String name;
  final String fuelType;
  final int consumptionMilliPer100km;
  final int wearMilliPerKm;
  final int? kmRateMilliPerKm;
  final DateTime createdAt;
  final String updatedAt;
  final DateTime? deletedAt;
  const UserVehicleRow({
    required this.id,
    required this.name,
    required this.fuelType,
    required this.consumptionMilliPer100km,
    required this.wearMilliPerKm,
    this.kmRateMilliPerKm,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['fuel_type'] = Variable<String>(fuelType);
    map['consumption_milli_per100km'] = Variable<int>(consumptionMilliPer100km);
    map['wear_milli_per_km'] = Variable<int>(wearMilliPerKm);
    if (!nullToAbsent || kmRateMilliPerKm != null) {
      map['km_rate_milli_per_km'] = Variable<int>(kmRateMilliPerKm);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  UserVehiclesCompanion toCompanion(bool nullToAbsent) {
    return UserVehiclesCompanion(
      id: Value(id),
      name: Value(name),
      fuelType: Value(fuelType),
      consumptionMilliPer100km: Value(consumptionMilliPer100km),
      wearMilliPerKm: Value(wearMilliPerKm),
      kmRateMilliPerKm: kmRateMilliPerKm == null && nullToAbsent
          ? const Value.absent()
          : Value(kmRateMilliPerKm),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory UserVehicleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserVehicleRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      fuelType: serializer.fromJson<String>(json['fuelType']),
      consumptionMilliPer100km: serializer.fromJson<int>(
        json['consumptionMilliPer100km'],
      ),
      wearMilliPerKm: serializer.fromJson<int>(json['wearMilliPerKm']),
      kmRateMilliPerKm: serializer.fromJson<int?>(json['kmRateMilliPerKm']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'fuelType': serializer.toJson<String>(fuelType),
      'consumptionMilliPer100km': serializer.toJson<int>(
        consumptionMilliPer100km,
      ),
      'wearMilliPerKm': serializer.toJson<int>(wearMilliPerKm),
      'kmRateMilliPerKm': serializer.toJson<int?>(kmRateMilliPerKm),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  UserVehicleRow copyWith({
    String? id,
    String? name,
    String? fuelType,
    int? consumptionMilliPer100km,
    int? wearMilliPerKm,
    Value<int?> kmRateMilliPerKm = const Value.absent(),
    DateTime? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => UserVehicleRow(
    id: id ?? this.id,
    name: name ?? this.name,
    fuelType: fuelType ?? this.fuelType,
    consumptionMilliPer100km:
        consumptionMilliPer100km ?? this.consumptionMilliPer100km,
    wearMilliPerKm: wearMilliPerKm ?? this.wearMilliPerKm,
    kmRateMilliPerKm: kmRateMilliPerKm.present
        ? kmRateMilliPerKm.value
        : this.kmRateMilliPerKm,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  UserVehicleRow copyWithCompanion(UserVehiclesCompanion data) {
    return UserVehicleRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      fuelType: data.fuelType.present ? data.fuelType.value : this.fuelType,
      consumptionMilliPer100km: data.consumptionMilliPer100km.present
          ? data.consumptionMilliPer100km.value
          : this.consumptionMilliPer100km,
      wearMilliPerKm: data.wearMilliPerKm.present
          ? data.wearMilliPerKm.value
          : this.wearMilliPerKm,
      kmRateMilliPerKm: data.kmRateMilliPerKm.present
          ? data.kmRateMilliPerKm.value
          : this.kmRateMilliPerKm,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserVehicleRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fuelType: $fuelType, ')
          ..write('consumptionMilliPer100km: $consumptionMilliPer100km, ')
          ..write('wearMilliPerKm: $wearMilliPerKm, ')
          ..write('kmRateMilliPerKm: $kmRateMilliPerKm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    fuelType,
    consumptionMilliPer100km,
    wearMilliPerKm,
    kmRateMilliPerKm,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserVehicleRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.fuelType == this.fuelType &&
          other.consumptionMilliPer100km == this.consumptionMilliPer100km &&
          other.wearMilliPerKm == this.wearMilliPerKm &&
          other.kmRateMilliPerKm == this.kmRateMilliPerKm &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class UserVehiclesCompanion extends UpdateCompanion<UserVehicleRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> fuelType;
  final Value<int> consumptionMilliPer100km;
  final Value<int> wearMilliPerKm;
  final Value<int?> kmRateMilliPerKm;
  final Value<DateTime> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const UserVehiclesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.fuelType = const Value.absent(),
    this.consumptionMilliPer100km = const Value.absent(),
    this.wearMilliPerKm = const Value.absent(),
    this.kmRateMilliPerKm = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserVehiclesCompanion.insert({
    required String id,
    required String name,
    required String fuelType,
    required int consumptionMilliPer100km,
    this.wearMilliPerKm = const Value.absent(),
    this.kmRateMilliPerKm = const Value.absent(),
    required DateTime createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       fuelType = Value(fuelType),
       consumptionMilliPer100km = Value(consumptionMilliPer100km),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<UserVehicleRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? fuelType,
    Expression<int>? consumptionMilliPer100km,
    Expression<int>? wearMilliPerKm,
    Expression<int>? kmRateMilliPerKm,
    Expression<DateTime>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (fuelType != null) 'fuel_type': fuelType,
      if (consumptionMilliPer100km != null)
        'consumption_milli_per100km': consumptionMilliPer100km,
      if (wearMilliPerKm != null) 'wear_milli_per_km': wearMilliPerKm,
      if (kmRateMilliPerKm != null) 'km_rate_milli_per_km': kmRateMilliPerKm,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserVehiclesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? fuelType,
    Value<int>? consumptionMilliPer100km,
    Value<int>? wearMilliPerKm,
    Value<int?>? kmRateMilliPerKm,
    Value<DateTime>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return UserVehiclesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      fuelType: fuelType ?? this.fuelType,
      consumptionMilliPer100km:
          consumptionMilliPer100km ?? this.consumptionMilliPer100km,
      wearMilliPerKm: wearMilliPerKm ?? this.wearMilliPerKm,
      kmRateMilliPerKm: kmRateMilliPerKm ?? this.kmRateMilliPerKm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (fuelType.present) {
      map['fuel_type'] = Variable<String>(fuelType.value);
    }
    if (consumptionMilliPer100km.present) {
      map['consumption_milli_per100km'] = Variable<int>(
        consumptionMilliPer100km.value,
      );
    }
    if (wearMilliPerKm.present) {
      map['wear_milli_per_km'] = Variable<int>(wearMilliPerKm.value);
    }
    if (kmRateMilliPerKm.present) {
      map['km_rate_milli_per_km'] = Variable<int>(kmRateMilliPerKm.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserVehiclesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('fuelType: $fuelType, ')
          ..write('consumptionMilliPer100km: $consumptionMilliPer100km, ')
          ..write('wearMilliPerKm: $wearMilliPerKm, ')
          ..write('kmRateMilliPerKm: $kmRateMilliPerKm, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $UserVehicleCostsTable extends UserVehicleCosts
    with TableInfo<$UserVehicleCostsTable, UserVehicleCostsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserVehicleCostsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _userVehicleIdMeta = const VerificationMeta(
    'userVehicleId',
  );
  @override
  late final GeneratedColumn<String> userVehicleId = GeneratedColumn<String>(
    'user_vehicle_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_vehicles (id)',
    ),
  );
  static const VerificationMeta _annualKmMeta = const VerificationMeta(
    'annualKm',
  );
  @override
  late final GeneratedColumn<int> annualKm = GeneratedColumn<int>(
    'annual_km',
    aliasedName,
    false,
    check: () => ComparableExpr(annualKm).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _shareBasisMeta = const VerificationMeta(
    'shareBasis',
  );
  @override
  late final GeneratedColumn<String> shareBasis = GeneratedColumn<String>(
    'share_basis',
    aliasedName,
    false,
    check: () => shareBasis.isIn(const ['running', 'full']),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('running'),
  );
  static const VerificationMeta _insuranceCentsMeta = const VerificationMeta(
    'insuranceCents',
  );
  @override
  late final GeneratedColumn<int> insuranceCents = GeneratedColumn<int>(
    'insurance_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _taxCentsMeta = const VerificationMeta(
    'taxCents',
  );
  @override
  late final GeneratedColumn<int> taxCents = GeneratedColumn<int>(
    'tax_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _maintenanceCentsMeta = const VerificationMeta(
    'maintenanceCents',
  );
  @override
  late final GeneratedColumn<int> maintenanceCents = GeneratedColumn<int>(
    'maintenance_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tyresCentsMeta = const VerificationMeta(
    'tyresCents',
  );
  @override
  late final GeneratedColumn<int> tyresCents = GeneratedColumn<int>(
    'tyres_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repairsCentsMeta = const VerificationMeta(
    'repairsCents',
  );
  @override
  late final GeneratedColumn<int> repairsCents = GeneratedColumn<int>(
    'repairs_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loanCentsMeta = const VerificationMeta(
    'loanCents',
  );
  @override
  late final GeneratedColumn<int> loanCents = GeneratedColumn<int>(
    'loan_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _depreciationCentsMeta = const VerificationMeta(
    'depreciationCents',
  );
  @override
  late final GeneratedColumn<int> depreciationCents = GeneratedColumn<int>(
    'depreciation_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parkingCentsMeta = const VerificationMeta(
    'parkingCents',
  );
  @override
  late final GeneratedColumn<int> parkingCents = GeneratedColumn<int>(
    'parking_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _otherCentsMeta = const VerificationMeta(
    'otherCents',
  );
  @override
  late final GeneratedColumn<int> otherCents = GeneratedColumn<int>(
    'other_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<String> updatedAt = GeneratedColumn<String>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    userVehicleId,
    annualKm,
    shareBasis,
    insuranceCents,
    taxCents,
    maintenanceCents,
    tyresCents,
    repairsCents,
    loanCents,
    depreciationCents,
    parkingCents,
    otherCents,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_vehicle_costs';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserVehicleCostsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('user_vehicle_id')) {
      context.handle(
        _userVehicleIdMeta,
        userVehicleId.isAcceptableOrUnknown(
          data['user_vehicle_id']!,
          _userVehicleIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_userVehicleIdMeta);
    }
    if (data.containsKey('annual_km')) {
      context.handle(
        _annualKmMeta,
        annualKm.isAcceptableOrUnknown(data['annual_km']!, _annualKmMeta),
      );
    } else if (isInserting) {
      context.missing(_annualKmMeta);
    }
    if (data.containsKey('share_basis')) {
      context.handle(
        _shareBasisMeta,
        shareBasis.isAcceptableOrUnknown(data['share_basis']!, _shareBasisMeta),
      );
    }
    if (data.containsKey('insurance_cents')) {
      context.handle(
        _insuranceCentsMeta,
        insuranceCents.isAcceptableOrUnknown(
          data['insurance_cents']!,
          _insuranceCentsMeta,
        ),
      );
    }
    if (data.containsKey('tax_cents')) {
      context.handle(
        _taxCentsMeta,
        taxCents.isAcceptableOrUnknown(data['tax_cents']!, _taxCentsMeta),
      );
    }
    if (data.containsKey('maintenance_cents')) {
      context.handle(
        _maintenanceCentsMeta,
        maintenanceCents.isAcceptableOrUnknown(
          data['maintenance_cents']!,
          _maintenanceCentsMeta,
        ),
      );
    }
    if (data.containsKey('tyres_cents')) {
      context.handle(
        _tyresCentsMeta,
        tyresCents.isAcceptableOrUnknown(data['tyres_cents']!, _tyresCentsMeta),
      );
    }
    if (data.containsKey('repairs_cents')) {
      context.handle(
        _repairsCentsMeta,
        repairsCents.isAcceptableOrUnknown(
          data['repairs_cents']!,
          _repairsCentsMeta,
        ),
      );
    }
    if (data.containsKey('loan_cents')) {
      context.handle(
        _loanCentsMeta,
        loanCents.isAcceptableOrUnknown(data['loan_cents']!, _loanCentsMeta),
      );
    }
    if (data.containsKey('depreciation_cents')) {
      context.handle(
        _depreciationCentsMeta,
        depreciationCents.isAcceptableOrUnknown(
          data['depreciation_cents']!,
          _depreciationCentsMeta,
        ),
      );
    }
    if (data.containsKey('parking_cents')) {
      context.handle(
        _parkingCentsMeta,
        parkingCents.isAcceptableOrUnknown(
          data['parking_cents']!,
          _parkingCentsMeta,
        ),
      );
    }
    if (data.containsKey('other_cents')) {
      context.handle(
        _otherCentsMeta,
        otherCents.isAcceptableOrUnknown(data['other_cents']!, _otherCentsMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {userVehicleId};
  @override
  UserVehicleCostsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserVehicleCostsRow(
      userVehicleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_vehicle_id'],
      )!,
      annualKm: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}annual_km'],
      )!,
      shareBasis: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}share_basis'],
      )!,
      insuranceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}insurance_cents'],
      ),
      taxCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tax_cents'],
      ),
      maintenanceCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}maintenance_cents'],
      ),
      tyresCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tyres_cents'],
      ),
      repairsCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repairs_cents'],
      ),
      loanCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}loan_cents'],
      ),
      depreciationCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}depreciation_cents'],
      ),
      parkingCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parking_cents'],
      ),
      otherCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}other_cents'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $UserVehicleCostsTable createAlias(String alias) {
    return $UserVehicleCostsTable(attachedDatabase, alias);
  }
}

class UserVehicleCostsRow extends DataClass
    implements Insertable<UserVehicleCostsRow> {
  final String userVehicleId;
  final int annualKm;

  /// `running` or `full` (ADR-25 §3).
  final String shareBasis;
  final int? insuranceCents;
  final int? taxCents;
  final int? maintenanceCents;
  final int? tyresCents;
  final int? repairsCents;
  final int? loanCents;
  final int? depreciationCents;
  final int? parkingCents;
  final int? otherCents;
  final String updatedAt;
  const UserVehicleCostsRow({
    required this.userVehicleId,
    required this.annualKm,
    required this.shareBasis,
    this.insuranceCents,
    this.taxCents,
    this.maintenanceCents,
    this.tyresCents,
    this.repairsCents,
    this.loanCents,
    this.depreciationCents,
    this.parkingCents,
    this.otherCents,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['user_vehicle_id'] = Variable<String>(userVehicleId);
    map['annual_km'] = Variable<int>(annualKm);
    map['share_basis'] = Variable<String>(shareBasis);
    if (!nullToAbsent || insuranceCents != null) {
      map['insurance_cents'] = Variable<int>(insuranceCents);
    }
    if (!nullToAbsent || taxCents != null) {
      map['tax_cents'] = Variable<int>(taxCents);
    }
    if (!nullToAbsent || maintenanceCents != null) {
      map['maintenance_cents'] = Variable<int>(maintenanceCents);
    }
    if (!nullToAbsent || tyresCents != null) {
      map['tyres_cents'] = Variable<int>(tyresCents);
    }
    if (!nullToAbsent || repairsCents != null) {
      map['repairs_cents'] = Variable<int>(repairsCents);
    }
    if (!nullToAbsent || loanCents != null) {
      map['loan_cents'] = Variable<int>(loanCents);
    }
    if (!nullToAbsent || depreciationCents != null) {
      map['depreciation_cents'] = Variable<int>(depreciationCents);
    }
    if (!nullToAbsent || parkingCents != null) {
      map['parking_cents'] = Variable<int>(parkingCents);
    }
    if (!nullToAbsent || otherCents != null) {
      map['other_cents'] = Variable<int>(otherCents);
    }
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  UserVehicleCostsCompanion toCompanion(bool nullToAbsent) {
    return UserVehicleCostsCompanion(
      userVehicleId: Value(userVehicleId),
      annualKm: Value(annualKm),
      shareBasis: Value(shareBasis),
      insuranceCents: insuranceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(insuranceCents),
      taxCents: taxCents == null && nullToAbsent
          ? const Value.absent()
          : Value(taxCents),
      maintenanceCents: maintenanceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(maintenanceCents),
      tyresCents: tyresCents == null && nullToAbsent
          ? const Value.absent()
          : Value(tyresCents),
      repairsCents: repairsCents == null && nullToAbsent
          ? const Value.absent()
          : Value(repairsCents),
      loanCents: loanCents == null && nullToAbsent
          ? const Value.absent()
          : Value(loanCents),
      depreciationCents: depreciationCents == null && nullToAbsent
          ? const Value.absent()
          : Value(depreciationCents),
      parkingCents: parkingCents == null && nullToAbsent
          ? const Value.absent()
          : Value(parkingCents),
      otherCents: otherCents == null && nullToAbsent
          ? const Value.absent()
          : Value(otherCents),
      updatedAt: Value(updatedAt),
    );
  }

  factory UserVehicleCostsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserVehicleCostsRow(
      userVehicleId: serializer.fromJson<String>(json['userVehicleId']),
      annualKm: serializer.fromJson<int>(json['annualKm']),
      shareBasis: serializer.fromJson<String>(json['shareBasis']),
      insuranceCents: serializer.fromJson<int?>(json['insuranceCents']),
      taxCents: serializer.fromJson<int?>(json['taxCents']),
      maintenanceCents: serializer.fromJson<int?>(json['maintenanceCents']),
      tyresCents: serializer.fromJson<int?>(json['tyresCents']),
      repairsCents: serializer.fromJson<int?>(json['repairsCents']),
      loanCents: serializer.fromJson<int?>(json['loanCents']),
      depreciationCents: serializer.fromJson<int?>(json['depreciationCents']),
      parkingCents: serializer.fromJson<int?>(json['parkingCents']),
      otherCents: serializer.fromJson<int?>(json['otherCents']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'userVehicleId': serializer.toJson<String>(userVehicleId),
      'annualKm': serializer.toJson<int>(annualKm),
      'shareBasis': serializer.toJson<String>(shareBasis),
      'insuranceCents': serializer.toJson<int?>(insuranceCents),
      'taxCents': serializer.toJson<int?>(taxCents),
      'maintenanceCents': serializer.toJson<int?>(maintenanceCents),
      'tyresCents': serializer.toJson<int?>(tyresCents),
      'repairsCents': serializer.toJson<int?>(repairsCents),
      'loanCents': serializer.toJson<int?>(loanCents),
      'depreciationCents': serializer.toJson<int?>(depreciationCents),
      'parkingCents': serializer.toJson<int?>(parkingCents),
      'otherCents': serializer.toJson<int?>(otherCents),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  UserVehicleCostsRow copyWith({
    String? userVehicleId,
    int? annualKm,
    String? shareBasis,
    Value<int?> insuranceCents = const Value.absent(),
    Value<int?> taxCents = const Value.absent(),
    Value<int?> maintenanceCents = const Value.absent(),
    Value<int?> tyresCents = const Value.absent(),
    Value<int?> repairsCents = const Value.absent(),
    Value<int?> loanCents = const Value.absent(),
    Value<int?> depreciationCents = const Value.absent(),
    Value<int?> parkingCents = const Value.absent(),
    Value<int?> otherCents = const Value.absent(),
    String? updatedAt,
  }) => UserVehicleCostsRow(
    userVehicleId: userVehicleId ?? this.userVehicleId,
    annualKm: annualKm ?? this.annualKm,
    shareBasis: shareBasis ?? this.shareBasis,
    insuranceCents: insuranceCents.present
        ? insuranceCents.value
        : this.insuranceCents,
    taxCents: taxCents.present ? taxCents.value : this.taxCents,
    maintenanceCents: maintenanceCents.present
        ? maintenanceCents.value
        : this.maintenanceCents,
    tyresCents: tyresCents.present ? tyresCents.value : this.tyresCents,
    repairsCents: repairsCents.present ? repairsCents.value : this.repairsCents,
    loanCents: loanCents.present ? loanCents.value : this.loanCents,
    depreciationCents: depreciationCents.present
        ? depreciationCents.value
        : this.depreciationCents,
    parkingCents: parkingCents.present ? parkingCents.value : this.parkingCents,
    otherCents: otherCents.present ? otherCents.value : this.otherCents,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  UserVehicleCostsRow copyWithCompanion(UserVehicleCostsCompanion data) {
    return UserVehicleCostsRow(
      userVehicleId: data.userVehicleId.present
          ? data.userVehicleId.value
          : this.userVehicleId,
      annualKm: data.annualKm.present ? data.annualKm.value : this.annualKm,
      shareBasis: data.shareBasis.present
          ? data.shareBasis.value
          : this.shareBasis,
      insuranceCents: data.insuranceCents.present
          ? data.insuranceCents.value
          : this.insuranceCents,
      taxCents: data.taxCents.present ? data.taxCents.value : this.taxCents,
      maintenanceCents: data.maintenanceCents.present
          ? data.maintenanceCents.value
          : this.maintenanceCents,
      tyresCents: data.tyresCents.present
          ? data.tyresCents.value
          : this.tyresCents,
      repairsCents: data.repairsCents.present
          ? data.repairsCents.value
          : this.repairsCents,
      loanCents: data.loanCents.present ? data.loanCents.value : this.loanCents,
      depreciationCents: data.depreciationCents.present
          ? data.depreciationCents.value
          : this.depreciationCents,
      parkingCents: data.parkingCents.present
          ? data.parkingCents.value
          : this.parkingCents,
      otherCents: data.otherCents.present
          ? data.otherCents.value
          : this.otherCents,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserVehicleCostsRow(')
          ..write('userVehicleId: $userVehicleId, ')
          ..write('annualKm: $annualKm, ')
          ..write('shareBasis: $shareBasis, ')
          ..write('insuranceCents: $insuranceCents, ')
          ..write('taxCents: $taxCents, ')
          ..write('maintenanceCents: $maintenanceCents, ')
          ..write('tyresCents: $tyresCents, ')
          ..write('repairsCents: $repairsCents, ')
          ..write('loanCents: $loanCents, ')
          ..write('depreciationCents: $depreciationCents, ')
          ..write('parkingCents: $parkingCents, ')
          ..write('otherCents: $otherCents, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    userVehicleId,
    annualKm,
    shareBasis,
    insuranceCents,
    taxCents,
    maintenanceCents,
    tyresCents,
    repairsCents,
    loanCents,
    depreciationCents,
    parkingCents,
    otherCents,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserVehicleCostsRow &&
          other.userVehicleId == this.userVehicleId &&
          other.annualKm == this.annualKm &&
          other.shareBasis == this.shareBasis &&
          other.insuranceCents == this.insuranceCents &&
          other.taxCents == this.taxCents &&
          other.maintenanceCents == this.maintenanceCents &&
          other.tyresCents == this.tyresCents &&
          other.repairsCents == this.repairsCents &&
          other.loanCents == this.loanCents &&
          other.depreciationCents == this.depreciationCents &&
          other.parkingCents == this.parkingCents &&
          other.otherCents == this.otherCents &&
          other.updatedAt == this.updatedAt);
}

class UserVehicleCostsCompanion extends UpdateCompanion<UserVehicleCostsRow> {
  final Value<String> userVehicleId;
  final Value<int> annualKm;
  final Value<String> shareBasis;
  final Value<int?> insuranceCents;
  final Value<int?> taxCents;
  final Value<int?> maintenanceCents;
  final Value<int?> tyresCents;
  final Value<int?> repairsCents;
  final Value<int?> loanCents;
  final Value<int?> depreciationCents;
  final Value<int?> parkingCents;
  final Value<int?> otherCents;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const UserVehicleCostsCompanion({
    this.userVehicleId = const Value.absent(),
    this.annualKm = const Value.absent(),
    this.shareBasis = const Value.absent(),
    this.insuranceCents = const Value.absent(),
    this.taxCents = const Value.absent(),
    this.maintenanceCents = const Value.absent(),
    this.tyresCents = const Value.absent(),
    this.repairsCents = const Value.absent(),
    this.loanCents = const Value.absent(),
    this.depreciationCents = const Value.absent(),
    this.parkingCents = const Value.absent(),
    this.otherCents = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UserVehicleCostsCompanion.insert({
    required String userVehicleId,
    required int annualKm,
    this.shareBasis = const Value.absent(),
    this.insuranceCents = const Value.absent(),
    this.taxCents = const Value.absent(),
    this.maintenanceCents = const Value.absent(),
    this.tyresCents = const Value.absent(),
    this.repairsCents = const Value.absent(),
    this.loanCents = const Value.absent(),
    this.depreciationCents = const Value.absent(),
    this.parkingCents = const Value.absent(),
    this.otherCents = const Value.absent(),
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : userVehicleId = Value(userVehicleId),
       annualKm = Value(annualKm),
       updatedAt = Value(updatedAt);
  static Insertable<UserVehicleCostsRow> custom({
    Expression<String>? userVehicleId,
    Expression<int>? annualKm,
    Expression<String>? shareBasis,
    Expression<int>? insuranceCents,
    Expression<int>? taxCents,
    Expression<int>? maintenanceCents,
    Expression<int>? tyresCents,
    Expression<int>? repairsCents,
    Expression<int>? loanCents,
    Expression<int>? depreciationCents,
    Expression<int>? parkingCents,
    Expression<int>? otherCents,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (userVehicleId != null) 'user_vehicle_id': userVehicleId,
      if (annualKm != null) 'annual_km': annualKm,
      if (shareBasis != null) 'share_basis': shareBasis,
      if (insuranceCents != null) 'insurance_cents': insuranceCents,
      if (taxCents != null) 'tax_cents': taxCents,
      if (maintenanceCents != null) 'maintenance_cents': maintenanceCents,
      if (tyresCents != null) 'tyres_cents': tyresCents,
      if (repairsCents != null) 'repairs_cents': repairsCents,
      if (loanCents != null) 'loan_cents': loanCents,
      if (depreciationCents != null) 'depreciation_cents': depreciationCents,
      if (parkingCents != null) 'parking_cents': parkingCents,
      if (otherCents != null) 'other_cents': otherCents,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UserVehicleCostsCompanion copyWith({
    Value<String>? userVehicleId,
    Value<int>? annualKm,
    Value<String>? shareBasis,
    Value<int?>? insuranceCents,
    Value<int?>? taxCents,
    Value<int?>? maintenanceCents,
    Value<int?>? tyresCents,
    Value<int?>? repairsCents,
    Value<int?>? loanCents,
    Value<int?>? depreciationCents,
    Value<int?>? parkingCents,
    Value<int?>? otherCents,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return UserVehicleCostsCompanion(
      userVehicleId: userVehicleId ?? this.userVehicleId,
      annualKm: annualKm ?? this.annualKm,
      shareBasis: shareBasis ?? this.shareBasis,
      insuranceCents: insuranceCents ?? this.insuranceCents,
      taxCents: taxCents ?? this.taxCents,
      maintenanceCents: maintenanceCents ?? this.maintenanceCents,
      tyresCents: tyresCents ?? this.tyresCents,
      repairsCents: repairsCents ?? this.repairsCents,
      loanCents: loanCents ?? this.loanCents,
      depreciationCents: depreciationCents ?? this.depreciationCents,
      parkingCents: parkingCents ?? this.parkingCents,
      otherCents: otherCents ?? this.otherCents,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (userVehicleId.present) {
      map['user_vehicle_id'] = Variable<String>(userVehicleId.value);
    }
    if (annualKm.present) {
      map['annual_km'] = Variable<int>(annualKm.value);
    }
    if (shareBasis.present) {
      map['share_basis'] = Variable<String>(shareBasis.value);
    }
    if (insuranceCents.present) {
      map['insurance_cents'] = Variable<int>(insuranceCents.value);
    }
    if (taxCents.present) {
      map['tax_cents'] = Variable<int>(taxCents.value);
    }
    if (maintenanceCents.present) {
      map['maintenance_cents'] = Variable<int>(maintenanceCents.value);
    }
    if (tyresCents.present) {
      map['tyres_cents'] = Variable<int>(tyresCents.value);
    }
    if (repairsCents.present) {
      map['repairs_cents'] = Variable<int>(repairsCents.value);
    }
    if (loanCents.present) {
      map['loan_cents'] = Variable<int>(loanCents.value);
    }
    if (depreciationCents.present) {
      map['depreciation_cents'] = Variable<int>(depreciationCents.value);
    }
    if (parkingCents.present) {
      map['parking_cents'] = Variable<int>(parkingCents.value);
    }
    if (otherCents.present) {
      map['other_cents'] = Variable<int>(otherCents.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserVehicleCostsCompanion(')
          ..write('userVehicleId: $userVehicleId, ')
          ..write('annualKm: $annualKm, ')
          ..write('shareBasis: $shareBasis, ')
          ..write('insuranceCents: $insuranceCents, ')
          ..write('taxCents: $taxCents, ')
          ..write('maintenanceCents: $maintenanceCents, ')
          ..write('tyresCents: $tyresCents, ')
          ..write('repairsCents: $repairsCents, ')
          ..write('loanCents: $loanCents, ')
          ..write('depreciationCents: $depreciationCents, ')
          ..write('parkingCents: $parkingCents, ')
          ..write('otherCents: $otherCents, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalRecurringExpensesTable extends LocalRecurringExpenses
    with TableInfo<$LocalRecurringExpensesTable, RecurringExpenseRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalRecurringExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    check: () => ComparableExpr(amountCents).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payersJsonMeta = const VerificationMeta(
    'payersJson',
  );
  @override
  late final GeneratedColumn<String> payersJson = GeneratedColumn<String>(
    'payers_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _splitModeMeta = const VerificationMeta(
    'splitMode',
  );
  @override
  late final GeneratedColumn<String> splitMode = GeneratedColumn<String>(
    'split_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _splitWeightsJsonMeta = const VerificationMeta(
    'splitWeightsJson',
  );
  @override
  late final GeneratedColumn<String> splitWeightsJson = GeneratedColumn<String>(
    'split_weights_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intervalCountMeta = const VerificationMeta(
    'intervalCount',
  );
  @override
  late final GeneratedColumn<int> intervalCount = GeneratedColumn<int>(
    'interval_count',
    aliasedName,
    false,
    check: () => ComparableExpr(intervalCount).isBiggerOrEqualValue(1),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastGeneratedMeta = const VerificationMeta(
    'lastGenerated',
  );
  @override
  late final GeneratedColumn<String> lastGenerated = GeneratedColumn<String>(
    'last_generated',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedMeta = const VerificationMeta('paused');
  @override
  late final GeneratedColumn<bool> paused = GeneratedColumn<bool>(
    'paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    groupId,
    title,
    amountCents,
    payersJson,
    splitMode,
    splitWeightsJson,
    category,
    frequency,
    intervalCount,
    startDate,
    endDate,
    lastGenerated,
    paused,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_recurring_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecurringExpenseRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('payers_json')) {
      context.handle(
        _payersJsonMeta,
        payersJson.isAcceptableOrUnknown(data['payers_json']!, _payersJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_payersJsonMeta);
    }
    if (data.containsKey('split_mode')) {
      context.handle(
        _splitModeMeta,
        splitMode.isAcceptableOrUnknown(data['split_mode']!, _splitModeMeta),
      );
    } else if (isInserting) {
      context.missing(_splitModeMeta);
    }
    if (data.containsKey('split_weights_json')) {
      context.handle(
        _splitWeightsJsonMeta,
        splitWeightsJson.isAcceptableOrUnknown(
          data['split_weights_json']!,
          _splitWeightsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_splitWeightsJsonMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('interval_count')) {
      context.handle(
        _intervalCountMeta,
        intervalCount.isAcceptableOrUnknown(
          data['interval_count']!,
          _intervalCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_intervalCountMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('last_generated')) {
      context.handle(
        _lastGeneratedMeta,
        lastGenerated.isAcceptableOrUnknown(
          data['last_generated']!,
          _lastGeneratedMeta,
        ),
      );
    }
    if (data.containsKey('paused')) {
      context.handle(
        _pausedMeta,
        paused.isAcceptableOrUnknown(data['paused']!, _pausedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  RecurringExpenseRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecurringExpenseRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      payersJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payers_json'],
      )!,
      splitMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_mode'],
      )!,
      splitWeightsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}split_weights_json'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      intervalCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}interval_count'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
      lastGenerated: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_generated'],
      ),
      paused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}paused'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalRecurringExpensesTable createAlias(String alias) {
    return $LocalRecurringExpensesTable(attachedDatabase, alias);
  }
}

class RecurringExpenseRow extends DataClass
    implements Insertable<RecurringExpenseRow> {
  final String id;
  final String groupId;
  final String title;

  /// In the group currency.
  final int amountCents;

  /// JSON `{memberId: cents}`.
  final String payersJson;

  /// `equal`, `shares`, `percent` or `exact` (see `splitModeOf`).
  final String splitMode;

  /// JSON `{memberId: weight}` as persisted for expenses (`splitWeightOf`).
  final String splitWeightsJson;
  final String? category;

  /// `daily`, `weekly`, `monthly` or `yearly`.
  final String frequency;
  final int intervalCount;

  /// `YYYY-MM-DD`.
  final String startDate;
  final String? endDate;

  /// The newest date an expense was created for; null while none was.
  final String? lastGenerated;
  final bool paused;
  final DateTime createdAt;
  const RecurringExpenseRow({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amountCents,
    required this.payersJson,
    required this.splitMode,
    required this.splitWeightsJson,
    this.category,
    required this.frequency,
    required this.intervalCount,
    required this.startDate,
    this.endDate,
    this.lastGenerated,
    required this.paused,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['title'] = Variable<String>(title);
    map['amount_cents'] = Variable<int>(amountCents);
    map['payers_json'] = Variable<String>(payersJson);
    map['split_mode'] = Variable<String>(splitMode);
    map['split_weights_json'] = Variable<String>(splitWeightsJson);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['frequency'] = Variable<String>(frequency);
    map['interval_count'] = Variable<int>(intervalCount);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    if (!nullToAbsent || lastGenerated != null) {
      map['last_generated'] = Variable<String>(lastGenerated);
    }
    map['paused'] = Variable<bool>(paused);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalRecurringExpensesCompanion toCompanion(bool nullToAbsent) {
    return LocalRecurringExpensesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      title: Value(title),
      amountCents: Value(amountCents),
      payersJson: Value(payersJson),
      splitMode: Value(splitMode),
      splitWeightsJson: Value(splitWeightsJson),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      frequency: Value(frequency),
      intervalCount: Value(intervalCount),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      lastGenerated: lastGenerated == null && nullToAbsent
          ? const Value.absent()
          : Value(lastGenerated),
      paused: Value(paused),
      createdAt: Value(createdAt),
    );
  }

  factory RecurringExpenseRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecurringExpenseRow(
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      title: serializer.fromJson<String>(json['title']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      payersJson: serializer.fromJson<String>(json['payersJson']),
      splitMode: serializer.fromJson<String>(json['splitMode']),
      splitWeightsJson: serializer.fromJson<String>(json['splitWeightsJson']),
      category: serializer.fromJson<String?>(json['category']),
      frequency: serializer.fromJson<String>(json['frequency']),
      intervalCount: serializer.fromJson<int>(json['intervalCount']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
      lastGenerated: serializer.fromJson<String?>(json['lastGenerated']),
      paused: serializer.fromJson<bool>(json['paused']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'title': serializer.toJson<String>(title),
      'amountCents': serializer.toJson<int>(amountCents),
      'payersJson': serializer.toJson<String>(payersJson),
      'splitMode': serializer.toJson<String>(splitMode),
      'splitWeightsJson': serializer.toJson<String>(splitWeightsJson),
      'category': serializer.toJson<String?>(category),
      'frequency': serializer.toJson<String>(frequency),
      'intervalCount': serializer.toJson<int>(intervalCount),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
      'lastGenerated': serializer.toJson<String?>(lastGenerated),
      'paused': serializer.toJson<bool>(paused),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  RecurringExpenseRow copyWith({
    String? id,
    String? groupId,
    String? title,
    int? amountCents,
    String? payersJson,
    String? splitMode,
    String? splitWeightsJson,
    Value<String?> category = const Value.absent(),
    String? frequency,
    int? intervalCount,
    String? startDate,
    Value<String?> endDate = const Value.absent(),
    Value<String?> lastGenerated = const Value.absent(),
    bool? paused,
    DateTime? createdAt,
  }) => RecurringExpenseRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    title: title ?? this.title,
    amountCents: amountCents ?? this.amountCents,
    payersJson: payersJson ?? this.payersJson,
    splitMode: splitMode ?? this.splitMode,
    splitWeightsJson: splitWeightsJson ?? this.splitWeightsJson,
    category: category.present ? category.value : this.category,
    frequency: frequency ?? this.frequency,
    intervalCount: intervalCount ?? this.intervalCount,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    lastGenerated: lastGenerated.present
        ? lastGenerated.value
        : this.lastGenerated,
    paused: paused ?? this.paused,
    createdAt: createdAt ?? this.createdAt,
  );
  RecurringExpenseRow copyWithCompanion(LocalRecurringExpensesCompanion data) {
    return RecurringExpenseRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      title: data.title.present ? data.title.value : this.title,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      payersJson: data.payersJson.present
          ? data.payersJson.value
          : this.payersJson,
      splitMode: data.splitMode.present ? data.splitMode.value : this.splitMode,
      splitWeightsJson: data.splitWeightsJson.present
          ? data.splitWeightsJson.value
          : this.splitWeightsJson,
      category: data.category.present ? data.category.value : this.category,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      intervalCount: data.intervalCount.present
          ? data.intervalCount.value
          : this.intervalCount,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      lastGenerated: data.lastGenerated.present
          ? data.lastGenerated.value
          : this.lastGenerated,
      paused: data.paused.present ? data.paused.value : this.paused,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecurringExpenseRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('amountCents: $amountCents, ')
          ..write('payersJson: $payersJson, ')
          ..write('splitMode: $splitMode, ')
          ..write('splitWeightsJson: $splitWeightsJson, ')
          ..write('category: $category, ')
          ..write('frequency: $frequency, ')
          ..write('intervalCount: $intervalCount, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('lastGenerated: $lastGenerated, ')
          ..write('paused: $paused, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    groupId,
    title,
    amountCents,
    payersJson,
    splitMode,
    splitWeightsJson,
    category,
    frequency,
    intervalCount,
    startDate,
    endDate,
    lastGenerated,
    paused,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecurringExpenseRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.title == this.title &&
          other.amountCents == this.amountCents &&
          other.payersJson == this.payersJson &&
          other.splitMode == this.splitMode &&
          other.splitWeightsJson == this.splitWeightsJson &&
          other.category == this.category &&
          other.frequency == this.frequency &&
          other.intervalCount == this.intervalCount &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.lastGenerated == this.lastGenerated &&
          other.paused == this.paused &&
          other.createdAt == this.createdAt);
}

class LocalRecurringExpensesCompanion
    extends UpdateCompanion<RecurringExpenseRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> title;
  final Value<int> amountCents;
  final Value<String> payersJson;
  final Value<String> splitMode;
  final Value<String> splitWeightsJson;
  final Value<String?> category;
  final Value<String> frequency;
  final Value<int> intervalCount;
  final Value<String> startDate;
  final Value<String?> endDate;
  final Value<String?> lastGenerated;
  final Value<bool> paused;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalRecurringExpensesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.title = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.payersJson = const Value.absent(),
    this.splitMode = const Value.absent(),
    this.splitWeightsJson = const Value.absent(),
    this.category = const Value.absent(),
    this.frequency = const Value.absent(),
    this.intervalCount = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.lastGenerated = const Value.absent(),
    this.paused = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalRecurringExpensesCompanion.insert({
    required String id,
    required String groupId,
    required String title,
    required int amountCents,
    required String payersJson,
    required String splitMode,
    required String splitWeightsJson,
    this.category = const Value.absent(),
    required String frequency,
    required int intervalCount,
    required String startDate,
    this.endDate = const Value.absent(),
    this.lastGenerated = const Value.absent(),
    this.paused = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       title = Value(title),
       amountCents = Value(amountCents),
       payersJson = Value(payersJson),
       splitMode = Value(splitMode),
       splitWeightsJson = Value(splitWeightsJson),
       frequency = Value(frequency),
       intervalCount = Value(intervalCount),
       startDate = Value(startDate),
       createdAt = Value(createdAt);
  static Insertable<RecurringExpenseRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? title,
    Expression<int>? amountCents,
    Expression<String>? payersJson,
    Expression<String>? splitMode,
    Expression<String>? splitWeightsJson,
    Expression<String>? category,
    Expression<String>? frequency,
    Expression<int>? intervalCount,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<String>? lastGenerated,
    Expression<bool>? paused,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (title != null) 'title': title,
      if (amountCents != null) 'amount_cents': amountCents,
      if (payersJson != null) 'payers_json': payersJson,
      if (splitMode != null) 'split_mode': splitMode,
      if (splitWeightsJson != null) 'split_weights_json': splitWeightsJson,
      if (category != null) 'category': category,
      if (frequency != null) 'frequency': frequency,
      if (intervalCount != null) 'interval_count': intervalCount,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (lastGenerated != null) 'last_generated': lastGenerated,
      if (paused != null) 'paused': paused,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalRecurringExpensesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? title,
    Value<int>? amountCents,
    Value<String>? payersJson,
    Value<String>? splitMode,
    Value<String>? splitWeightsJson,
    Value<String?>? category,
    Value<String>? frequency,
    Value<int>? intervalCount,
    Value<String>? startDate,
    Value<String?>? endDate,
    Value<String?>? lastGenerated,
    Value<bool>? paused,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalRecurringExpensesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amountCents: amountCents ?? this.amountCents,
      payersJson: payersJson ?? this.payersJson,
      splitMode: splitMode ?? this.splitMode,
      splitWeightsJson: splitWeightsJson ?? this.splitWeightsJson,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      intervalCount: intervalCount ?? this.intervalCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      lastGenerated: lastGenerated ?? this.lastGenerated,
      paused: paused ?? this.paused,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (payersJson.present) {
      map['payers_json'] = Variable<String>(payersJson.value);
    }
    if (splitMode.present) {
      map['split_mode'] = Variable<String>(splitMode.value);
    }
    if (splitWeightsJson.present) {
      map['split_weights_json'] = Variable<String>(splitWeightsJson.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (intervalCount.present) {
      map['interval_count'] = Variable<int>(intervalCount.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (lastGenerated.present) {
      map['last_generated'] = Variable<String>(lastGenerated.value);
    }
    if (paused.present) {
      map['paused'] = Variable<bool>(paused.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalRecurringExpensesCompanion(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('title: $title, ')
          ..write('amountCents: $amountCents, ')
          ..write('payersJson: $payersJson, ')
          ..write('splitMode: $splitMode, ')
          ..write('splitWeightsJson: $splitWeightsJson, ')
          ..write('category: $category, ')
          ..write('frequency: $frequency, ')
          ..write('intervalCount: $intervalCount, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('lastGenerated: $lastGenerated, ')
          ..write('paused: $paused, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GroupsTable groups = $GroupsTable(this);
  late final $MembersTable members = $MembersTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $ExpensePayersTable expensePayers = $ExpensePayersTable(this);
  late final $ExpenseSharesTable expenseShares = $ExpenseSharesTable(this);
  late final $SettlementsTable settlements = $SettlementsTable(this);
  late final $LocalMemberBankTable localMemberBank = $LocalMemberBankTable(
    this,
  );
  late final $LocalOutboxTable localOutbox = $LocalOutboxTable(this);
  late final $LocalDriverPromptsTable localDriverPrompts =
      $LocalDriverPromptsTable(this);
  late final $LocalPlacesTable localPlaces = $LocalPlacesTable(this);
  late final $VehiclesTable vehicles = $VehiclesTable(this);
  late final $RideTemplatesTable rideTemplates = $RideTemplatesTable(this);
  late final $RidesTable rides = $RidesTable(this);
  late final $ExpenseRevisionsTable expenseRevisions = $ExpenseRevisionsTable(
    this,
  );
  late final $LocalGroupSyncTable localGroupSync = $LocalGroupSyncTable(this);
  late final $LocalSyncCursorTable localSyncCursor = $LocalSyncCursorTable(
    this,
  );
  late final $LocalSettingsTable localSettings = $LocalSettingsTable(this);
  late final $ProfileTable profile = $ProfileTable(this);
  late final $LocalProfileBankTable localProfileBank = $LocalProfileBankTable(
    this,
  );
  late final $UserVehiclesTable userVehicles = $UserVehiclesTable(this);
  late final $UserVehicleCostsTable userVehicleCosts = $UserVehicleCostsTable(
    this,
  );
  late final $LocalRecurringExpensesTable localRecurringExpenses =
      $LocalRecurringExpensesTable(this);
  late final Index membersGroupId = Index(
    'members_group_id',
    'CREATE INDEX members_group_id ON members (group_id)',
  );
  late final Index expensesGroupId = Index(
    'expenses_group_id',
    'CREATE INDEX expenses_group_id ON expenses (group_id)',
  );
  late final Index expensePayersExpenseId = Index(
    'expense_payers_expense_id',
    'CREATE INDEX expense_payers_expense_id ON expense_payers (expense_id)',
  );
  late final Index expensePayersGroupId = Index(
    'expense_payers_group_id',
    'CREATE INDEX expense_payers_group_id ON expense_payers (group_id)',
  );
  late final Index expensePayersMemberId = Index(
    'expense_payers_member_id',
    'CREATE INDEX expense_payers_member_id ON expense_payers (member_id)',
  );
  late final Index expenseSharesExpenseId = Index(
    'expense_shares_expense_id',
    'CREATE INDEX expense_shares_expense_id ON expense_shares (expense_id)',
  );
  late final Index expenseSharesGroupId = Index(
    'expense_shares_group_id',
    'CREATE INDEX expense_shares_group_id ON expense_shares (group_id)',
  );
  late final Index expenseSharesMemberId = Index(
    'expense_shares_member_id',
    'CREATE INDEX expense_shares_member_id ON expense_shares (member_id)',
  );
  late final Index settlementsGroupId = Index(
    'settlements_group_id',
    'CREATE INDEX settlements_group_id ON settlements (group_id)',
  );
  late final Index vehiclesGroupId = Index(
    'vehicles_group_id',
    'CREATE INDEX vehicles_group_id ON vehicles (group_id)',
  );
  late final Index rideTemplatesGroupId = Index(
    'ride_templates_group_id',
    'CREATE INDEX ride_templates_group_id ON ride_templates (group_id)',
  );
  late final Index ridesGroupDate = Index(
    'rides_group_date',
    'CREATE INDEX rides_group_date ON rides (group_id, date)',
  );
  late final Index expenseRevisionsExpenseRevision = Index(
    'expense_revisions_expense_revision',
    'CREATE UNIQUE INDEX expense_revisions_expense_revision ON expense_revisions (expense_id, revision)',
  );
  late final Index expenseRevisionsGroupId = Index(
    'expense_revisions_group_id',
    'CREATE INDEX expense_revisions_group_id ON expense_revisions (group_id)',
  );
  late final Index localRecurringExpensesGroupId = Index(
    'local_recurring_expenses_group_id',
    'CREATE INDEX local_recurring_expenses_group_id ON local_recurring_expenses (group_id)',
  );
  late final GroupsDao groupsDao = GroupsDao(this as AppDatabase);
  late final MembersDao membersDao = MembersDao(this as AppDatabase);
  late final ExpensesDao expensesDao = ExpensesDao(this as AppDatabase);
  late final SettlementsDao settlementsDao = SettlementsDao(
    this as AppDatabase,
  );
  late final LocalMemberBankDao localMemberBankDao = LocalMemberBankDao(
    this as AppDatabase,
  );
  late final LocalPlacesDao localPlacesDao = LocalPlacesDao(
    this as AppDatabase,
  );
  late final RidesDao ridesDao = RidesDao(this as AppDatabase);
  late final SyncStateDao syncStateDao = SyncStateDao(this as AppDatabase);
  late final ProfileDao profileDao = ProfileDao(this as AppDatabase);
  late final LocalProfileBankDao localProfileBankDao = LocalProfileBankDao(
    this as AppDatabase,
  );
  late final UserVehiclesDao userVehiclesDao = UserVehiclesDao(
    this as AppDatabase,
  );
  late final RecurringDao recurringDao = RecurringDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    groups,
    members,
    expenses,
    expensePayers,
    expenseShares,
    settlements,
    localMemberBank,
    localOutbox,
    localDriverPrompts,
    localPlaces,
    vehicles,
    rideTemplates,
    rides,
    expenseRevisions,
    localGroupSync,
    localSyncCursor,
    localSettings,
    profile,
    localProfileBank,
    userVehicles,
    userVehicleCosts,
    localRecurringExpenses,
    membersGroupId,
    expensesGroupId,
    expensePayersExpenseId,
    expensePayersGroupId,
    expensePayersMemberId,
    expenseSharesExpenseId,
    expenseSharesGroupId,
    expenseSharesMemberId,
    settlementsGroupId,
    vehiclesGroupId,
    rideTemplatesGroupId,
    ridesGroupDate,
    expenseRevisionsExpenseRevision,
    expenseRevisionsGroupId,
    localRecurringExpensesGroupId,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  required String id,
  required String name,
  required String currency,
  required String createdBy,
  required DateTime createdAt,
  required String updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> currency,
  Value<String> createdBy,
  Value<DateTime> createdAt,
  Value<String> updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});

final class $$GroupsTableReferences
    extends BaseReferences<_$AppDatabase, $GroupsTable, GroupRow> {
  $$GroupsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MembersTable, List<MemberRow>> _membersRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.members,
    aliasName: 'groups__id__members__group_id',
  );

  $$MembersTableProcessedTableManager get membersRefs {
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_membersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<ExpenseRow>>
  _expensesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'groups__id__expenses__group_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpensePayersTable, List<ExpensePayerRow>>
  _expensePayersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expensePayers,
    aliasName: 'groups__id__expense_payers__group_id',
  );

  $$ExpensePayersTableProcessedTableManager get expensePayersRefs {
    final manager = $$ExpensePayersTableTableManager(
      $_db,
      $_db.expensePayers,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensePayersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpenseSharesTable, List<ExpenseShareRow>>
  _expenseSharesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseShares,
    aliasName: 'groups__id__expense_shares__group_id',
  );

  $$ExpenseSharesTableProcessedTableManager get expenseSharesRefs {
    final manager = $$ExpenseSharesTableTableManager(
      $_db,
      $_db.expenseShares,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseSharesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SettlementsTable, List<SettlementRow>>
  _settlementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.settlements,
    aliasName: 'groups__id__settlements__group_id',
  );

  $$SettlementsTableProcessedTableManager get settlementsRefs {
    final manager = $$SettlementsTableTableManager(
      $_db,
      $_db.settlements,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_settlementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalOutboxTable, List<LocalOutboxRow>>
  _localOutboxRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localOutbox,
    aliasName: 'groups__id__local_outbox__group_id',
  );

  $$LocalOutboxTableProcessedTableManager get localOutboxRefs {
    final manager = $$LocalOutboxTableTableManager(
      $_db,
      $_db.localOutbox,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_localOutboxRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$VehiclesTable, List<VehicleRow>>
  _vehiclesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.vehicles,
    aliasName: 'groups__id__vehicles__group_id',
  );

  $$VehiclesTableProcessedTableManager get vehiclesRefs {
    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_vehiclesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RideTemplatesTable, List<RideTemplateRow>>
  _rideTemplatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rideTemplates,
    aliasName: 'groups__id__ride_templates__group_id',
  );

  $$RideTemplatesTableProcessedTableManager get rideTemplatesRefs {
    final manager = $$RideTemplatesTableTableManager(
      $_db,
      $_db.rideTemplates,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rideTemplatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RidesTable, List<RideRow>> _ridesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rides,
    aliasName: 'groups__id__rides__group_id',
  );

  $$RidesTableProcessedTableManager get ridesRefs {
    final manager = $$RidesTableTableManager(
      $_db,
      $_db.rides,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ridesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpenseRevisionsTable, List<ExpenseRevisionRow>>
  _expenseRevisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseRevisions,
    aliasName: 'groups__id__expense_revisions__group_id',
  );

  $$ExpenseRevisionsTableProcessedTableManager get expenseRevisionsRefs {
    final manager = $$ExpenseRevisionsTableTableManager(
      $_db,
      $_db.expenseRevisions,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalGroupSyncTable, List<LocalGroupSyncRow>>
  _localGroupSyncRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localGroupSync,
    aliasName: 'groups__id__local_group_sync__group_id',
  );

  $$LocalGroupSyncTableProcessedTableManager get localGroupSyncRefs {
    final manager = $$LocalGroupSyncTableTableManager(
      $_db,
      $_db.localGroupSync,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_localGroupSyncRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalSyncCursorTable, List<LocalSyncCursorRow>>
  _localSyncCursorRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localSyncCursor,
    aliasName: 'groups__id__local_sync_cursor__group_id',
  );

  $$LocalSyncCursorTableProcessedTableManager get localSyncCursorRefs {
    final manager = $$LocalSyncCursorTableTableManager(
      $_db,
      $_db.localSyncCursor,
    ).filter((f) => f.groupId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localSyncCursorRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GroupsTableFilterComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> membersRefs(
    Expression<bool> Function($$MembersTableFilterComposer f) f,
  ) {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expensePayersRefs(
    Expression<bool> Function($$ExpensePayersTableFilterComposer f) f,
  ) {
    final $$ExpensePayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensePayersTableFilterComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseSharesRefs(
    Expression<bool> Function($$ExpenseSharesTableFilterComposer f) f,
  ) {
    final $$ExpenseSharesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseShares,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseSharesTableFilterComposer(
            $db: $db,
            $table: $db.expenseShares,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> settlementsRefs(
    Expression<bool> Function($$SettlementsTableFilterComposer f) f,
  ) {
    final $$SettlementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettlementsTableFilterComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localOutboxRefs(
    Expression<bool> Function($$LocalOutboxTableFilterComposer f) f,
  ) {
    final $$LocalOutboxTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localOutbox,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalOutboxTableFilterComposer(
            $db: $db,
            $table: $db.localOutbox,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> vehiclesRefs(
    Expression<bool> Function($$VehiclesTableFilterComposer f) f,
  ) {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rideTemplatesRefs(
    Expression<bool> Function($$RideTemplatesTableFilterComposer f) f,
  ) {
    final $$RideTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rideTemplates,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RideTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.rideTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ridesRefs(
    Expression<bool> Function($$RidesTableFilterComposer f) f,
  ) {
    final $$RidesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rides,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RidesTableFilterComposer(
            $db: $db,
            $table: $db.rides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseRevisionsRefs(
    Expression<bool> Function($$ExpenseRevisionsTableFilterComposer f) f,
  ) {
    final $$ExpenseRevisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseRevisions,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseRevisionsTableFilterComposer(
            $db: $db,
            $table: $db.expenseRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localGroupSyncRefs(
    Expression<bool> Function($$LocalGroupSyncTableFilterComposer f) f,
  ) {
    final $$LocalGroupSyncTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localGroupSync,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalGroupSyncTableFilterComposer(
            $db: $db,
            $table: $db.localGroupSync,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localSyncCursorRefs(
    Expression<bool> Function($$LocalSyncCursorTableFilterComposer f) f,
  ) {
    final $$LocalSyncCursorTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localSyncCursor,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSyncCursorTableFilterComposer(
            $db: $db,
            $table: $db.localSyncCursor,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableOrderingComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdBy => $composableBuilder(
    column: $table.createdBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GroupsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GroupsTable> {
  $$GroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<String> get createdBy =>
      $composableBuilder(column: $table.createdBy, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> membersRefs<T extends Object>(
    Expression<T> Function($$MembersTableAnnotationComposer a) f,
  ) {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expensePayersRefs<T extends Object>(
    Expression<T> Function($$ExpensePayersTableAnnotationComposer a) f,
  ) {
    final $$ExpensePayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensePayersTableAnnotationComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseSharesRefs<T extends Object>(
    Expression<T> Function($$ExpenseSharesTableAnnotationComposer a) f,
  ) {
    final $$ExpenseSharesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseShares,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseSharesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenseShares,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> settlementsRefs<T extends Object>(
    Expression<T> Function($$SettlementsTableAnnotationComposer a) f,
  ) {
    final $$SettlementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettlementsTableAnnotationComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localOutboxRefs<T extends Object>(
    Expression<T> Function($$LocalOutboxTableAnnotationComposer a) f,
  ) {
    final $$LocalOutboxTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localOutbox,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalOutboxTableAnnotationComposer(
            $db: $db,
            $table: $db.localOutbox,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> vehiclesRefs<T extends Object>(
    Expression<T> Function($$VehiclesTableAnnotationComposer a) f,
  ) {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rideTemplatesRefs<T extends Object>(
    Expression<T> Function($$RideTemplatesTableAnnotationComposer a) f,
  ) {
    final $$RideTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rideTemplates,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RideTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.rideTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ridesRefs<T extends Object>(
    Expression<T> Function($$RidesTableAnnotationComposer a) f,
  ) {
    final $$RidesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rides,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RidesTableAnnotationComposer(
            $db: $db,
            $table: $db.rides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseRevisionsRefs<T extends Object>(
    Expression<T> Function($$ExpenseRevisionsTableAnnotationComposer a) f,
  ) {
    final $$ExpenseRevisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseRevisions,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseRevisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.expenseRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localGroupSyncRefs<T extends Object>(
    Expression<T> Function($$LocalGroupSyncTableAnnotationComposer a) f,
  ) {
    final $$LocalGroupSyncTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localGroupSync,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalGroupSyncTableAnnotationComposer(
            $db: $db,
            $table: $db.localGroupSync,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localSyncCursorRefs<T extends Object>(
    Expression<T> Function($$LocalSyncCursorTableAnnotationComposer a) f,
  ) {
    final $$LocalSyncCursorTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localSyncCursor,
      getReferencedColumn: (t) => t.groupId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalSyncCursorTableAnnotationComposer(
            $db: $db,
            $table: $db.localSyncCursor,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GroupsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GroupsTable,
          GroupRow,
          $$GroupsTableFilterComposer,
          $$GroupsTableOrderingComposer,
          $$GroupsTableAnnotationComposer,
          $$GroupsTableCreateCompanionBuilder,
          $$GroupsTableUpdateCompanionBuilder,
          (GroupRow, $$GroupsTableReferences),
          GroupRow,
          PrefetchHooks Function({
            bool membersRefs,
            bool expensesRefs,
            bool expensePayersRefs,
            bool expenseSharesRefs,
            bool settlementsRefs,
            bool localOutboxRefs,
            bool vehiclesRefs,
            bool rideTemplatesRefs,
            bool ridesRefs,
            bool expenseRevisionsRefs,
            bool localGroupSyncRefs,
            bool localSyncCursorRefs,
          })
        > {
  $$GroupsTableTableManager(_$AppDatabase db, $GroupsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<String> createdBy = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion(
                id: id,
                name: name,
                currency: currency,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String currency,
                required String createdBy,
                required DateTime createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GroupsCompanion.insert(
                id: id,
                name: name,
                currency: currency,
                createdBy: createdBy,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GroupsTable, GroupRow>(table),
                  $$GroupsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                membersRefs = false,
                expensesRefs = false,
                expensePayersRefs = false,
                expenseSharesRefs = false,
                settlementsRefs = false,
                localOutboxRefs = false,
                vehiclesRefs = false,
                rideTemplatesRefs = false,
                ridesRefs = false,
                expenseRevisionsRefs = false,
                localGroupSyncRefs = false,
                localSyncCursorRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (membersRefs) db.members,
                    if (expensesRefs) db.expenses,
                    if (expensePayersRefs) db.expensePayers,
                    if (expenseSharesRefs) db.expenseShares,
                    if (settlementsRefs) db.settlements,
                    if (localOutboxRefs) db.localOutbox,
                    if (vehiclesRefs) db.vehicles,
                    if (rideTemplatesRefs) db.rideTemplates,
                    if (ridesRefs) db.rides,
                    if (expenseRevisionsRefs) db.expenseRevisions,
                    if (localGroupSyncRefs) db.localGroupSync,
                    if (localSyncCursorRefs) db.localSyncCursor,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (membersRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          MemberRow,
                          $MembersTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._membersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).membersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (expensesRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          ExpenseRow,
                          $ExpensesTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._expensesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (expensePayersRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          ExpensePayerRow,
                          $ExpensePayersTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._expensePayersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).expensePayersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (expenseSharesRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          ExpenseShareRow,
                          $ExpenseSharesTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._expenseSharesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseSharesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (settlementsRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          SettlementRow,
                          $SettlementsTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._settlementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).settlementsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (localOutboxRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          LocalOutboxRow,
                          $LocalOutboxTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._localOutboxRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).localOutboxRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (vehiclesRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          VehicleRow,
                          $VehiclesTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._vehiclesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).vehiclesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (rideTemplatesRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          RideTemplateRow,
                          $RideTemplatesTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._rideTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).rideTemplatesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (ridesRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          RideRow,
                          $RidesTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._ridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(db, table, p0).ridesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (expenseRevisionsRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          ExpenseRevisionRow,
                          $ExpenseRevisionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._expenseRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseRevisionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (localGroupSyncRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          LocalGroupSyncRow,
                          $LocalGroupSyncTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._localGroupSyncRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).localGroupSyncRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                      if (localSyncCursorRefs)
                        await $_getPrefetchedDataByColumns<
                          GroupRow,
                          $GroupsTable,
                          LocalSyncCursorRow,
                          $LocalSyncCursorTable
                        >(
                          currentTable: table,
                          referencedTable: $$GroupsTableReferences
                              ._localSyncCursorRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GroupsTableReferences(
                                db,
                                table,
                                p0,
                              ).localSyncCursorRefs,
                          currentColumn: 'id',
                          referencedColumn: 'group_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GroupsTable,
      GroupRow,
      $$GroupsTableFilterComposer,
      $$GroupsTableOrderingComposer,
      $$GroupsTableAnnotationComposer,
      $$GroupsTableCreateCompanionBuilder,
      $$GroupsTableUpdateCompanionBuilder,
      (GroupRow, $$GroupsTableReferences),
      GroupRow,
      PrefetchHooks Function({
        bool membersRefs,
        bool expensesRefs,
        bool expensePayersRefs,
        bool expenseSharesRefs,
        bool settlementsRefs,
        bool localOutboxRefs,
        bool vehiclesRefs,
        bool rideTemplatesRefs,
        bool ridesRefs,
        bool expenseRevisionsRefs,
        bool localGroupSyncRefs,
        bool localSyncCursorRefs,
      })
    >;
typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  required String id,
  required String groupId,
  required DateTime createdAt,
  required String updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  required int position,
  Value<String?> paypalMe,
  Value<String?> userId,
  Value<String?> ibanHint,
  Value<bool> canDrive,
  Value<int> rowid,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<DateTime> createdAt,
  Value<String> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<int> position,
  Value<String?> paypalMe,
  Value<String?> userId,
  Value<String?> ibanHint,
  Value<bool> canDrive,
  Value<int> rowid,
});

final class $$MembersTableReferences
    extends BaseReferences<_$AppDatabase, $MembersTable, MemberRow> {
  $$MembersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('members__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpensePayersTable, List<ExpensePayerRow>>
  _expensePayersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expensePayers,
    aliasName: 'members__id__expense_payers__member_id',
  );

  $$ExpensePayersTableProcessedTableManager get expensePayersRefs {
    final manager = $$ExpensePayersTableTableManager(
      $_db,
      $_db.expensePayers,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensePayersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpenseSharesTable, List<ExpenseShareRow>>
  _expenseSharesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseShares,
    aliasName: 'members__id__expense_shares__member_id',
  );

  $$ExpenseSharesTableProcessedTableManager get expenseSharesRefs {
    final manager = $$ExpenseSharesTableTableManager(
      $_db,
      $_db.expenseShares,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseSharesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SettlementsTable, List<SettlementRow>>
  _sentSettlementsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.settlements,
    aliasName: 'members__id__settlements__from_member',
  );

  $$SettlementsTableProcessedTableManager get sentSettlements {
    final manager = $$SettlementsTableTableManager(
      $_db,
      $_db.settlements,
    ).filter((f) => f.fromMember.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_sentSettlementsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SettlementsTable, List<SettlementRow>>
  _receivedSettlementsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.settlements,
    aliasName: 'members__id__settlements__to_member',
  );

  $$SettlementsTableProcessedTableManager get receivedSettlements {
    final manager = $$SettlementsTableTableManager(
      $_db,
      $_db.settlements,
    ).filter((f) => f.toMember.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _receivedSettlementsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LocalMemberBankTable, List<LocalMemberBankRow>>
  _localMemberBankRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localMemberBank,
    aliasName: 'members__id__local_member_bank__member_id',
  );

  $$LocalMemberBankTableProcessedTableManager get localMemberBankRefs {
    final manager = $$LocalMemberBankTableTableManager(
      $_db,
      $_db.localMemberBank,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localMemberBankRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $LocalDriverPromptsTable,
    List<LocalDriverPromptRow>
  >
  _localDriverPromptsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.localDriverPrompts,
        aliasName: 'members__id__local_driver_prompts__member_id',
      );

  $$LocalDriverPromptsTableProcessedTableManager get localDriverPromptsRefs {
    final manager = $$LocalDriverPromptsTableTableManager(
      $_db,
      $_db.localDriverPrompts,
    ).filter((f) => f.memberId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localDriverPromptsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RideTemplatesTable, List<RideTemplateRow>>
  _rideTemplatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rideTemplates,
    aliasName: 'members__id__ride_templates__default_driver_id',
  );

  $$RideTemplatesTableProcessedTableManager get rideTemplatesRefs {
    final manager = $$RideTemplatesTableTableManager($_db, $_db.rideTemplates)
        .filter(
          (f) => f.defaultDriverId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_rideTemplatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RidesTable, List<RideRow>> _ridesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rides,
    aliasName: 'members__id__rides__driver_id',
  );

  $$RidesTableProcessedTableManager get ridesRefs {
    final manager = $$RidesTableTableManager(
      $_db,
      $_db.rides,
    ).filter((f) => f.driverId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ridesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MembersTableFilterComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paypalMe => $composableBuilder(
    column: $table.paypalMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ibanHint => $composableBuilder(
    column: $table.ibanHint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get canDrive => $composableBuilder(
    column: $table.canDrive,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensePayersRefs(
    Expression<bool> Function($$ExpensePayersTableFilterComposer f) f,
  ) {
    final $$ExpensePayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensePayersTableFilterComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseSharesRefs(
    Expression<bool> Function($$ExpenseSharesTableFilterComposer f) f,
  ) {
    final $$ExpenseSharesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseShares,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseSharesTableFilterComposer(
            $db: $db,
            $table: $db.expenseShares,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sentSettlements(
    Expression<bool> Function($$SettlementsTableFilterComposer f) f,
  ) {
    final $$SettlementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.fromMember,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettlementsTableFilterComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> receivedSettlements(
    Expression<bool> Function($$SettlementsTableFilterComposer f) f,
  ) {
    final $$SettlementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.toMember,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettlementsTableFilterComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localMemberBankRefs(
    Expression<bool> Function($$LocalMemberBankTableFilterComposer f) f,
  ) {
    final $$LocalMemberBankTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localMemberBank,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalMemberBankTableFilterComposer(
            $db: $db,
            $table: $db.localMemberBank,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> localDriverPromptsRefs(
    Expression<bool> Function($$LocalDriverPromptsTableFilterComposer f) f,
  ) {
    final $$LocalDriverPromptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localDriverPrompts,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalDriverPromptsTableFilterComposer(
            $db: $db,
            $table: $db.localDriverPrompts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rideTemplatesRefs(
    Expression<bool> Function($$RideTemplatesTableFilterComposer f) f,
  ) {
    final $$RideTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rideTemplates,
      getReferencedColumn: (t) => t.defaultDriverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RideTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.rideTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ridesRefs(
    Expression<bool> Function($$RidesTableFilterComposer f) f,
  ) {
    final $$RidesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rides,
      getReferencedColumn: (t) => t.driverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RidesTableFilterComposer(
            $db: $db,
            $table: $db.rides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableOrderingComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paypalMe => $composableBuilder(
    column: $table.paypalMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ibanHint => $composableBuilder(
    column: $table.ibanHint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get canDrive => $composableBuilder(
    column: $table.canDrive,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembersTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembersTable> {
  $$MembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get paypalMe =>
      $composableBuilder(column: $table.paypalMe, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get ibanHint =>
      $composableBuilder(column: $table.ibanHint, builder: (column) => column);

  GeneratedColumn<bool> get canDrive =>
      $composableBuilder(column: $table.canDrive, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensePayersRefs<T extends Object>(
    Expression<T> Function($$ExpensePayersTableAnnotationComposer a) f,
  ) {
    final $$ExpensePayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensePayersTableAnnotationComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseSharesRefs<T extends Object>(
    Expression<T> Function($$ExpenseSharesTableAnnotationComposer a) f,
  ) {
    final $$ExpenseSharesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseShares,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseSharesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenseShares,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> sentSettlements<T extends Object>(
    Expression<T> Function($$SettlementsTableAnnotationComposer a) f,
  ) {
    final $$SettlementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.fromMember,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettlementsTableAnnotationComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> receivedSettlements<T extends Object>(
    Expression<T> Function($$SettlementsTableAnnotationComposer a) f,
  ) {
    final $$SettlementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.settlements,
      getReferencedColumn: (t) => t.toMember,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SettlementsTableAnnotationComposer(
            $db: $db,
            $table: $db.settlements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localMemberBankRefs<T extends Object>(
    Expression<T> Function($$LocalMemberBankTableAnnotationComposer a) f,
  ) {
    final $$LocalMemberBankTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localMemberBank,
      getReferencedColumn: (t) => t.memberId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalMemberBankTableAnnotationComposer(
            $db: $db,
            $table: $db.localMemberBank,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> localDriverPromptsRefs<T extends Object>(
    Expression<T> Function($$LocalDriverPromptsTableAnnotationComposer a) f,
  ) {
    final $$LocalDriverPromptsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.localDriverPrompts,
          getReferencedColumn: (t) => t.memberId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$LocalDriverPromptsTableAnnotationComposer(
                $db: $db,
                $table: $db.localDriverPrompts,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> rideTemplatesRefs<T extends Object>(
    Expression<T> Function($$RideTemplatesTableAnnotationComposer a) f,
  ) {
    final $$RideTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rideTemplates,
      getReferencedColumn: (t) => t.defaultDriverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RideTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.rideTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ridesRefs<T extends Object>(
    Expression<T> Function($$RidesTableAnnotationComposer a) f,
  ) {
    final $$RidesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rides,
      getReferencedColumn: (t) => t.driverId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RidesTableAnnotationComposer(
            $db: $db,
            $table: $db.rides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MembersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembersTable,
          MemberRow,
          $$MembersTableFilterComposer,
          $$MembersTableOrderingComposer,
          $$MembersTableAnnotationComposer,
          $$MembersTableCreateCompanionBuilder,
          $$MembersTableUpdateCompanionBuilder,
          (MemberRow, $$MembersTableReferences),
          MemberRow,
          PrefetchHooks Function({
            bool groupId,
            bool expensePayersRefs,
            bool expenseSharesRefs,
            bool sentSettlements,
            bool receivedSettlements,
            bool localMemberBankRefs,
            bool localDriverPromptsRefs,
            bool rideTemplatesRefs,
            bool ridesRefs,
          })
        > {
  $$MembersTableTableManager(_$AppDatabase db, $MembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> paypalMe = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> ibanHint = const Value.absent(),
                Value<bool> canDrive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                position: position,
                paypalMe: paypalMe,
                userId: userId,
                ibanHint: ibanHint,
                canDrive: canDrive,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required DateTime createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required int position,
                Value<String?> paypalMe = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> ibanHint = const Value.absent(),
                Value<bool> canDrive = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembersCompanion.insert(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                position: position,
                paypalMe: paypalMe,
                userId: userId,
                ibanHint: ibanHint,
                canDrive: canDrive,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MembersTable, MemberRow>(table),
                  $$MembersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                expensePayersRefs = false,
                expenseSharesRefs = false,
                sentSettlements = false,
                receivedSettlements = false,
                localMemberBankRefs = false,
                localDriverPromptsRefs = false,
                rideTemplatesRefs = false,
                ridesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensePayersRefs) db.expensePayers,
                    if (expenseSharesRefs) db.expenseShares,
                    if (sentSettlements) db.settlements,
                    if (receivedSettlements) db.settlements,
                    if (localMemberBankRefs) db.localMemberBank,
                    if (localDriverPromptsRefs) db.localDriverPrompts,
                    if (rideTemplatesRefs) db.rideTemplates,
                    if (ridesRefs) db.rides,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$MembersTableReferences
                                ._groupIdTable(db),
                            referencedColumn: $$MembersTableReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensePayersRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          $MembersTable,
                          ExpensePayerRow,
                          $ExpensePayersTable
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._expensePayersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).expensePayersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'member_id',
                          typedResults: items,
                        ),
                      if (expenseSharesRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          $MembersTable,
                          ExpenseShareRow,
                          $ExpenseSharesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._expenseSharesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseSharesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'member_id',
                          typedResults: items,
                        ),
                      if (sentSettlements)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          $MembersTable,
                          SettlementRow,
                          $SettlementsTable
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._sentSettlementsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).sentSettlements,
                          currentColumn: 'id',
                          referencedColumn: 'from_member',
                          typedResults: items,
                        ),
                      if (receivedSettlements)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          $MembersTable,
                          SettlementRow,
                          $SettlementsTable
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._receivedSettlementsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).receivedSettlements,
                          currentColumn: 'id',
                          referencedColumn: 'to_member',
                          typedResults: items,
                        ),
                      if (localMemberBankRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          $MembersTable,
                          LocalMemberBankRow,
                          $LocalMemberBankTable
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._localMemberBankRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).localMemberBankRefs,
                          currentColumn: 'id',
                          referencedColumn: 'member_id',
                          typedResults: items,
                        ),
                      if (localDriverPromptsRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          $MembersTable,
                          LocalDriverPromptRow,
                          $LocalDriverPromptsTable
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._localDriverPromptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).localDriverPromptsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'member_id',
                          typedResults: items,
                        ),
                      if (rideTemplatesRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          $MembersTable,
                          RideTemplateRow,
                          $RideTemplatesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._rideTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(
                                db,
                                table,
                                p0,
                              ).rideTemplatesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'default_driver_id',
                          typedResults: items,
                        ),
                      if (ridesRefs)
                        await $_getPrefetchedDataByColumns<
                          MemberRow,
                          $MembersTable,
                          RideRow,
                          $RidesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MembersTableReferences
                              ._ridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MembersTableReferences(db, table, p0).ridesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'driver_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MembersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembersTable,
      MemberRow,
      $$MembersTableFilterComposer,
      $$MembersTableOrderingComposer,
      $$MembersTableAnnotationComposer,
      $$MembersTableCreateCompanionBuilder,
      $$MembersTableUpdateCompanionBuilder,
      (MemberRow, $$MembersTableReferences),
      MemberRow,
      PrefetchHooks Function({
        bool groupId,
        bool expensePayersRefs,
        bool expenseSharesRefs,
        bool sentSettlements,
        bool receivedSettlements,
        bool localMemberBankRefs,
        bool localDriverPromptsRefs,
        bool rideTemplatesRefs,
        bool ridesRefs,
      })
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String groupId,
  required DateTime createdAt,
  required String updatedAt,
  Value<DateTime?> deletedAt,
  required String title,
  required int amountCents,
  required String currency,
  required int fxRatePpm,
  required int groupAmountCents,
  required DateTime date,
  Value<String?> category,
  required String type,
  required String splitMode,
  Value<String?> tripMeta,
  Value<int> rowid,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<DateTime> createdAt,
  Value<String> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> title,
  Value<int> amountCents,
  Value<String> currency,
  Value<int> fxRatePpm,
  Value<int> groupAmountCents,
  Value<DateTime> date,
  Value<String?> category,
  Value<String> type,
  Value<String> splitMode,
  Value<String?> tripMeta,
  Value<int> rowid,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, ExpenseRow> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('expenses__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpensePayersTable, List<ExpensePayerRow>>
  _expensePayersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expensePayers,
    aliasName: 'expenses__id__expense_payers__expense_id',
  );

  $$ExpensePayersTableProcessedTableManager get expensePayersRefs {
    final manager = $$ExpensePayersTableTableManager(
      $_db,
      $_db.expensePayers,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensePayersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpenseSharesTable, List<ExpenseShareRow>>
  _expenseSharesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseShares,
    aliasName: 'expenses__id__expense_shares__expense_id',
  );

  $$ExpenseSharesTableProcessedTableManager get expenseSharesRefs {
    final manager = $$ExpenseSharesTableTableManager(
      $_db,
      $_db.expenseShares,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_expenseSharesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RidesTable, List<RideRow>> _ridesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rides,
    aliasName: 'expenses__id__rides__settled_expense_id',
  );

  $$RidesTableProcessedTableManager get ridesRefs {
    final manager = $$RidesTableTableManager($_db, $_db.rides).filter(
      (f) => f.settledExpenseId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_ridesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExpenseRevisionsTable, List<ExpenseRevisionRow>>
  _expenseRevisionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.expenseRevisions,
    aliasName: 'expenses__id__expense_revisions__expense_id',
  );

  $$ExpenseRevisionsTableProcessedTableManager get expenseRevisionsRefs {
    final manager = $$ExpenseRevisionsTableTableManager(
      $_db,
      $_db.expenseRevisions,
    ).filter((f) => f.expenseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _expenseRevisionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fxRatePpm => $composableBuilder(
    column: $table.fxRatePpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get groupAmountCents => $composableBuilder(
    column: $table.groupAmountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitMode => $composableBuilder(
    column: $table.splitMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tripMeta => $composableBuilder(
    column: $table.tripMeta,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensePayersRefs(
    Expression<bool> Function($$ExpensePayersTableFilterComposer f) f,
  ) {
    final $$ExpensePayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensePayersTableFilterComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseSharesRefs(
    Expression<bool> Function($$ExpenseSharesTableFilterComposer f) f,
  ) {
    final $$ExpenseSharesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseShares,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseSharesTableFilterComposer(
            $db: $db,
            $table: $db.expenseShares,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ridesRefs(
    Expression<bool> Function($$RidesTableFilterComposer f) f,
  ) {
    final $$RidesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rides,
      getReferencedColumn: (t) => t.settledExpenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RidesTableFilterComposer(
            $db: $db,
            $table: $db.rides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> expenseRevisionsRefs(
    Expression<bool> Function($$ExpenseRevisionsTableFilterComposer f) f,
  ) {
    final $$ExpenseRevisionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseRevisions,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseRevisionsTableFilterComposer(
            $db: $db,
            $table: $db.expenseRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fxRatePpm => $composableBuilder(
    column: $table.fxRatePpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get groupAmountCents => $composableBuilder(
    column: $table.groupAmountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitMode => $composableBuilder(
    column: $table.splitMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tripMeta => $composableBuilder(
    column: $table.tripMeta,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<int> get fxRatePpm =>
      $composableBuilder(column: $table.fxRatePpm, builder: (column) => column);

  GeneratedColumn<int> get groupAmountCents => $composableBuilder(
    column: $table.groupAmountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get splitMode =>
      $composableBuilder(column: $table.splitMode, builder: (column) => column);

  GeneratedColumn<String> get tripMeta =>
      $composableBuilder(column: $table.tripMeta, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensePayersRefs<T extends Object>(
    Expression<T> Function($$ExpensePayersTableAnnotationComposer a) f,
  ) {
    final $$ExpensePayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expensePayers,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensePayersTableAnnotationComposer(
            $db: $db,
            $table: $db.expensePayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseSharesRefs<T extends Object>(
    Expression<T> Function($$ExpenseSharesTableAnnotationComposer a) f,
  ) {
    final $$ExpenseSharesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseShares,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseSharesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenseShares,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ridesRefs<T extends Object>(
    Expression<T> Function($$RidesTableAnnotationComposer a) f,
  ) {
    final $$RidesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rides,
      getReferencedColumn: (t) => t.settledExpenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RidesTableAnnotationComposer(
            $db: $db,
            $table: $db.rides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> expenseRevisionsRefs<T extends Object>(
    Expression<T> Function($$ExpenseRevisionsTableAnnotationComposer a) f,
  ) {
    final $$ExpenseRevisionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenseRevisions,
      getReferencedColumn: (t) => t.expenseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpenseRevisionsTableAnnotationComposer(
            $db: $db,
            $table: $db.expenseRevisions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          ExpenseRow,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (ExpenseRow, $$ExpensesTableReferences),
          ExpenseRow,
          PrefetchHooks Function({
            bool groupId,
            bool expensePayersRefs,
            bool expenseSharesRefs,
            bool ridesRefs,
            bool expenseRevisionsRefs,
          })
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<int> fxRatePpm = const Value.absent(),
                Value<int> groupAmountCents = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> splitMode = const Value.absent(),
                Value<String?> tripMeta = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                amountCents: amountCents,
                currency: currency,
                fxRatePpm: fxRatePpm,
                groupAmountCents: groupAmountCents,
                date: date,
                category: category,
                type: type,
                splitMode: splitMode,
                tripMeta: tripMeta,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required DateTime createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String title,
                required int amountCents,
                required String currency,
                required int fxRatePpm,
                required int groupAmountCents,
                required DateTime date,
                Value<String?> category = const Value.absent(),
                required String type,
                required String splitMode,
                Value<String?> tripMeta = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                title: title,
                amountCents: amountCents,
                currency: currency,
                fxRatePpm: fxRatePpm,
                groupAmountCents: groupAmountCents,
                date: date,
                category: category,
                type: type,
                splitMode: splitMode,
                tripMeta: tripMeta,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensesTable, ExpenseRow>(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                expensePayersRefs = false,
                expenseSharesRefs = false,
                ridesRefs = false,
                expenseRevisionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensePayersRefs) db.expensePayers,
                    if (expenseSharesRefs) db.expenseShares,
                    if (ridesRefs) db.rides,
                    if (expenseRevisionsRefs) db.expenseRevisions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$ExpensesTableReferences
                                ._groupIdTable(db),
                            referencedColumn: $$ExpensesTableReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (expensePayersRefs)
                        await $_getPrefetchedDataByColumns<
                          ExpenseRow,
                          $ExpensesTable,
                          ExpensePayerRow,
                          $ExpensePayersTable
                        >(
                          currentTable: table,
                          referencedTable: $$ExpensesTableReferences
                              ._expensePayersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExpensesTableReferences(
                                db,
                                table,
                                p0,
                              ).expensePayersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'expense_id',
                          typedResults: items,
                        ),
                      if (expenseSharesRefs)
                        await $_getPrefetchedDataByColumns<
                          ExpenseRow,
                          $ExpensesTable,
                          ExpenseShareRow,
                          $ExpenseSharesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ExpensesTableReferences
                              ._expenseSharesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExpensesTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseSharesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'expense_id',
                          typedResults: items,
                        ),
                      if (ridesRefs)
                        await $_getPrefetchedDataByColumns<
                          ExpenseRow,
                          $ExpensesTable,
                          RideRow,
                          $RidesTable
                        >(
                          currentTable: table,
                          referencedTable: $$ExpensesTableReferences
                              ._ridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExpensesTableReferences(
                                db,
                                table,
                                p0,
                              ).ridesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'settled_expense_id',
                          typedResults: items,
                        ),
                      if (expenseRevisionsRefs)
                        await $_getPrefetchedDataByColumns<
                          ExpenseRow,
                          $ExpensesTable,
                          ExpenseRevisionRow,
                          $ExpenseRevisionsTable
                        >(
                          currentTable: table,
                          referencedTable: $$ExpensesTableReferences
                              ._expenseRevisionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExpensesTableReferences(
                                db,
                                table,
                                p0,
                              ).expenseRevisionsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'expense_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      ExpenseRow,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (ExpenseRow, $$ExpensesTableReferences),
      ExpenseRow,
      PrefetchHooks Function({
        bool groupId,
        bool expensePayersRefs,
        bool expenseSharesRefs,
        bool ridesRefs,
        bool expenseRevisionsRefs,
      })
    >;
typedef $$ExpensePayersTableCreateCompanionBuilder =
    ExpensePayersCompanion Function({
      required String groupId,
      required String expenseId,
      required String memberId,
      required int paidCents,
      Value<int> rowid,
    });
typedef $$ExpensePayersTableUpdateCompanionBuilder =
    ExpensePayersCompanion Function({
      Value<String> groupId,
      Value<String> expenseId,
      Value<String> memberId,
      Value<int> paidCents,
      Value<int> rowid,
    });

final class $$ExpensePayersTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExpensePayersTable, ExpensePayerRow> {
  $$ExpensePayersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('expense_payers__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExpensesTable _expenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias('expense_payers__expense_id__expenses__id');

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('expense_payers__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpensePayersTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensePayersTable> {
  $$ExpensePayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get paidCents => $composableBuilder(
    column: $table.paidCents,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensePayersTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensePayersTable> {
  $$ExpensePayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get paidCents => $composableBuilder(
    column: $table.paidCents,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensePayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensePayersTable> {
  $$ExpensePayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get paidCents =>
      $composableBuilder(column: $table.paidCents, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensePayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensePayersTable,
          ExpensePayerRow,
          $$ExpensePayersTableFilterComposer,
          $$ExpensePayersTableOrderingComposer,
          $$ExpensePayersTableAnnotationComposer,
          $$ExpensePayersTableCreateCompanionBuilder,
          $$ExpensePayersTableUpdateCompanionBuilder,
          (ExpensePayerRow, $$ExpensePayersTableReferences),
          ExpensePayerRow,
          PrefetchHooks Function({bool groupId, bool expenseId, bool memberId})
        > {
  $$ExpensePayersTableTableManager(_$AppDatabase db, $ExpensePayersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensePayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensePayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensePayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> paidCents = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensePayersCompanion(
                groupId: groupId,
                expenseId: expenseId,
                memberId: memberId,
                paidCents: paidCents,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String expenseId,
                required String memberId,
                required int paidCents,
                Value<int> rowid = const Value.absent(),
              }) => ExpensePayersCompanion.insert(
                groupId: groupId,
                expenseId: expenseId,
                memberId: memberId,
                paidCents: paidCents,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensePayersTable, ExpensePayerRow>(table),
                  $$ExpensePayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, expenseId = false, memberId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$ExpensePayersTableReferences
                                ._groupIdTable(db),
                            referencedColumn: $$ExpensePayersTableReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (expenseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.expenseId,
                            referencedTable: $$ExpensePayersTableReferences
                                ._expenseIdTable(db),
                            referencedColumn: $$ExpensePayersTableReferences
                                ._expenseIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (memberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.memberId,
                            referencedTable: $$ExpensePayersTableReferences
                                ._memberIdTable(db),
                            referencedColumn: $$ExpensePayersTableReferences
                                ._memberIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ExpensePayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensePayersTable,
      ExpensePayerRow,
      $$ExpensePayersTableFilterComposer,
      $$ExpensePayersTableOrderingComposer,
      $$ExpensePayersTableAnnotationComposer,
      $$ExpensePayersTableCreateCompanionBuilder,
      $$ExpensePayersTableUpdateCompanionBuilder,
      (ExpensePayerRow, $$ExpensePayersTableReferences),
      ExpensePayerRow,
      PrefetchHooks Function({bool groupId, bool expenseId, bool memberId})
    >;
typedef $$ExpenseSharesTableCreateCompanionBuilder =
    ExpenseSharesCompanion Function({
      required String groupId,
      required String expenseId,
      required String memberId,
      required int shareCents,
      required int weight,
      Value<int> rowid,
    });
typedef $$ExpenseSharesTableUpdateCompanionBuilder =
    ExpenseSharesCompanion Function({
      Value<String> groupId,
      Value<String> expenseId,
      Value<String> memberId,
      Value<int> shareCents,
      Value<int> weight,
      Value<int> rowid,
    });

final class $$ExpenseSharesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ExpenseSharesTable, ExpenseShareRow> {
  $$ExpenseSharesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('expense_shares__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExpensesTable _expenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias('expense_shares__expense_id__expenses__id');

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('expense_shares__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpenseSharesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseSharesTable> {
  $$ExpenseSharesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get shareCents => $composableBuilder(
    column: $table.shareCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseSharesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseSharesTable> {
  $$ExpenseSharesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get shareCents => $composableBuilder(
    column: $table.shareCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weight => $composableBuilder(
    column: $table.weight,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseSharesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseSharesTable> {
  $$ExpenseSharesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get shareCents => $composableBuilder(
    column: $table.shareCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get weight =>
      $composableBuilder(column: $table.weight, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseSharesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseSharesTable,
          ExpenseShareRow,
          $$ExpenseSharesTableFilterComposer,
          $$ExpenseSharesTableOrderingComposer,
          $$ExpenseSharesTableAnnotationComposer,
          $$ExpenseSharesTableCreateCompanionBuilder,
          $$ExpenseSharesTableUpdateCompanionBuilder,
          (ExpenseShareRow, $$ExpenseSharesTableReferences),
          ExpenseShareRow,
          PrefetchHooks Function({bool groupId, bool expenseId, bool memberId})
        > {
  $$ExpenseSharesTableTableManager(_$AppDatabase db, $ExpenseSharesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseSharesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseSharesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseSharesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> shareCents = const Value.absent(),
                Value<int> weight = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseSharesCompanion(
                groupId: groupId,
                expenseId: expenseId,
                memberId: memberId,
                shareCents: shareCents,
                weight: weight,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String expenseId,
                required String memberId,
                required int shareCents,
                required int weight,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseSharesCompanion.insert(
                groupId: groupId,
                expenseId: expenseId,
                memberId: memberId,
                shareCents: shareCents,
                weight: weight,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpenseSharesTable, ExpenseShareRow>(table),
                  $$ExpenseSharesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, expenseId = false, memberId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$ExpenseSharesTableReferences
                                ._groupIdTable(db),
                            referencedColumn: $$ExpenseSharesTableReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (expenseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.expenseId,
                            referencedTable: $$ExpenseSharesTableReferences
                                ._expenseIdTable(db),
                            referencedColumn: $$ExpenseSharesTableReferences
                                ._expenseIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (memberId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.memberId,
                            referencedTable: $$ExpenseSharesTableReferences
                                ._memberIdTable(db),
                            referencedColumn: $$ExpenseSharesTableReferences
                                ._memberIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ExpenseSharesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseSharesTable,
      ExpenseShareRow,
      $$ExpenseSharesTableFilterComposer,
      $$ExpenseSharesTableOrderingComposer,
      $$ExpenseSharesTableAnnotationComposer,
      $$ExpenseSharesTableCreateCompanionBuilder,
      $$ExpenseSharesTableUpdateCompanionBuilder,
      (ExpenseShareRow, $$ExpenseSharesTableReferences),
      ExpenseShareRow,
      PrefetchHooks Function({bool groupId, bool expenseId, bool memberId})
    >;
typedef $$SettlementsTableCreateCompanionBuilder =
    SettlementsCompanion Function({
      required String id,
      required String groupId,
      required DateTime createdAt,
      required String updatedAt,
      Value<DateTime?> deletedAt,
      required String fromMember,
      required String toMember,
      required int amountCents,
      required String currency,
      required DateTime date,
      required String method,
      Value<int> rowid,
    });
typedef $$SettlementsTableUpdateCompanionBuilder =
    SettlementsCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<DateTime> createdAt,
      Value<String> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> fromMember,
      Value<String> toMember,
      Value<int> amountCents,
      Value<String> currency,
      Value<DateTime> date,
      Value<String> method,
      Value<int> rowid,
    });

final class $$SettlementsTableReferences
    extends BaseReferences<_$AppDatabase, $SettlementsTable, SettlementRow> {
  $$SettlementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('settlements__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _fromMemberTable(_$AppDatabase db) =>
      db.members.createAlias('settlements__from_member__members__id');

  $$MembersTableProcessedTableManager get fromMember {
    final $_column = $_itemColumn<String>('from_member')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromMemberTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _toMemberTable(_$AppDatabase db) =>
      db.members.createAlias('settlements__to_member__members__id');

  $$MembersTableProcessedTableManager get toMember {
    final $_column = $_itemColumn<String>('to_member')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toMemberTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SettlementsTableFilterComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get fromMember {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMember,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get toMember {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMember,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettlementsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currency => $composableBuilder(
    column: $table.currency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get fromMember {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMember,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get toMember {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMember,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettlementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettlementsTable> {
  $$SettlementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currency =>
      $composableBuilder(column: $table.currency, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get fromMember {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMember,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get toMember {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMember,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SettlementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettlementsTable,
          SettlementRow,
          $$SettlementsTableFilterComposer,
          $$SettlementsTableOrderingComposer,
          $$SettlementsTableAnnotationComposer,
          $$SettlementsTableCreateCompanionBuilder,
          $$SettlementsTableUpdateCompanionBuilder,
          (SettlementRow, $$SettlementsTableReferences),
          SettlementRow,
          PrefetchHooks Function({bool groupId, bool fromMember, bool toMember})
        > {
  $$SettlementsTableTableManager(_$AppDatabase db, $SettlementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettlementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettlementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettlementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> fromMember = const Value.absent(),
                Value<String> toMember = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> currency = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                fromMember: fromMember,
                toMember: toMember,
                amountCents: amountCents,
                currency: currency,
                date: date,
                method: method,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required DateTime createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String fromMember,
                required String toMember,
                required int amountCents,
                required String currency,
                required DateTime date,
                required String method,
                Value<int> rowid = const Value.absent(),
              }) => SettlementsCompanion.insert(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                fromMember: fromMember,
                toMember: toMember,
                amountCents: amountCents,
                currency: currency,
                date: date,
                method: method,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettlementsTable, SettlementRow>(table),
                  $$SettlementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, fromMember = false, toMember = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$SettlementsTableReferences
                                ._groupIdTable(db),
                            referencedColumn: $$SettlementsTableReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (fromMember) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.fromMember,
                            referencedTable: $$SettlementsTableReferences
                                ._fromMemberTable(db),
                            referencedColumn: $$SettlementsTableReferences
                                ._fromMemberTable(db)
                                .id,
                          ) as T;
                        }
                        if (toMember) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.toMember,
                            referencedTable: $$SettlementsTableReferences
                                ._toMemberTable(db),
                            referencedColumn: $$SettlementsTableReferences
                                ._toMemberTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$SettlementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettlementsTable,
      SettlementRow,
      $$SettlementsTableFilterComposer,
      $$SettlementsTableOrderingComposer,
      $$SettlementsTableAnnotationComposer,
      $$SettlementsTableCreateCompanionBuilder,
      $$SettlementsTableUpdateCompanionBuilder,
      (SettlementRow, $$SettlementsTableReferences),
      SettlementRow,
      PrefetchHooks Function({bool groupId, bool fromMember, bool toMember})
    >;
typedef $$LocalMemberBankTableCreateCompanionBuilder =
    LocalMemberBankCompanion Function({
      required String memberId,
      required String iban,
      Value<String?> bic,
      Value<String?> accountName,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$LocalMemberBankTableUpdateCompanionBuilder =
    LocalMemberBankCompanion Function({
      Value<String> memberId,
      Value<String> iban,
      Value<String?> bic,
      Value<String?> accountName,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$LocalMemberBankTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalMemberBankTable,
          LocalMemberBankRow
        > {
  $$LocalMemberBankTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('local_member_bank__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalMemberBankTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMemberBankTable> {
  $$LocalMemberBankTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get iban => $composableBuilder(
    column: $table.iban,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bic => $composableBuilder(
    column: $table.bic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalMemberBankTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMemberBankTable> {
  $$LocalMemberBankTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get iban => $composableBuilder(
    column: $table.iban,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bic => $composableBuilder(
    column: $table.bic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalMemberBankTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMemberBankTable> {
  $$LocalMemberBankTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get iban =>
      $composableBuilder(column: $table.iban, builder: (column) => column);

  GeneratedColumn<String> get bic =>
      $composableBuilder(column: $table.bic, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalMemberBankTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMemberBankTable,
          LocalMemberBankRow,
          $$LocalMemberBankTableFilterComposer,
          $$LocalMemberBankTableOrderingComposer,
          $$LocalMemberBankTableAnnotationComposer,
          $$LocalMemberBankTableCreateCompanionBuilder,
          $$LocalMemberBankTableUpdateCompanionBuilder,
          (LocalMemberBankRow, $$LocalMemberBankTableReferences),
          LocalMemberBankRow,
          PrefetchHooks Function({bool memberId})
        > {
  $$LocalMemberBankTableTableManager(
    _$AppDatabase db,
    $LocalMemberBankTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMemberBankTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMemberBankTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMemberBankTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<String> iban = const Value.absent(),
                Value<String?> bic = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMemberBankCompanion(
                memberId: memberId,
                iban: iban,
                bic: bic,
                accountName: accountName,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required String iban,
                Value<String?> bic = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalMemberBankCompanion.insert(
                memberId: memberId,
                iban: iban,
                bic: bic,
                accountName: accountName,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalMemberBankTable, LocalMemberBankRow>(table),
                  $$LocalMemberBankTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.memberId,
                        referencedTable: $$LocalMemberBankTableReferences
                            ._memberIdTable(db),
                        referencedColumn: $$LocalMemberBankTableReferences
                            ._memberIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalMemberBankTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMemberBankTable,
      LocalMemberBankRow,
      $$LocalMemberBankTableFilterComposer,
      $$LocalMemberBankTableOrderingComposer,
      $$LocalMemberBankTableAnnotationComposer,
      $$LocalMemberBankTableCreateCompanionBuilder,
      $$LocalMemberBankTableUpdateCompanionBuilder,
      (LocalMemberBankRow, $$LocalMemberBankTableReferences),
      LocalMemberBankRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $$LocalOutboxTableCreateCompanionBuilder =
    LocalOutboxCompanion Function({
      Value<int> seq,
      required String opId,
      required String groupId,
      required String entity,
      required String entityId,
      required String op,
      required String payload,
      required DateTime createdAt,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastErrorCode,
    });
typedef $$LocalOutboxTableUpdateCompanionBuilder =
    LocalOutboxCompanion Function({
      Value<int> seq,
      Value<String> opId,
      Value<String> groupId,
      Value<String> entity,
      Value<String> entityId,
      Value<String> op,
      Value<String> payload,
      Value<DateTime> createdAt,
      Value<int> attempts,
      Value<DateTime?> nextAttemptAt,
      Value<String?> lastErrorCode,
    });

final class $$LocalOutboxTableReferences
    extends BaseReferences<_$AppDatabase, $LocalOutboxTable, LocalOutboxRow> {
  $$LocalOutboxTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('local_outbox__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $LocalOutboxTable> {
  $$LocalOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalOutboxTable> {
  $$LocalOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get opId => $composableBuilder(
    column: $table.opId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entity => $composableBuilder(
    column: $table.entity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get op => $composableBuilder(
    column: $table.op,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalOutboxTable> {
  $$LocalOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get opId =>
      $composableBuilder(column: $table.opId, builder: (column) => column);

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalOutboxTable,
          LocalOutboxRow,
          $$LocalOutboxTableFilterComposer,
          $$LocalOutboxTableOrderingComposer,
          $$LocalOutboxTableAnnotationComposer,
          $$LocalOutboxTableCreateCompanionBuilder,
          $$LocalOutboxTableUpdateCompanionBuilder,
          (LocalOutboxRow, $$LocalOutboxTableReferences),
          LocalOutboxRow,
          PrefetchHooks Function({bool groupId})
        > {
  $$LocalOutboxTableTableManager(_$AppDatabase db, $LocalOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                Value<String> opId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
              }) => LocalOutboxCompanion(
                seq: seq,
                opId: opId,
                groupId: groupId,
                entity: entity,
                entityId: entityId,
                op: op,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String opId,
                required String groupId,
                required String entity,
                required String entityId,
                required String op,
                required String payload,
                required DateTime createdAt,
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> nextAttemptAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
              }) => LocalOutboxCompanion.insert(
                seq: seq,
                opId: opId,
                groupId: groupId,
                entity: entity,
                entityId: entityId,
                op: op,
                payload: payload,
                createdAt: createdAt,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastErrorCode: lastErrorCode,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalOutboxTable, LocalOutboxRow>(table),
                  $$LocalOutboxTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$LocalOutboxTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$LocalOutboxTableReferences
                            ._groupIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalOutboxTable,
      LocalOutboxRow,
      $$LocalOutboxTableFilterComposer,
      $$LocalOutboxTableOrderingComposer,
      $$LocalOutboxTableAnnotationComposer,
      $$LocalOutboxTableCreateCompanionBuilder,
      $$LocalOutboxTableUpdateCompanionBuilder,
      (LocalOutboxRow, $$LocalOutboxTableReferences),
      LocalOutboxRow,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$LocalDriverPromptsTableCreateCompanionBuilder =
    LocalDriverPromptsCompanion Function({
      required String memberId,
      required String askedAt,
      Value<int> rowid,
    });
typedef $$LocalDriverPromptsTableUpdateCompanionBuilder =
    LocalDriverPromptsCompanion Function({
      Value<String> memberId,
      Value<String> askedAt,
      Value<int> rowid,
    });

final class $$LocalDriverPromptsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalDriverPromptsTable,
          LocalDriverPromptRow
        > {
  $$LocalDriverPromptsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MembersTable _memberIdTable(_$AppDatabase db) =>
      db.members.createAlias('local_driver_prompts__member_id__members__id');

  $$MembersTableProcessedTableManager get memberId {
    final $_column = $_itemColumn<String>('member_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_memberIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalDriverPromptsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDriverPromptsTable> {
  $$LocalDriverPromptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get askedAt => $composableBuilder(
    column: $table.askedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MembersTableFilterComposer get memberId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDriverPromptsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDriverPromptsTable> {
  $$LocalDriverPromptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get askedAt => $composableBuilder(
    column: $table.askedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MembersTableOrderingComposer get memberId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDriverPromptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDriverPromptsTable> {
  $$LocalDriverPromptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get askedAt =>
      $composableBuilder(column: $table.askedAt, builder: (column) => column);

  $$MembersTableAnnotationComposer get memberId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.memberId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalDriverPromptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDriverPromptsTable,
          LocalDriverPromptRow,
          $$LocalDriverPromptsTableFilterComposer,
          $$LocalDriverPromptsTableOrderingComposer,
          $$LocalDriverPromptsTableAnnotationComposer,
          $$LocalDriverPromptsTableCreateCompanionBuilder,
          $$LocalDriverPromptsTableUpdateCompanionBuilder,
          (LocalDriverPromptRow, $$LocalDriverPromptsTableReferences),
          LocalDriverPromptRow,
          PrefetchHooks Function({bool memberId})
        > {
  $$LocalDriverPromptsTableTableManager(
    _$AppDatabase db,
    $LocalDriverPromptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDriverPromptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalDriverPromptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalDriverPromptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> memberId = const Value.absent(),
                Value<String> askedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDriverPromptsCompanion(
                memberId: memberId,
                askedAt: askedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required String askedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalDriverPromptsCompanion.insert(
                memberId: memberId,
                askedAt: askedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalDriverPromptsTable, LocalDriverPromptRow>(
                    table,
                  ),
                  $$LocalDriverPromptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memberId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (memberId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.memberId,
                        referencedTable: $$LocalDriverPromptsTableReferences
                            ._memberIdTable(db),
                        referencedColumn: $$LocalDriverPromptsTableReferences
                            ._memberIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalDriverPromptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDriverPromptsTable,
      LocalDriverPromptRow,
      $$LocalDriverPromptsTableFilterComposer,
      $$LocalDriverPromptsTableOrderingComposer,
      $$LocalDriverPromptsTableAnnotationComposer,
      $$LocalDriverPromptsTableCreateCompanionBuilder,
      $$LocalDriverPromptsTableUpdateCompanionBuilder,
      (LocalDriverPromptRow, $$LocalDriverPromptsTableReferences),
      LocalDriverPromptRow,
      PrefetchHooks Function({bool memberId})
    >;
typedef $$LocalPlacesTableCreateCompanionBuilder =
    LocalPlacesCompanion Function({
      required String kind,
      required String label,
      required double lat,
      required double lng,
      required String savedAt,
      Value<int> rowid,
    });
typedef $$LocalPlacesTableUpdateCompanionBuilder =
    LocalPlacesCompanion Function({
      Value<String> kind,
      Value<String> label,
      Value<double> lat,
      Value<double> lng,
      Value<String> savedAt,
      Value<int> rowid,
    });

class $$LocalPlacesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalPlacesTable> {
  $$LocalPlacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalPlacesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalPlacesTable> {
  $$LocalPlacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lat => $composableBuilder(
    column: $table.lat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lng => $composableBuilder(
    column: $table.lng,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savedAt => $composableBuilder(
    column: $table.savedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalPlacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalPlacesTable> {
  $$LocalPlacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lng =>
      $composableBuilder(column: $table.lng, builder: (column) => column);

  GeneratedColumn<String> get savedAt =>
      $composableBuilder(column: $table.savedAt, builder: (column) => column);
}

class $$LocalPlacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalPlacesTable,
          LocalPlaceRow,
          $$LocalPlacesTableFilterComposer,
          $$LocalPlacesTableOrderingComposer,
          $$LocalPlacesTableAnnotationComposer,
          $$LocalPlacesTableCreateCompanionBuilder,
          $$LocalPlacesTableUpdateCompanionBuilder,
          (
            LocalPlaceRow,
            BaseReferences<_$AppDatabase, $LocalPlacesTable, LocalPlaceRow>,
          ),
          LocalPlaceRow,
          PrefetchHooks Function()
        > {
  $$LocalPlacesTableTableManager(_$AppDatabase db, $LocalPlacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalPlacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalPlacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalPlacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> kind = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> lat = const Value.absent(),
                Value<double> lng = const Value.absent(),
                Value<String> savedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalPlacesCompanion(
                kind: kind,
                label: label,
                lat: lat,
                lng: lng,
                savedAt: savedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String kind,
                required String label,
                required double lat,
                required double lng,
                required String savedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalPlacesCompanion.insert(
                kind: kind,
                label: label,
                lat: lat,
                lng: lng,
                savedAt: savedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalPlacesTable, LocalPlaceRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalPlacesTable,
                    LocalPlaceRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalPlacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalPlacesTable,
      LocalPlaceRow,
      $$LocalPlacesTableFilterComposer,
      $$LocalPlacesTableOrderingComposer,
      $$LocalPlacesTableAnnotationComposer,
      $$LocalPlacesTableCreateCompanionBuilder,
      $$LocalPlacesTableUpdateCompanionBuilder,
      (
        LocalPlaceRow,
        BaseReferences<_$AppDatabase, $LocalPlacesTable, LocalPlaceRow>,
      ),
      LocalPlaceRow,
      PrefetchHooks Function()
    >;
typedef $$VehiclesTableCreateCompanionBuilder = VehiclesCompanion Function({
  required String id,
  required String groupId,
  required DateTime createdAt,
  required String updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  required String fuelType,
  required int consumptionMilliPer100km,
  Value<int> wearMilliPerKm,
  Value<int?> kmRateMilliPerKm,
  Value<String?> sourceUserVehicleId,
  Value<int> rowid,
});
typedef $$VehiclesTableUpdateCompanionBuilder = VehiclesCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<DateTime> createdAt,
  Value<String> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<String> fuelType,
  Value<int> consumptionMilliPer100km,
  Value<int> wearMilliPerKm,
  Value<int?> kmRateMilliPerKm,
  Value<String?> sourceUserVehicleId,
  Value<int> rowid,
});

final class $$VehiclesTableReferences
    extends BaseReferences<_$AppDatabase, $VehiclesTable, VehicleRow> {
  $$VehiclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('vehicles__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$RideTemplatesTable, List<RideTemplateRow>>
  _rideTemplatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.rideTemplates,
    aliasName: 'vehicles__id__ride_templates__vehicle_id',
  );

  $$RideTemplatesTableProcessedTableManager get rideTemplatesRefs {
    final manager = $$RideTemplatesTableTableManager(
      $_db,
      $_db.rideTemplates,
    ).filter((f) => f.vehicleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_rideTemplatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$RidesTable, List<RideRow>> _ridesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rides,
    aliasName: 'vehicles__id__rides__vehicle_id',
  );

  $$RidesTableProcessedTableManager get ridesRefs {
    final manager = $$RidesTableTableManager(
      $_db,
      $_db.rides,
    ).filter((f) => f.vehicleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_ridesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$VehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consumptionMilliPer100km => $composableBuilder(
    column: $table.consumptionMilliPer100km,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearMilliPerKm => $composableBuilder(
    column: $table.wearMilliPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kmRateMilliPerKm => $composableBuilder(
    column: $table.kmRateMilliPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceUserVehicleId => $composableBuilder(
    column: $table.sourceUserVehicleId,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> rideTemplatesRefs(
    Expression<bool> Function($$RideTemplatesTableFilterComposer f) f,
  ) {
    final $$RideTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rideTemplates,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RideTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.rideTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ridesRefs(
    Expression<bool> Function($$RidesTableFilterComposer f) f,
  ) {
    final $$RidesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rides,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RidesTableFilterComposer(
            $db: $db,
            $table: $db.rides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consumptionMilliPer100km => $composableBuilder(
    column: $table.consumptionMilliPer100km,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearMilliPerKm => $composableBuilder(
    column: $table.wearMilliPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kmRateMilliPerKm => $composableBuilder(
    column: $table.kmRateMilliPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceUserVehicleId => $composableBuilder(
    column: $table.sourceUserVehicleId,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$VehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VehiclesTable> {
  $$VehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumn<int> get consumptionMilliPer100km => $composableBuilder(
    column: $table.consumptionMilliPer100km,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wearMilliPerKm => $composableBuilder(
    column: $table.wearMilliPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kmRateMilliPerKm => $composableBuilder(
    column: $table.kmRateMilliPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceUserVehicleId => $composableBuilder(
    column: $table.sourceUserVehicleId,
    builder: (column) => column,
  );

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> rideTemplatesRefs<T extends Object>(
    Expression<T> Function($$RideTemplatesTableAnnotationComposer a) f,
  ) {
    final $$RideTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rideTemplates,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RideTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.rideTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ridesRefs<T extends Object>(
    Expression<T> Function($$RidesTableAnnotationComposer a) f,
  ) {
    final $$RidesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rides,
      getReferencedColumn: (t) => t.vehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RidesTableAnnotationComposer(
            $db: $db,
            $table: $db.rides,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$VehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VehiclesTable,
          VehicleRow,
          $$VehiclesTableFilterComposer,
          $$VehiclesTableOrderingComposer,
          $$VehiclesTableAnnotationComposer,
          $$VehiclesTableCreateCompanionBuilder,
          $$VehiclesTableUpdateCompanionBuilder,
          (VehicleRow, $$VehiclesTableReferences),
          VehicleRow,
          PrefetchHooks Function({
            bool groupId,
            bool rideTemplatesRefs,
            bool ridesRefs,
          })
        > {
  $$VehiclesTableTableManager(_$AppDatabase db, $VehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> fuelType = const Value.absent(),
                Value<int> consumptionMilliPer100km = const Value.absent(),
                Value<int> wearMilliPerKm = const Value.absent(),
                Value<int?> kmRateMilliPerKm = const Value.absent(),
                Value<String?> sourceUserVehicleId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                fuelType: fuelType,
                consumptionMilliPer100km: consumptionMilliPer100km,
                wearMilliPerKm: wearMilliPerKm,
                kmRateMilliPerKm: kmRateMilliPerKm,
                sourceUserVehicleId: sourceUserVehicleId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required DateTime createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required String fuelType,
                required int consumptionMilliPer100km,
                Value<int> wearMilliPerKm = const Value.absent(),
                Value<int?> kmRateMilliPerKm = const Value.absent(),
                Value<String?> sourceUserVehicleId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VehiclesCompanion.insert(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                fuelType: fuelType,
                consumptionMilliPer100km: consumptionMilliPer100km,
                wearMilliPerKm: wearMilliPerKm,
                kmRateMilliPerKm: kmRateMilliPerKm,
                sourceUserVehicleId: sourceUserVehicleId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$VehiclesTable, VehicleRow>(table),
                  $$VehiclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                rideTemplatesRefs = false,
                ridesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (rideTemplatesRefs) db.rideTemplates,
                    if (ridesRefs) db.rides,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$VehiclesTableReferences
                                ._groupIdTable(db),
                            referencedColumn: $$VehiclesTableReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (rideTemplatesRefs)
                        await $_getPrefetchedDataByColumns<
                          VehicleRow,
                          $VehiclesTable,
                          RideTemplateRow,
                          $RideTemplatesTable
                        >(
                          currentTable: table,
                          referencedTable: $$VehiclesTableReferences
                              ._rideTemplatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VehiclesTableReferences(
                                db,
                                table,
                                p0,
                              ).rideTemplatesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'vehicle_id',
                          typedResults: items,
                        ),
                      if (ridesRefs)
                        await $_getPrefetchedDataByColumns<
                          VehicleRow,
                          $VehiclesTable,
                          RideRow,
                          $RidesTable
                        >(
                          currentTable: table,
                          referencedTable: $$VehiclesTableReferences
                              ._ridesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$VehiclesTableReferences(
                                db,
                                table,
                                p0,
                              ).ridesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'vehicle_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$VehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VehiclesTable,
      VehicleRow,
      $$VehiclesTableFilterComposer,
      $$VehiclesTableOrderingComposer,
      $$VehiclesTableAnnotationComposer,
      $$VehiclesTableCreateCompanionBuilder,
      $$VehiclesTableUpdateCompanionBuilder,
      (VehicleRow, $$VehiclesTableReferences),
      VehicleRow,
      PrefetchHooks Function({
        bool groupId,
        bool rideTemplatesRefs,
        bool ridesRefs,
      })
    >;
typedef $$RideTemplatesTableCreateCompanionBuilder =
    RideTemplatesCompanion Function({
      required String id,
      required String groupId,
      required DateTime createdAt,
      required String updatedAt,
      Value<DateTime?> deletedAt,
      required String name,
      required int distanceMeters,
      Value<bool> roundTrip,
      required String vehicleId,
      Value<String?> defaultDriverId,
      Value<String> defaultPassengerIds,
      Value<int> tollsCents,
      Value<int> rowid,
    });
typedef $$RideTemplatesTableUpdateCompanionBuilder =
    RideTemplatesCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<DateTime> createdAt,
      Value<String> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<int> distanceMeters,
      Value<bool> roundTrip,
      Value<String> vehicleId,
      Value<String?> defaultDriverId,
      Value<String> defaultPassengerIds,
      Value<int> tollsCents,
      Value<int> rowid,
    });

final class $$RideTemplatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $RideTemplatesTable, RideTemplateRow> {
  $$RideTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('ride_templates__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VehiclesTable _vehicleIdTable(_$AppDatabase db) =>
      db.vehicles.createAlias('ride_templates__vehicle_id__vehicles__id');

  $$VehiclesTableProcessedTableManager get vehicleId {
    final $_column = $_itemColumn<String>('vehicle_id')!;

    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _defaultDriverIdTable(_$AppDatabase db) =>
      db.members.createAlias('ride_templates__default_driver_id__members__id');

  $$MembersTableProcessedTableManager? get defaultDriverId {
    final $_column = $_itemColumn<String>('default_driver_id');
    if ($_column == null) return null;
    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_defaultDriverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RideTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $RideTemplatesTable> {
  $$RideTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get roundTrip => $composableBuilder(
    column: $table.roundTrip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultPassengerIds => $composableBuilder(
    column: $table.defaultPassengerIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tollsCents => $composableBuilder(
    column: $table.tollsCents,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VehiclesTableFilterComposer get vehicleId {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get defaultDriverId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultDriverId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RideTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $RideTemplatesTable> {
  $$RideTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get roundTrip => $composableBuilder(
    column: $table.roundTrip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultPassengerIds => $composableBuilder(
    column: $table.defaultPassengerIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tollsCents => $composableBuilder(
    column: $table.tollsCents,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VehiclesTableOrderingComposer get vehicleId {
    final $$VehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get defaultDriverId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultDriverId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RideTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RideTemplatesTable> {
  $$RideTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get roundTrip =>
      $composableBuilder(column: $table.roundTrip, builder: (column) => column);

  GeneratedColumn<String> get defaultPassengerIds => $composableBuilder(
    column: $table.defaultPassengerIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tollsCents => $composableBuilder(
    column: $table.tollsCents,
    builder: (column) => column,
  );

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VehiclesTableAnnotationComposer get vehicleId {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get defaultDriverId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.defaultDriverId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RideTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RideTemplatesTable,
          RideTemplateRow,
          $$RideTemplatesTableFilterComposer,
          $$RideTemplatesTableOrderingComposer,
          $$RideTemplatesTableAnnotationComposer,
          $$RideTemplatesTableCreateCompanionBuilder,
          $$RideTemplatesTableUpdateCompanionBuilder,
          (RideTemplateRow, $$RideTemplatesTableReferences),
          RideTemplateRow,
          PrefetchHooks Function({
            bool groupId,
            bool vehicleId,
            bool defaultDriverId,
          })
        > {
  $$RideTemplatesTableTableManager(_$AppDatabase db, $RideTemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RideTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RideTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RideTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> distanceMeters = const Value.absent(),
                Value<bool> roundTrip = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String?> defaultDriverId = const Value.absent(),
                Value<String> defaultPassengerIds = const Value.absent(),
                Value<int> tollsCents = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RideTemplatesCompanion(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                distanceMeters: distanceMeters,
                roundTrip: roundTrip,
                vehicleId: vehicleId,
                defaultDriverId: defaultDriverId,
                defaultPassengerIds: defaultPassengerIds,
                tollsCents: tollsCents,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required DateTime createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required int distanceMeters,
                Value<bool> roundTrip = const Value.absent(),
                required String vehicleId,
                Value<String?> defaultDriverId = const Value.absent(),
                Value<String> defaultPassengerIds = const Value.absent(),
                Value<int> tollsCents = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RideTemplatesCompanion.insert(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                distanceMeters: distanceMeters,
                roundTrip: roundTrip,
                vehicleId: vehicleId,
                defaultDriverId: defaultDriverId,
                defaultPassengerIds: defaultPassengerIds,
                tollsCents: tollsCents,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RideTemplatesTable, RideTemplateRow>(table),
                  $$RideTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({groupId = false, vehicleId = false, defaultDriverId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$RideTemplatesTableReferences
                                ._groupIdTable(db),
                            referencedColumn: $$RideTemplatesTableReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (vehicleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.vehicleId,
                            referencedTable: $$RideTemplatesTableReferences
                                ._vehicleIdTable(db),
                            referencedColumn: $$RideTemplatesTableReferences
                                ._vehicleIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (defaultDriverId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.defaultDriverId,
                            referencedTable: $$RideTemplatesTableReferences
                                ._defaultDriverIdTable(db),
                            referencedColumn: $$RideTemplatesTableReferences
                                ._defaultDriverIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$RideTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RideTemplatesTable,
      RideTemplateRow,
      $$RideTemplatesTableFilterComposer,
      $$RideTemplatesTableOrderingComposer,
      $$RideTemplatesTableAnnotationComposer,
      $$RideTemplatesTableCreateCompanionBuilder,
      $$RideTemplatesTableUpdateCompanionBuilder,
      (RideTemplateRow, $$RideTemplatesTableReferences),
      RideTemplateRow,
      PrefetchHooks Function({
        bool groupId,
        bool vehicleId,
        bool defaultDriverId,
      })
    >;
typedef $$RidesTableCreateCompanionBuilder = RidesCompanion Function({
  required String id,
  required String groupId,
  required DateTime createdAt,
  required String updatedAt,
  Value<DateTime?> deletedAt,
  required DateTime date,
  required int distanceMeters,
  Value<bool> roundTrip,
  Value<int> tollsCents,
  required String vehicleId,
  required String driverId,
  Value<String> passengerIds,
  Value<bool> driverCounts,
  required int pricePerUnitMilli,
  Value<bool> useKmRate,
  Value<String?> settledExpenseId,
  Value<int> rowid,
});
typedef $$RidesTableUpdateCompanionBuilder = RidesCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<DateTime> createdAt,
  Value<String> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> date,
  Value<int> distanceMeters,
  Value<bool> roundTrip,
  Value<int> tollsCents,
  Value<String> vehicleId,
  Value<String> driverId,
  Value<String> passengerIds,
  Value<bool> driverCounts,
  Value<int> pricePerUnitMilli,
  Value<bool> useKmRate,
  Value<String?> settledExpenseId,
  Value<int> rowid,
});

final class $$RidesTableReferences
    extends BaseReferences<_$AppDatabase, $RidesTable, RideRow> {
  $$RidesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('rides__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $VehiclesTable _vehicleIdTable(_$AppDatabase db) =>
      db.vehicles.createAlias('rides__vehicle_id__vehicles__id');

  $$VehiclesTableProcessedTableManager get vehicleId {
    final $_column = $_itemColumn<String>('vehicle_id')!;

    final manager = $$VehiclesTableTableManager(
      $_db,
      $_db.vehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_vehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MembersTable _driverIdTable(_$AppDatabase db) =>
      db.members.createAlias('rides__driver_id__members__id');

  $$MembersTableProcessedTableManager get driverId {
    final $_column = $_itemColumn<String>('driver_id')!;

    final manager = $$MembersTableTableManager(
      $_db,
      $_db.members,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_driverIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExpensesTable _settledExpenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias('rides__settled_expense_id__expenses__id');

  $$ExpensesTableProcessedTableManager? get settledExpenseId {
    final $_column = $_itemColumn<String>('settled_expense_id');
    if ($_column == null) return null;
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_settledExpenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RidesTableFilterComposer extends Composer<_$AppDatabase, $RidesTable> {
  $$RidesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get roundTrip => $composableBuilder(
    column: $table.roundTrip,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tollsCents => $composableBuilder(
    column: $table.tollsCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passengerIds => $composableBuilder(
    column: $table.passengerIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get driverCounts => $composableBuilder(
    column: $table.driverCounts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pricePerUnitMilli => $composableBuilder(
    column: $table.pricePerUnitMilli,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get useKmRate => $composableBuilder(
    column: $table.useKmRate,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VehiclesTableFilterComposer get vehicleId {
    final $$VehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableFilterComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableFilterComposer get driverId {
    final $$MembersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.driverId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableFilterComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableFilterComposer get settledExpenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.settledExpenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RidesTableOrderingComposer
    extends Composer<_$AppDatabase, $RidesTable> {
  $$RidesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get roundTrip => $composableBuilder(
    column: $table.roundTrip,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tollsCents => $composableBuilder(
    column: $table.tollsCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passengerIds => $composableBuilder(
    column: $table.passengerIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get driverCounts => $composableBuilder(
    column: $table.driverCounts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pricePerUnitMilli => $composableBuilder(
    column: $table.pricePerUnitMilli,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get useKmRate => $composableBuilder(
    column: $table.useKmRate,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VehiclesTableOrderingComposer get vehicleId {
    final $$VehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableOrderingComposer get driverId {
    final $$MembersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.driverId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableOrderingComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableOrderingComposer get settledExpenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.settledExpenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RidesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RidesTable> {
  $$RidesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get distanceMeters => $composableBuilder(
    column: $table.distanceMeters,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get roundTrip =>
      $composableBuilder(column: $table.roundTrip, builder: (column) => column);

  GeneratedColumn<int> get tollsCents => $composableBuilder(
    column: $table.tollsCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get passengerIds => $composableBuilder(
    column: $table.passengerIds,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get driverCounts => $composableBuilder(
    column: $table.driverCounts,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pricePerUnitMilli => $composableBuilder(
    column: $table.pricePerUnitMilli,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get useKmRate =>
      $composableBuilder(column: $table.useKmRate, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$VehiclesTableAnnotationComposer get vehicleId {
    final $$VehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.vehicleId,
      referencedTable: $db.vehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$VehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.vehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MembersTableAnnotationComposer get driverId {
    final $$MembersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.driverId,
      referencedTable: $db.members,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembersTableAnnotationComposer(
            $db: $db,
            $table: $db.members,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExpensesTableAnnotationComposer get settledExpenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.settledExpenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RidesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RidesTable,
          RideRow,
          $$RidesTableFilterComposer,
          $$RidesTableOrderingComposer,
          $$RidesTableAnnotationComposer,
          $$RidesTableCreateCompanionBuilder,
          $$RidesTableUpdateCompanionBuilder,
          (RideRow, $$RidesTableReferences),
          RideRow,
          PrefetchHooks Function({
            bool groupId,
            bool vehicleId,
            bool driverId,
            bool settledExpenseId,
          })
        > {
  $$RidesTableTableManager(_$AppDatabase db, $RidesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RidesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RidesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RidesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> distanceMeters = const Value.absent(),
                Value<bool> roundTrip = const Value.absent(),
                Value<int> tollsCents = const Value.absent(),
                Value<String> vehicleId = const Value.absent(),
                Value<String> driverId = const Value.absent(),
                Value<String> passengerIds = const Value.absent(),
                Value<bool> driverCounts = const Value.absent(),
                Value<int> pricePerUnitMilli = const Value.absent(),
                Value<bool> useKmRate = const Value.absent(),
                Value<String?> settledExpenseId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RidesCompanion(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                date: date,
                distanceMeters: distanceMeters,
                roundTrip: roundTrip,
                tollsCents: tollsCents,
                vehicleId: vehicleId,
                driverId: driverId,
                passengerIds: passengerIds,
                driverCounts: driverCounts,
                pricePerUnitMilli: pricePerUnitMilli,
                useKmRate: useKmRate,
                settledExpenseId: settledExpenseId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required DateTime createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required DateTime date,
                required int distanceMeters,
                Value<bool> roundTrip = const Value.absent(),
                Value<int> tollsCents = const Value.absent(),
                required String vehicleId,
                required String driverId,
                Value<String> passengerIds = const Value.absent(),
                Value<bool> driverCounts = const Value.absent(),
                required int pricePerUnitMilli,
                Value<bool> useKmRate = const Value.absent(),
                Value<String?> settledExpenseId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RidesCompanion.insert(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                date: date,
                distanceMeters: distanceMeters,
                roundTrip: roundTrip,
                tollsCents: tollsCents,
                vehicleId: vehicleId,
                driverId: driverId,
                passengerIds: passengerIds,
                driverCounts: driverCounts,
                pricePerUnitMilli: pricePerUnitMilli,
                useKmRate: useKmRate,
                settledExpenseId: settledExpenseId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$RidesTable, RideRow>(table),
                  $$RidesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                groupId = false,
                vehicleId = false,
                driverId = false,
                settledExpenseId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (groupId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.groupId,
                            referencedTable: $$RidesTableReferences
                                ._groupIdTable(db),
                            referencedColumn: $$RidesTableReferences
                                ._groupIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (vehicleId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.vehicleId,
                            referencedTable: $$RidesTableReferences
                                ._vehicleIdTable(db),
                            referencedColumn: $$RidesTableReferences
                                ._vehicleIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (driverId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.driverId,
                            referencedTable: $$RidesTableReferences
                                ._driverIdTable(db),
                            referencedColumn: $$RidesTableReferences
                                ._driverIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (settledExpenseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.settledExpenseId,
                            referencedTable: $$RidesTableReferences
                                ._settledExpenseIdTable(db),
                            referencedColumn: $$RidesTableReferences
                                ._settledExpenseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$RidesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RidesTable,
      RideRow,
      $$RidesTableFilterComposer,
      $$RidesTableOrderingComposer,
      $$RidesTableAnnotationComposer,
      $$RidesTableCreateCompanionBuilder,
      $$RidesTableUpdateCompanionBuilder,
      (RideRow, $$RidesTableReferences),
      RideRow,
      PrefetchHooks Function({
        bool groupId,
        bool vehicleId,
        bool driverId,
        bool settledExpenseId,
      })
    >;
typedef $$ExpenseRevisionsTableCreateCompanionBuilder =
    ExpenseRevisionsCompanion Function({
      required String id,
      required String expenseId,
      required String groupId,
      required int revision,
      required DateTime changedAt,
      Value<String?> authorMemberId,
      required String snapshot,
      Value<int> rowid,
    });
typedef $$ExpenseRevisionsTableUpdateCompanionBuilder =
    ExpenseRevisionsCompanion Function({
      Value<String> id,
      Value<String> expenseId,
      Value<String> groupId,
      Value<int> revision,
      Value<DateTime> changedAt,
      Value<String?> authorMemberId,
      Value<String> snapshot,
      Value<int> rowid,
    });

final class $$ExpenseRevisionsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $ExpenseRevisionsTable,
          ExpenseRevisionRow
        > {
  $$ExpenseRevisionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ExpensesTable _expenseIdTable(_$AppDatabase db) =>
      db.expenses.createAlias('expense_revisions__expense_id__expenses__id');

  $$ExpensesTableProcessedTableManager get expenseId {
    final $_column = $_itemColumn<String>('expense_id')!;

    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_expenseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('expense_revisions__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpenseRevisionsTableFilterComposer
    extends Composer<_$AppDatabase, $ExpenseRevisionsTable> {
  $$ExpenseRevisionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authorMemberId => $composableBuilder(
    column: $table.authorMemberId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnFilters(column),
  );

  $$ExpensesTableFilterComposer get expenseId {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseRevisionsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpenseRevisionsTable> {
  $$ExpenseRevisionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authorMemberId => $composableBuilder(
    column: $table.authorMemberId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get snapshot => $composableBuilder(
    column: $table.snapshot,
    builder: (column) => ColumnOrderings(column),
  );

  $$ExpensesTableOrderingComposer get expenseId {
    final $$ExpensesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableOrderingComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseRevisionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpenseRevisionsTable> {
  $$ExpenseRevisionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<String> get authorMemberId => $composableBuilder(
    column: $table.authorMemberId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get snapshot =>
      $composableBuilder(column: $table.snapshot, builder: (column) => column);

  $$ExpensesTableAnnotationComposer get expenseId {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.expenseId,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpenseRevisionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpenseRevisionsTable,
          ExpenseRevisionRow,
          $$ExpenseRevisionsTableFilterComposer,
          $$ExpenseRevisionsTableOrderingComposer,
          $$ExpenseRevisionsTableAnnotationComposer,
          $$ExpenseRevisionsTableCreateCompanionBuilder,
          $$ExpenseRevisionsTableUpdateCompanionBuilder,
          (ExpenseRevisionRow, $$ExpenseRevisionsTableReferences),
          ExpenseRevisionRow,
          PrefetchHooks Function({bool expenseId, bool groupId})
        > {
  $$ExpenseRevisionsTableTableManager(
    _$AppDatabase db,
    $ExpenseRevisionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpenseRevisionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpenseRevisionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpenseRevisionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<String?> authorMemberId = const Value.absent(),
                Value<String> snapshot = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseRevisionsCompanion(
                id: id,
                expenseId: expenseId,
                groupId: groupId,
                revision: revision,
                changedAt: changedAt,
                authorMemberId: authorMemberId,
                snapshot: snapshot,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String expenseId,
                required String groupId,
                required int revision,
                required DateTime changedAt,
                Value<String?> authorMemberId = const Value.absent(),
                required String snapshot,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseRevisionsCompanion.insert(
                id: id,
                expenseId: expenseId,
                groupId: groupId,
                revision: revision,
                changedAt: changedAt,
                authorMemberId: authorMemberId,
                snapshot: snapshot,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpenseRevisionsTable, ExpenseRevisionRow>(
                    table,
                  ),
                  $$ExpenseRevisionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({expenseId = false, groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (expenseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.expenseId,
                        referencedTable: $$ExpenseRevisionsTableReferences
                            ._expenseIdTable(db),
                        referencedColumn: $$ExpenseRevisionsTableReferences
                            ._expenseIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$ExpenseRevisionsTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$ExpenseRevisionsTableReferences
                            ._groupIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExpenseRevisionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpenseRevisionsTable,
      ExpenseRevisionRow,
      $$ExpenseRevisionsTableFilterComposer,
      $$ExpenseRevisionsTableOrderingComposer,
      $$ExpenseRevisionsTableAnnotationComposer,
      $$ExpenseRevisionsTableCreateCompanionBuilder,
      $$ExpenseRevisionsTableUpdateCompanionBuilder,
      (ExpenseRevisionRow, $$ExpenseRevisionsTableReferences),
      ExpenseRevisionRow,
      PrefetchHooks Function({bool expenseId, bool groupId})
    >;
typedef $$LocalGroupSyncTableCreateCompanionBuilder =
    LocalGroupSyncCompanion Function({
      required String groupId,
      required String state,
      Value<String?> role,
      Value<DateTime?> lastPushAt,
      Value<DateTime?> lastPullAt,
      Value<String?> lastErrorCode,
      Value<DateTime?> lastErrorAt,
      Value<int> rowid,
    });
typedef $$LocalGroupSyncTableUpdateCompanionBuilder =
    LocalGroupSyncCompanion Function({
      Value<String> groupId,
      Value<String> state,
      Value<String?> role,
      Value<DateTime?> lastPushAt,
      Value<DateTime?> lastPullAt,
      Value<String?> lastErrorCode,
      Value<DateTime?> lastErrorAt,
      Value<int> rowid,
    });

final class $$LocalGroupSyncTableReferences
    extends
        BaseReferences<_$AppDatabase, $LocalGroupSyncTable, LocalGroupSyncRow> {
  $$LocalGroupSyncTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('local_group_sync__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalGroupSyncTableFilterComposer
    extends Composer<_$AppDatabase, $LocalGroupSyncTable> {
  $$LocalGroupSyncTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastErrorAt => $composableBuilder(
    column: $table.lastErrorAt,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalGroupSyncTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalGroupSyncTable> {
  $$LocalGroupSyncTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get role => $composableBuilder(
    column: $table.role,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastErrorAt => $composableBuilder(
    column: $table.lastErrorAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalGroupSyncTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalGroupSyncTable> {
  $$LocalGroupSyncTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get role =>
      $composableBuilder(column: $table.role, builder: (column) => column);

  GeneratedColumn<DateTime> get lastPushAt => $composableBuilder(
    column: $table.lastPushAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastPullAt => $composableBuilder(
    column: $table.lastPullAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastErrorCode => $composableBuilder(
    column: $table.lastErrorCode,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastErrorAt => $composableBuilder(
    column: $table.lastErrorAt,
    builder: (column) => column,
  );

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalGroupSyncTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalGroupSyncTable,
          LocalGroupSyncRow,
          $$LocalGroupSyncTableFilterComposer,
          $$LocalGroupSyncTableOrderingComposer,
          $$LocalGroupSyncTableAnnotationComposer,
          $$LocalGroupSyncTableCreateCompanionBuilder,
          $$LocalGroupSyncTableUpdateCompanionBuilder,
          (LocalGroupSyncRow, $$LocalGroupSyncTableReferences),
          LocalGroupSyncRow,
          PrefetchHooks Function({bool groupId})
        > {
  $$LocalGroupSyncTableTableManager(
    _$AppDatabase db,
    $LocalGroupSyncTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalGroupSyncTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalGroupSyncTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalGroupSyncTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> role = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<DateTime?> lastErrorAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalGroupSyncCompanion(
                groupId: groupId,
                state: state,
                role: role,
                lastPushAt: lastPushAt,
                lastPullAt: lastPullAt,
                lastErrorCode: lastErrorCode,
                lastErrorAt: lastErrorAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String state,
                Value<String?> role = const Value.absent(),
                Value<DateTime?> lastPushAt = const Value.absent(),
                Value<DateTime?> lastPullAt = const Value.absent(),
                Value<String?> lastErrorCode = const Value.absent(),
                Value<DateTime?> lastErrorAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalGroupSyncCompanion.insert(
                groupId: groupId,
                state: state,
                role: role,
                lastPushAt: lastPushAt,
                lastPullAt: lastPullAt,
                lastErrorCode: lastErrorCode,
                lastErrorAt: lastErrorAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalGroupSyncTable, LocalGroupSyncRow>(table),
                  $$LocalGroupSyncTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$LocalGroupSyncTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$LocalGroupSyncTableReferences
                            ._groupIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalGroupSyncTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalGroupSyncTable,
      LocalGroupSyncRow,
      $$LocalGroupSyncTableFilterComposer,
      $$LocalGroupSyncTableOrderingComposer,
      $$LocalGroupSyncTableAnnotationComposer,
      $$LocalGroupSyncTableCreateCompanionBuilder,
      $$LocalGroupSyncTableUpdateCompanionBuilder,
      (LocalGroupSyncRow, $$LocalGroupSyncTableReferences),
      LocalGroupSyncRow,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$LocalSyncCursorTableCreateCompanionBuilder =
    LocalSyncCursorCompanion Function({
      required String groupId,
      required String syncedTable,
      Value<int> cursor,
      Value<int> rowid,
    });
typedef $$LocalSyncCursorTableUpdateCompanionBuilder =
    LocalSyncCursorCompanion Function({
      Value<String> groupId,
      Value<String> syncedTable,
      Value<int> cursor,
      Value<int> rowid,
    });

final class $$LocalSyncCursorTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalSyncCursorTable,
          LocalSyncCursorRow
        > {
  $$LocalSyncCursorTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GroupsTable _groupIdTable(_$AppDatabase db) =>
      db.groups.createAlias('local_sync_cursor__group_id__groups__id');

  $$GroupsTableProcessedTableManager get groupId {
    final $_column = $_itemColumn<String>('group_id')!;

    final manager = $$GroupsTableTableManager(
      $_db,
      $_db.groups,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_groupIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalSyncCursorTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSyncCursorTable> {
  $$LocalSyncCursorTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncedTable => $composableBuilder(
    column: $table.syncedTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  $$GroupsTableFilterComposer get groupId {
    final $$GroupsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableFilterComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSyncCursorTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSyncCursorTable> {
  $$LocalSyncCursorTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncedTable => $composableBuilder(
    column: $table.syncedTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  $$GroupsTableOrderingComposer get groupId {
    final $$GroupsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableOrderingComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSyncCursorTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSyncCursorTable> {
  $$LocalSyncCursorTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncedTable => $composableBuilder(
    column: $table.syncedTable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  $$GroupsTableAnnotationComposer get groupId {
    final $$GroupsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.groupId,
      referencedTable: $db.groups,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GroupsTableAnnotationComposer(
            $db: $db,
            $table: $db.groups,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalSyncCursorTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSyncCursorTable,
          LocalSyncCursorRow,
          $$LocalSyncCursorTableFilterComposer,
          $$LocalSyncCursorTableOrderingComposer,
          $$LocalSyncCursorTableAnnotationComposer,
          $$LocalSyncCursorTableCreateCompanionBuilder,
          $$LocalSyncCursorTableUpdateCompanionBuilder,
          (LocalSyncCursorRow, $$LocalSyncCursorTableReferences),
          LocalSyncCursorRow,
          PrefetchHooks Function({bool groupId})
        > {
  $$LocalSyncCursorTableTableManager(
    _$AppDatabase db,
    $LocalSyncCursorTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncCursorTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncCursorTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncCursorTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> groupId = const Value.absent(),
                Value<String> syncedTable = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncCursorCompanion(
                groupId: groupId,
                syncedTable: syncedTable,
                cursor: cursor,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String groupId,
                required String syncedTable,
                Value<int> cursor = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncCursorCompanion.insert(
                groupId: groupId,
                syncedTable: syncedTable,
                cursor: cursor,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSyncCursorTable, LocalSyncCursorRow>(table),
                  $$LocalSyncCursorTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({groupId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (groupId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.groupId,
                        referencedTable: $$LocalSyncCursorTableReferences
                            ._groupIdTable(db),
                        referencedColumn: $$LocalSyncCursorTableReferences
                            ._groupIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalSyncCursorTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSyncCursorTable,
      LocalSyncCursorRow,
      $$LocalSyncCursorTableFilterComposer,
      $$LocalSyncCursorTableOrderingComposer,
      $$LocalSyncCursorTableAnnotationComposer,
      $$LocalSyncCursorTableCreateCompanionBuilder,
      $$LocalSyncCursorTableUpdateCompanionBuilder,
      (LocalSyncCursorRow, $$LocalSyncCursorTableReferences),
      LocalSyncCursorRow,
      PrefetchHooks Function({bool groupId})
    >;
typedef $$LocalSettingsTableCreateCompanionBuilder =
    LocalSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$LocalSettingsTableUpdateCompanionBuilder =
    LocalSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$LocalSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalSettingsTable> {
  $$LocalSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalSettingsTable,
          LocalSettingRow,
          $$LocalSettingsTableFilterComposer,
          $$LocalSettingsTableOrderingComposer,
          $$LocalSettingsTableAnnotationComposer,
          $$LocalSettingsTableCreateCompanionBuilder,
          $$LocalSettingsTableUpdateCompanionBuilder,
          (
            LocalSettingRow,
            BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSettingRow>,
          ),
          LocalSettingRow,
          PrefetchHooks Function()
        > {
  $$LocalSettingsTableTableManager(_$AppDatabase db, $LocalSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => LocalSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => LocalSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalSettingsTable, LocalSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalSettingsTable,
                    LocalSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalSettingsTable,
      LocalSettingRow,
      $$LocalSettingsTableFilterComposer,
      $$LocalSettingsTableOrderingComposer,
      $$LocalSettingsTableAnnotationComposer,
      $$LocalSettingsTableCreateCompanionBuilder,
      $$LocalSettingsTableUpdateCompanionBuilder,
      (
        LocalSettingRow,
        BaseReferences<_$AppDatabase, $LocalSettingsTable, LocalSettingRow>,
      ),
      LocalSettingRow,
      PrefetchHooks Function()
    >;
typedef $$ProfileTableCreateCompanionBuilder = ProfileCompanion Function({
  required String id,
  required String displayName,
  Value<int?> avatarColor,
  Value<String?> avatarEmoji,
  Value<String?> paypalMe,
  required String updatedAt,
  Value<int> rowid,
});
typedef $$ProfileTableUpdateCompanionBuilder = ProfileCompanion Function({
  Value<String> id,
  Value<String> displayName,
  Value<int?> avatarColor,
  Value<String?> avatarEmoji,
  Value<String?> paypalMe,
  Value<String> updatedAt,
  Value<int> rowid,
});

final class $$ProfileTableReferences
    extends BaseReferences<_$AppDatabase, $ProfileTable, ProfileRow> {
  $$ProfileTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$LocalProfileBankTable, List<LocalProfileBankRow>>
  _localProfileBankRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.localProfileBank,
    aliasName: 'profile__id__local_profile_bank__profile_id',
  );

  $$LocalProfileBankTableProcessedTableManager get localProfileBankRefs {
    final manager = $$LocalProfileBankTableTableManager(
      $_db,
      $_db.localProfileBank,
    ).filter((f) => f.profileId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _localProfileBankRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProfileTableFilterComposer
    extends Composer<_$AppDatabase, $ProfileTable> {
  $$ProfileTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paypalMe => $composableBuilder(
    column: $table.paypalMe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> localProfileBankRefs(
    Expression<bool> Function($$LocalProfileBankTableFilterComposer f) f,
  ) {
    final $$LocalProfileBankTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localProfileBank,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalProfileBankTableFilterComposer(
            $db: $db,
            $table: $db.localProfileBank,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfileTableOrderingComposer
    extends Composer<_$AppDatabase, $ProfileTable> {
  $$ProfileTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paypalMe => $composableBuilder(
    column: $table.paypalMe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProfileTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProfileTable> {
  $$ProfileTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<int> get avatarColor => $composableBuilder(
    column: $table.avatarColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarEmoji => $composableBuilder(
    column: $table.avatarEmoji,
    builder: (column) => column,
  );

  GeneratedColumn<String> get paypalMe =>
      $composableBuilder(column: $table.paypalMe, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> localProfileBankRefs<T extends Object>(
    Expression<T> Function($$LocalProfileBankTableAnnotationComposer a) f,
  ) {
    final $$LocalProfileBankTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.localProfileBank,
      getReferencedColumn: (t) => t.profileId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LocalProfileBankTableAnnotationComposer(
            $db: $db,
            $table: $db.localProfileBank,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProfileTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProfileTable,
          ProfileRow,
          $$ProfileTableFilterComposer,
          $$ProfileTableOrderingComposer,
          $$ProfileTableAnnotationComposer,
          $$ProfileTableCreateCompanionBuilder,
          $$ProfileTableUpdateCompanionBuilder,
          (ProfileRow, $$ProfileTableReferences),
          ProfileRow,
          PrefetchHooks Function({bool localProfileBankRefs})
        > {
  $$ProfileTableTableManager(_$AppDatabase db, $ProfileTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProfileTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProfileTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProfileTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int?> avatarColor = const Value.absent(),
                Value<String?> avatarEmoji = const Value.absent(),
                Value<String?> paypalMe = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProfileCompanion(
                id: id,
                displayName: displayName,
                avatarColor: avatarColor,
                avatarEmoji: avatarEmoji,
                paypalMe: paypalMe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String displayName,
                Value<int?> avatarColor = const Value.absent(),
                Value<String?> avatarEmoji = const Value.absent(),
                Value<String?> paypalMe = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProfileCompanion.insert(
                id: id,
                displayName: displayName,
                avatarColor: avatarColor,
                avatarEmoji: avatarEmoji,
                paypalMe: paypalMe,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProfileTable, ProfileRow>(table),
                  $$ProfileTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({localProfileBankRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (localProfileBankRefs) db.localProfileBank,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (localProfileBankRefs)
                    await $_getPrefetchedDataByColumns<
                      ProfileRow,
                      $ProfileTable,
                      LocalProfileBankRow,
                      $LocalProfileBankTable
                    >(
                      currentTable: table,
                      referencedTable: $$ProfileTableReferences
                          ._localProfileBankRefsTable(db),
                      managerFromTypedResult: (p0) => $$ProfileTableReferences(
                        db,
                        table,
                        p0,
                      ).localProfileBankRefs,
                      currentColumn: 'id',
                      referencedColumn: 'profile_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProfileTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProfileTable,
      ProfileRow,
      $$ProfileTableFilterComposer,
      $$ProfileTableOrderingComposer,
      $$ProfileTableAnnotationComposer,
      $$ProfileTableCreateCompanionBuilder,
      $$ProfileTableUpdateCompanionBuilder,
      (ProfileRow, $$ProfileTableReferences),
      ProfileRow,
      PrefetchHooks Function({bool localProfileBankRefs})
    >;
typedef $$LocalProfileBankTableCreateCompanionBuilder =
    LocalProfileBankCompanion Function({
      required String profileId,
      required String iban,
      Value<String?> bic,
      Value<String?> accountName,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$LocalProfileBankTableUpdateCompanionBuilder =
    LocalProfileBankCompanion Function({
      Value<String> profileId,
      Value<String> iban,
      Value<String?> bic,
      Value<String?> accountName,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$LocalProfileBankTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LocalProfileBankTable,
          LocalProfileBankRow
        > {
  $$LocalProfileBankTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ProfileTable _profileIdTable(_$AppDatabase db) =>
      db.profile.createAlias('local_profile_bank__profile_id__profile__id');

  $$ProfileTableProcessedTableManager get profileId {
    final $_column = $_itemColumn<String>('profile_id')!;

    final manager = $$ProfileTableTableManager(
      $_db,
      $_db.profile,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_profileIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LocalProfileBankTableFilterComposer
    extends Composer<_$AppDatabase, $LocalProfileBankTable> {
  $$LocalProfileBankTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get iban => $composableBuilder(
    column: $table.iban,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bic => $composableBuilder(
    column: $table.bic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ProfileTableFilterComposer get profileId {
    final $$ProfileTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableFilterComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalProfileBankTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalProfileBankTable> {
  $$LocalProfileBankTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get iban => $composableBuilder(
    column: $table.iban,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bic => $composableBuilder(
    column: $table.bic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ProfileTableOrderingComposer get profileId {
    final $$ProfileTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableOrderingComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalProfileBankTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalProfileBankTable> {
  $$LocalProfileBankTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get iban =>
      $composableBuilder(column: $table.iban, builder: (column) => column);

  GeneratedColumn<String> get bic =>
      $composableBuilder(column: $table.bic, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ProfileTableAnnotationComposer get profileId {
    final $$ProfileTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.profileId,
      referencedTable: $db.profile,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProfileTableAnnotationComposer(
            $db: $db,
            $table: $db.profile,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LocalProfileBankTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalProfileBankTable,
          LocalProfileBankRow,
          $$LocalProfileBankTableFilterComposer,
          $$LocalProfileBankTableOrderingComposer,
          $$LocalProfileBankTableAnnotationComposer,
          $$LocalProfileBankTableCreateCompanionBuilder,
          $$LocalProfileBankTableUpdateCompanionBuilder,
          (LocalProfileBankRow, $$LocalProfileBankTableReferences),
          LocalProfileBankRow,
          PrefetchHooks Function({bool profileId})
        > {
  $$LocalProfileBankTableTableManager(
    _$AppDatabase db,
    $LocalProfileBankTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalProfileBankTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalProfileBankTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalProfileBankTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> profileId = const Value.absent(),
                Value<String> iban = const Value.absent(),
                Value<String?> bic = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalProfileBankCompanion(
                profileId: profileId,
                iban: iban,
                bic: bic,
                accountName: accountName,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String profileId,
                required String iban,
                Value<String?> bic = const Value.absent(),
                Value<String?> accountName = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalProfileBankCompanion.insert(
                profileId: profileId,
                iban: iban,
                bic: bic,
                accountName: accountName,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalProfileBankTable, LocalProfileBankRow>(
                    table,
                  ),
                  $$LocalProfileBankTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({profileId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (profileId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.profileId,
                        referencedTable: $$LocalProfileBankTableReferences
                            ._profileIdTable(db),
                        referencedColumn: $$LocalProfileBankTableReferences
                            ._profileIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LocalProfileBankTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalProfileBankTable,
      LocalProfileBankRow,
      $$LocalProfileBankTableFilterComposer,
      $$LocalProfileBankTableOrderingComposer,
      $$LocalProfileBankTableAnnotationComposer,
      $$LocalProfileBankTableCreateCompanionBuilder,
      $$LocalProfileBankTableUpdateCompanionBuilder,
      (LocalProfileBankRow, $$LocalProfileBankTableReferences),
      LocalProfileBankRow,
      PrefetchHooks Function({bool profileId})
    >;
typedef $$UserVehiclesTableCreateCompanionBuilder =
    UserVehiclesCompanion Function({
      required String id,
      required String name,
      required String fuelType,
      required int consumptionMilliPer100km,
      Value<int> wearMilliPerKm,
      Value<int?> kmRateMilliPerKm,
      required DateTime createdAt,
      required String updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$UserVehiclesTableUpdateCompanionBuilder =
    UserVehiclesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> fuelType,
      Value<int> consumptionMilliPer100km,
      Value<int> wearMilliPerKm,
      Value<int?> kmRateMilliPerKm,
      Value<DateTime> createdAt,
      Value<String> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

final class $$UserVehiclesTableReferences
    extends BaseReferences<_$AppDatabase, $UserVehiclesTable, UserVehicleRow> {
  $$UserVehiclesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$UserVehicleCostsTable, List<UserVehicleCostsRow>>
  _userVehicleCostsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.userVehicleCosts,
    aliasName: 'user_vehicles__id__user_vehicle_costs__user_vehicle_id',
  );

  $$UserVehicleCostsTableProcessedTableManager get userVehicleCostsRefs {
    final manager = $$UserVehicleCostsTableTableManager(
      $_db,
      $_db.userVehicleCosts,
    ).filter((f) => f.userVehicleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _userVehicleCostsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserVehiclesTableFilterComposer
    extends Composer<_$AppDatabase, $UserVehiclesTable> {
  $$UserVehiclesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get consumptionMilliPer100km => $composableBuilder(
    column: $table.consumptionMilliPer100km,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wearMilliPerKm => $composableBuilder(
    column: $table.wearMilliPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kmRateMilliPerKm => $composableBuilder(
    column: $table.kmRateMilliPerKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> userVehicleCostsRefs(
    Expression<bool> Function($$UserVehicleCostsTableFilterComposer f) f,
  ) {
    final $$UserVehicleCostsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userVehicleCosts,
      getReferencedColumn: (t) => t.userVehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserVehicleCostsTableFilterComposer(
            $db: $db,
            $table: $db.userVehicleCosts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserVehiclesTableOrderingComposer
    extends Composer<_$AppDatabase, $UserVehiclesTable> {
  $$UserVehiclesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fuelType => $composableBuilder(
    column: $table.fuelType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get consumptionMilliPer100km => $composableBuilder(
    column: $table.consumptionMilliPer100km,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wearMilliPerKm => $composableBuilder(
    column: $table.wearMilliPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kmRateMilliPerKm => $composableBuilder(
    column: $table.kmRateMilliPerKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserVehiclesTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserVehiclesTable> {
  $$UserVehiclesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get fuelType =>
      $composableBuilder(column: $table.fuelType, builder: (column) => column);

  GeneratedColumn<int> get consumptionMilliPer100km => $composableBuilder(
    column: $table.consumptionMilliPer100km,
    builder: (column) => column,
  );

  GeneratedColumn<int> get wearMilliPerKm => $composableBuilder(
    column: $table.wearMilliPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<int> get kmRateMilliPerKm => $composableBuilder(
    column: $table.kmRateMilliPerKm,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  Expression<T> userVehicleCostsRefs<T extends Object>(
    Expression<T> Function($$UserVehicleCostsTableAnnotationComposer a) f,
  ) {
    final $$UserVehicleCostsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.userVehicleCosts,
      getReferencedColumn: (t) => t.userVehicleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserVehicleCostsTableAnnotationComposer(
            $db: $db,
            $table: $db.userVehicleCosts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserVehiclesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserVehiclesTable,
          UserVehicleRow,
          $$UserVehiclesTableFilterComposer,
          $$UserVehiclesTableOrderingComposer,
          $$UserVehiclesTableAnnotationComposer,
          $$UserVehiclesTableCreateCompanionBuilder,
          $$UserVehiclesTableUpdateCompanionBuilder,
          (UserVehicleRow, $$UserVehiclesTableReferences),
          UserVehicleRow,
          PrefetchHooks Function({bool userVehicleCostsRefs})
        > {
  $$UserVehiclesTableTableManager(_$AppDatabase db, $UserVehiclesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserVehiclesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserVehiclesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserVehiclesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> fuelType = const Value.absent(),
                Value<int> consumptionMilliPer100km = const Value.absent(),
                Value<int> wearMilliPerKm = const Value.absent(),
                Value<int?> kmRateMilliPerKm = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserVehiclesCompanion(
                id: id,
                name: name,
                fuelType: fuelType,
                consumptionMilliPer100km: consumptionMilliPer100km,
                wearMilliPerKm: wearMilliPerKm,
                kmRateMilliPerKm: kmRateMilliPerKm,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String fuelType,
                required int consumptionMilliPer100km,
                Value<int> wearMilliPerKm = const Value.absent(),
                Value<int?> kmRateMilliPerKm = const Value.absent(),
                required DateTime createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserVehiclesCompanion.insert(
                id: id,
                name: name,
                fuelType: fuelType,
                consumptionMilliPer100km: consumptionMilliPer100km,
                wearMilliPerKm: wearMilliPerKm,
                kmRateMilliPerKm: kmRateMilliPerKm,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserVehiclesTable, UserVehicleRow>(table),
                  $$UserVehiclesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userVehicleCostsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (userVehicleCostsRefs) db.userVehicleCosts,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (userVehicleCostsRefs)
                    await $_getPrefetchedDataByColumns<
                      UserVehicleRow,
                      $UserVehiclesTable,
                      UserVehicleCostsRow,
                      $UserVehicleCostsTable
                    >(
                      currentTable: table,
                      referencedTable: $$UserVehiclesTableReferences
                          ._userVehicleCostsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UserVehiclesTableReferences(
                            db,
                            table,
                            p0,
                          ).userVehicleCostsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'user_vehicle_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UserVehiclesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserVehiclesTable,
      UserVehicleRow,
      $$UserVehiclesTableFilterComposer,
      $$UserVehiclesTableOrderingComposer,
      $$UserVehiclesTableAnnotationComposer,
      $$UserVehiclesTableCreateCompanionBuilder,
      $$UserVehiclesTableUpdateCompanionBuilder,
      (UserVehicleRow, $$UserVehiclesTableReferences),
      UserVehicleRow,
      PrefetchHooks Function({bool userVehicleCostsRefs})
    >;
typedef $$UserVehicleCostsTableCreateCompanionBuilder =
    UserVehicleCostsCompanion Function({
      required String userVehicleId,
      required int annualKm,
      Value<String> shareBasis,
      Value<int?> insuranceCents,
      Value<int?> taxCents,
      Value<int?> maintenanceCents,
      Value<int?> tyresCents,
      Value<int?> repairsCents,
      Value<int?> loanCents,
      Value<int?> depreciationCents,
      Value<int?> parkingCents,
      Value<int?> otherCents,
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$UserVehicleCostsTableUpdateCompanionBuilder =
    UserVehicleCostsCompanion Function({
      Value<String> userVehicleId,
      Value<int> annualKm,
      Value<String> shareBasis,
      Value<int?> insuranceCents,
      Value<int?> taxCents,
      Value<int?> maintenanceCents,
      Value<int?> tyresCents,
      Value<int?> repairsCents,
      Value<int?> loanCents,
      Value<int?> depreciationCents,
      Value<int?> parkingCents,
      Value<int?> otherCents,
      Value<String> updatedAt,
      Value<int> rowid,
    });

final class $$UserVehicleCostsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $UserVehicleCostsTable,
          UserVehicleCostsRow
        > {
  $$UserVehicleCostsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UserVehiclesTable _userVehicleIdTable(_$AppDatabase db) => db
      .userVehicles
      .createAlias('user_vehicle_costs__user_vehicle_id__user_vehicles__id');

  $$UserVehiclesTableProcessedTableManager get userVehicleId {
    final $_column = $_itemColumn<String>('user_vehicle_id')!;

    final manager = $$UserVehiclesTableTableManager(
      $_db,
      $_db.userVehicles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userVehicleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$UserVehicleCostsTableFilterComposer
    extends Composer<_$AppDatabase, $UserVehicleCostsTable> {
  $$UserVehicleCostsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get annualKm => $composableBuilder(
    column: $table.annualKm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get shareBasis => $composableBuilder(
    column: $table.shareBasis,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get insuranceCents => $composableBuilder(
    column: $table.insuranceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get taxCents => $composableBuilder(
    column: $table.taxCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maintenanceCents => $composableBuilder(
    column: $table.maintenanceCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tyresCents => $composableBuilder(
    column: $table.tyresCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repairsCents => $composableBuilder(
    column: $table.repairsCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get loanCents => $composableBuilder(
    column: $table.loanCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get depreciationCents => $composableBuilder(
    column: $table.depreciationCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get parkingCents => $composableBuilder(
    column: $table.parkingCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get otherCents => $composableBuilder(
    column: $table.otherCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$UserVehiclesTableFilterComposer get userVehicleId {
    final $$UserVehiclesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userVehicleId,
      referencedTable: $db.userVehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserVehiclesTableFilterComposer(
            $db: $db,
            $table: $db.userVehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserVehicleCostsTableOrderingComposer
    extends Composer<_$AppDatabase, $UserVehicleCostsTable> {
  $$UserVehicleCostsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get annualKm => $composableBuilder(
    column: $table.annualKm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get shareBasis => $composableBuilder(
    column: $table.shareBasis,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get insuranceCents => $composableBuilder(
    column: $table.insuranceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get taxCents => $composableBuilder(
    column: $table.taxCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maintenanceCents => $composableBuilder(
    column: $table.maintenanceCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tyresCents => $composableBuilder(
    column: $table.tyresCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repairsCents => $composableBuilder(
    column: $table.repairsCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get loanCents => $composableBuilder(
    column: $table.loanCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get depreciationCents => $composableBuilder(
    column: $table.depreciationCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get parkingCents => $composableBuilder(
    column: $table.parkingCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get otherCents => $composableBuilder(
    column: $table.otherCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$UserVehiclesTableOrderingComposer get userVehicleId {
    final $$UserVehiclesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userVehicleId,
      referencedTable: $db.userVehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserVehiclesTableOrderingComposer(
            $db: $db,
            $table: $db.userVehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserVehicleCostsTableAnnotationComposer
    extends Composer<_$AppDatabase, $UserVehicleCostsTable> {
  $$UserVehicleCostsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get annualKm =>
      $composableBuilder(column: $table.annualKm, builder: (column) => column);

  GeneratedColumn<String> get shareBasis => $composableBuilder(
    column: $table.shareBasis,
    builder: (column) => column,
  );

  GeneratedColumn<int> get insuranceCents => $composableBuilder(
    column: $table.insuranceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get taxCents =>
      $composableBuilder(column: $table.taxCents, builder: (column) => column);

  GeneratedColumn<int> get maintenanceCents => $composableBuilder(
    column: $table.maintenanceCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tyresCents => $composableBuilder(
    column: $table.tyresCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repairsCents => $composableBuilder(
    column: $table.repairsCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get loanCents =>
      $composableBuilder(column: $table.loanCents, builder: (column) => column);

  GeneratedColumn<int> get depreciationCents => $composableBuilder(
    column: $table.depreciationCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get parkingCents => $composableBuilder(
    column: $table.parkingCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get otherCents => $composableBuilder(
    column: $table.otherCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$UserVehiclesTableAnnotationComposer get userVehicleId {
    final $$UserVehiclesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userVehicleId,
      referencedTable: $db.userVehicles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserVehiclesTableAnnotationComposer(
            $db: $db,
            $table: $db.userVehicles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$UserVehicleCostsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UserVehicleCostsTable,
          UserVehicleCostsRow,
          $$UserVehicleCostsTableFilterComposer,
          $$UserVehicleCostsTableOrderingComposer,
          $$UserVehicleCostsTableAnnotationComposer,
          $$UserVehicleCostsTableCreateCompanionBuilder,
          $$UserVehicleCostsTableUpdateCompanionBuilder,
          (UserVehicleCostsRow, $$UserVehicleCostsTableReferences),
          UserVehicleCostsRow,
          PrefetchHooks Function({bool userVehicleId})
        > {
  $$UserVehicleCostsTableTableManager(
    _$AppDatabase db,
    $UserVehicleCostsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserVehicleCostsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserVehicleCostsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserVehicleCostsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> userVehicleId = const Value.absent(),
                Value<int> annualKm = const Value.absent(),
                Value<String> shareBasis = const Value.absent(),
                Value<int?> insuranceCents = const Value.absent(),
                Value<int?> taxCents = const Value.absent(),
                Value<int?> maintenanceCents = const Value.absent(),
                Value<int?> tyresCents = const Value.absent(),
                Value<int?> repairsCents = const Value.absent(),
                Value<int?> loanCents = const Value.absent(),
                Value<int?> depreciationCents = const Value.absent(),
                Value<int?> parkingCents = const Value.absent(),
                Value<int?> otherCents = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UserVehicleCostsCompanion(
                userVehicleId: userVehicleId,
                annualKm: annualKm,
                shareBasis: shareBasis,
                insuranceCents: insuranceCents,
                taxCents: taxCents,
                maintenanceCents: maintenanceCents,
                tyresCents: tyresCents,
                repairsCents: repairsCents,
                loanCents: loanCents,
                depreciationCents: depreciationCents,
                parkingCents: parkingCents,
                otherCents: otherCents,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String userVehicleId,
                required int annualKm,
                Value<String> shareBasis = const Value.absent(),
                Value<int?> insuranceCents = const Value.absent(),
                Value<int?> taxCents = const Value.absent(),
                Value<int?> maintenanceCents = const Value.absent(),
                Value<int?> tyresCents = const Value.absent(),
                Value<int?> repairsCents = const Value.absent(),
                Value<int?> loanCents = const Value.absent(),
                Value<int?> depreciationCents = const Value.absent(),
                Value<int?> parkingCents = const Value.absent(),
                Value<int?> otherCents = const Value.absent(),
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => UserVehicleCostsCompanion.insert(
                userVehicleId: userVehicleId,
                annualKm: annualKm,
                shareBasis: shareBasis,
                insuranceCents: insuranceCents,
                taxCents: taxCents,
                maintenanceCents: maintenanceCents,
                tyresCents: tyresCents,
                repairsCents: repairsCents,
                loanCents: loanCents,
                depreciationCents: depreciationCents,
                parkingCents: parkingCents,
                otherCents: otherCents,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UserVehicleCostsTable, UserVehicleCostsRow>(
                    table,
                  ),
                  $$UserVehicleCostsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userVehicleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (userVehicleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.userVehicleId,
                        referencedTable: $$UserVehicleCostsTableReferences
                            ._userVehicleIdTable(db),
                        referencedColumn: $$UserVehicleCostsTableReferences
                            ._userVehicleIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$UserVehicleCostsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UserVehicleCostsTable,
      UserVehicleCostsRow,
      $$UserVehicleCostsTableFilterComposer,
      $$UserVehicleCostsTableOrderingComposer,
      $$UserVehicleCostsTableAnnotationComposer,
      $$UserVehicleCostsTableCreateCompanionBuilder,
      $$UserVehicleCostsTableUpdateCompanionBuilder,
      (UserVehicleCostsRow, $$UserVehicleCostsTableReferences),
      UserVehicleCostsRow,
      PrefetchHooks Function({bool userVehicleId})
    >;
typedef $$LocalRecurringExpensesTableCreateCompanionBuilder =
    LocalRecurringExpensesCompanion Function({
      required String id,
      required String groupId,
      required String title,
      required int amountCents,
      required String payersJson,
      required String splitMode,
      required String splitWeightsJson,
      Value<String?> category,
      required String frequency,
      required int intervalCount,
      required String startDate,
      Value<String?> endDate,
      Value<String?> lastGenerated,
      Value<bool> paused,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$LocalRecurringExpensesTableUpdateCompanionBuilder =
    LocalRecurringExpensesCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> title,
      Value<int> amountCents,
      Value<String> payersJson,
      Value<String> splitMode,
      Value<String> splitWeightsJson,
      Value<String?> category,
      Value<String> frequency,
      Value<int> intervalCount,
      Value<String> startDate,
      Value<String?> endDate,
      Value<String?> lastGenerated,
      Value<bool> paused,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalRecurringExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $LocalRecurringExpensesTable> {
  $$LocalRecurringExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payersJson => $composableBuilder(
    column: $table.payersJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitMode => $composableBuilder(
    column: $table.splitMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get splitWeightsJson => $composableBuilder(
    column: $table.splitWeightsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intervalCount => $composableBuilder(
    column: $table.intervalCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastGenerated => $composableBuilder(
    column: $table.lastGenerated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalRecurringExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalRecurringExpensesTable> {
  $$LocalRecurringExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payersJson => $composableBuilder(
    column: $table.payersJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitMode => $composableBuilder(
    column: $table.splitMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get splitWeightsJson => $composableBuilder(
    column: $table.splitWeightsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intervalCount => $composableBuilder(
    column: $table.intervalCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastGenerated => $composableBuilder(
    column: $table.lastGenerated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get paused => $composableBuilder(
    column: $table.paused,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalRecurringExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalRecurringExpensesTable> {
  $$LocalRecurringExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payersJson => $composableBuilder(
    column: $table.payersJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get splitMode =>
      $composableBuilder(column: $table.splitMode, builder: (column) => column);

  GeneratedColumn<String> get splitWeightsJson => $composableBuilder(
    column: $table.splitWeightsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get intervalCount => $composableBuilder(
    column: $table.intervalCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get lastGenerated => $composableBuilder(
    column: $table.lastGenerated,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get paused =>
      $composableBuilder(column: $table.paused, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalRecurringExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalRecurringExpensesTable,
          RecurringExpenseRow,
          $$LocalRecurringExpensesTableFilterComposer,
          $$LocalRecurringExpensesTableOrderingComposer,
          $$LocalRecurringExpensesTableAnnotationComposer,
          $$LocalRecurringExpensesTableCreateCompanionBuilder,
          $$LocalRecurringExpensesTableUpdateCompanionBuilder,
          (
            RecurringExpenseRow,
            BaseReferences<
              _$AppDatabase,
              $LocalRecurringExpensesTable,
              RecurringExpenseRow
            >,
          ),
          RecurringExpenseRow,
          PrefetchHooks Function()
        > {
  $$LocalRecurringExpensesTableTableManager(
    _$AppDatabase db,
    $LocalRecurringExpensesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalRecurringExpensesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalRecurringExpensesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalRecurringExpensesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String> payersJson = const Value.absent(),
                Value<String> splitMode = const Value.absent(),
                Value<String> splitWeightsJson = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int> intervalCount = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<String?> lastGenerated = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalRecurringExpensesCompanion(
                id: id,
                groupId: groupId,
                title: title,
                amountCents: amountCents,
                payersJson: payersJson,
                splitMode: splitMode,
                splitWeightsJson: splitWeightsJson,
                category: category,
                frequency: frequency,
                intervalCount: intervalCount,
                startDate: startDate,
                endDate: endDate,
                lastGenerated: lastGenerated,
                paused: paused,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String title,
                required int amountCents,
                required String payersJson,
                required String splitMode,
                required String splitWeightsJson,
                Value<String?> category = const Value.absent(),
                required String frequency,
                required int intervalCount,
                required String startDate,
                Value<String?> endDate = const Value.absent(),
                Value<String?> lastGenerated = const Value.absent(),
                Value<bool> paused = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalRecurringExpensesCompanion.insert(
                id: id,
                groupId: groupId,
                title: title,
                amountCents: amountCents,
                payersJson: payersJson,
                splitMode: splitMode,
                splitWeightsJson: splitWeightsJson,
                category: category,
                frequency: frequency,
                intervalCount: intervalCount,
                startDate: startDate,
                endDate: endDate,
                lastGenerated: lastGenerated,
                paused: paused,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $LocalRecurringExpensesTable,
                    RecurringExpenseRow
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalRecurringExpensesTable,
                    RecurringExpenseRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalRecurringExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalRecurringExpensesTable,
      RecurringExpenseRow,
      $$LocalRecurringExpensesTableFilterComposer,
      $$LocalRecurringExpensesTableOrderingComposer,
      $$LocalRecurringExpensesTableAnnotationComposer,
      $$LocalRecurringExpensesTableCreateCompanionBuilder,
      $$LocalRecurringExpensesTableUpdateCompanionBuilder,
      (
        RecurringExpenseRow,
        BaseReferences<
          _$AppDatabase,
          $LocalRecurringExpensesTable,
          RecurringExpenseRow
        >,
      ),
      RecurringExpenseRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db, _db.groups);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db, _db.members);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$ExpensePayersTableTableManager get expensePayers =>
      $$ExpensePayersTableTableManager(_db, _db.expensePayers);
  $$ExpenseSharesTableTableManager get expenseShares =>
      $$ExpenseSharesTableTableManager(_db, _db.expenseShares);
  $$SettlementsTableTableManager get settlements =>
      $$SettlementsTableTableManager(_db, _db.settlements);
  $$LocalMemberBankTableTableManager get localMemberBank =>
      $$LocalMemberBankTableTableManager(_db, _db.localMemberBank);
  $$LocalOutboxTableTableManager get localOutbox =>
      $$LocalOutboxTableTableManager(_db, _db.localOutbox);
  $$LocalDriverPromptsTableTableManager get localDriverPrompts =>
      $$LocalDriverPromptsTableTableManager(_db, _db.localDriverPrompts);
  $$LocalPlacesTableTableManager get localPlaces =>
      $$LocalPlacesTableTableManager(_db, _db.localPlaces);
  $$VehiclesTableTableManager get vehicles =>
      $$VehiclesTableTableManager(_db, _db.vehicles);
  $$RideTemplatesTableTableManager get rideTemplates =>
      $$RideTemplatesTableTableManager(_db, _db.rideTemplates);
  $$RidesTableTableManager get rides =>
      $$RidesTableTableManager(_db, _db.rides);
  $$ExpenseRevisionsTableTableManager get expenseRevisions =>
      $$ExpenseRevisionsTableTableManager(_db, _db.expenseRevisions);
  $$LocalGroupSyncTableTableManager get localGroupSync =>
      $$LocalGroupSyncTableTableManager(_db, _db.localGroupSync);
  $$LocalSyncCursorTableTableManager get localSyncCursor =>
      $$LocalSyncCursorTableTableManager(_db, _db.localSyncCursor);
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db, _db.localSettings);
  $$ProfileTableTableManager get profile =>
      $$ProfileTableTableManager(_db, _db.profile);
  $$LocalProfileBankTableTableManager get localProfileBank =>
      $$LocalProfileBankTableTableManager(_db, _db.localProfileBank);
  $$UserVehiclesTableTableManager get userVehicles =>
      $$UserVehiclesTableTableManager(_db, _db.userVehicles);
  $$UserVehicleCostsTableTableManager get userVehicleCosts =>
      $$UserVehicleCostsTableTableManager(_db, _db.userVehicleCosts);
  $$LocalRecurringExpensesTableTableManager get localRecurringExpenses =>
      $$LocalRecurringExpensesTableTableManager(
        _db,
        _db.localRecurringExpenses,
      );
}
