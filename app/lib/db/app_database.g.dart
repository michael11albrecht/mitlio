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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
        DriftSqlType.string,
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
  final String createdAt;
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
    map['created_at'] = Variable<String>(createdAt);
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
      createdAt: serializer.fromJson<String>(json['createdAt']),
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
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  GroupRow copyWith({
    String? id,
    String? name,
    String? currency,
    String? createdBy,
    String? createdAt,
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
  final Value<String> createdAt;
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
    required String createdAt,
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
    Expression<String>? createdAt,
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
    Value<String>? createdAt,
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
      map['created_at'] = Variable<String>(createdAt.value);
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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
        DriftSqlType.string,
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

  /// Hybrid logical clock string.
  final String createdAt;

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
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<String>(createdAt);
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
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      paypalMe: serializer.fromJson<String?>(json['paypalMe']),
      userId: serializer.fromJson<String?>(json['userId']),
      ibanHint: serializer.fromJson<String?>(json['ibanHint']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'paypalMe': serializer.toJson<String?>(paypalMe),
      'userId': serializer.toJson<String?>(userId),
      'ibanHint': serializer.toJson<String?>(ibanHint),
    };
  }

  MemberRow copyWith({
    String? id,
    String? groupId,
    String? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    int? position,
    Value<String?> paypalMe = const Value.absent(),
    Value<String?> userId = const Value.absent(),
    Value<String?> ibanHint = const Value.absent(),
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
          ..write('ibanHint: $ibanHint')
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
          other.ibanHint == this.ibanHint);
}

class MembersCompanion extends UpdateCompanion<MemberRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<int> position;
  final Value<String?> paypalMe;
  final Value<String?> userId;
  final Value<String?> ibanHint;
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
    this.rowid = const Value.absent(),
  });
  MembersCompanion.insert({
    required String id,
    required String groupId,
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String name,
    required int position,
    this.paypalMe = const Value.absent(),
    this.userId = const Value.absent(),
    this.ibanHint = const Value.absent(),
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
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<int>? position,
    Expression<String>? paypalMe,
    Expression<String>? userId,
    Expression<String>? ibanHint,
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
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembersCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<int>? position,
    Value<String?>? paypalMe,
    Value<String?>? userId,
    Value<String?>? ibanHint,
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
      map['created_at'] = Variable<String>(createdAt.value);
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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
        DriftSqlType.string,
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

  /// Hybrid logical clock string.
  final String createdAt;

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
    map['created_at'] = Variable<String>(createdAt);
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
      createdAt: serializer.fromJson<String>(json['createdAt']),
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
      'createdAt': serializer.toJson<String>(createdAt),
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
    String? createdAt,
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
  final Value<String> createdAt;
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
    required String createdAt,
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
    Expression<String>? createdAt,
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
    Value<String>? createdAt,
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
      map['created_at'] = Variable<String>(createdAt.value);
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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {expenseId, memberId},
  ];
  @override
  ExpensePayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpensePayerRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
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
  /// UUIDv7 generated on the client.
  final String id;
  final String groupId;

  /// Hybrid logical clock string.
  final String createdAt;

  /// Hybrid logical clock string.
  final String updatedAt;

  /// Soft delete marker; null while the row is live.
  final DateTime? deletedAt;
  final String expenseId;
  final String memberId;
  final int paidCents;
  const ExpensePayerRow({
    required this.id,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.expenseId,
    required this.memberId,
    required this.paidCents,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['paid_cents'] = Variable<int>(paidCents);
    return map;
  }

  ExpensePayersCompanion toCompanion(bool nullToAbsent) {
    return ExpensePayersCompanion(
      id: Value(id),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
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
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      expenseId: serializer.fromJson<String>(json['expenseId']),
      memberId: serializer.fromJson<String>(json['memberId']),
      paidCents: serializer.fromJson<int>(json['paidCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'expenseId': serializer.toJson<String>(expenseId),
      'memberId': serializer.toJson<String>(memberId),
      'paidCents': serializer.toJson<int>(paidCents),
    };
  }

  ExpensePayerRow copyWith({
    String? id,
    String? groupId,
    String? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? expenseId,
    String? memberId,
    int? paidCents,
  }) => ExpensePayerRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    expenseId: expenseId ?? this.expenseId,
    memberId: memberId ?? this.memberId,
    paidCents: paidCents ?? this.paidCents,
  );
  ExpensePayerRow copyWithCompanion(ExpensePayersCompanion data) {
    return ExpensePayerRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      expenseId: data.expenseId.present ? data.expenseId.value : this.expenseId,
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      paidCents: data.paidCents.present ? data.paidCents.value : this.paidCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExpensePayerRow(')
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('paidCents: $paidCents')
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
    expenseId,
    memberId,
    paidCents,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpensePayerRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.paidCents == this.paidCents);
}

class ExpensePayersCompanion extends UpdateCompanion<ExpensePayerRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<int> paidCents;
  final Value<int> rowid;
  const ExpensePayersCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.paidCents = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpensePayersCompanion.insert({
    required String id,
    required String groupId,
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String expenseId,
    required String memberId,
    required int paidCents,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       expenseId = Value(expenseId),
       memberId = Value(memberId),
       paidCents = Value(paidCents);
  static Insertable<ExpensePayerRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<int>? paidCents,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (paidCents != null) 'paid_cents': paidCents,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpensePayersCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<int>? paidCents,
    Value<int>? rowid,
  }) {
    return ExpensePayersCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      expenseId: expenseId ?? this.expenseId,
      memberId: memberId ?? this.memberId,
      paidCents: paidCents ?? this.paidCents,
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
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
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
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    id,
    groupId,
    createdAt,
    updatedAt,
    deletedAt,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {expenseId, memberId},
  ];
  @override
  ExpenseShareRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExpenseShareRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
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
  /// UUIDv7 generated on the client.
  final String id;
  final String groupId;

  /// Hybrid logical clock string.
  final String createdAt;

  /// Hybrid logical clock string.
  final String updatedAt;

  /// Soft delete marker; null while the row is live.
  final DateTime? deletedAt;
  final String expenseId;
  final String memberId;
  final int shareCents;

  /// Weight / basis points for share and percent modes (re-editing).
  final int weight;
  const ExpenseShareRow({
    required this.id,
    required this.groupId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.expenseId,
    required this.memberId,
    required this.shareCents,
    required this.weight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['group_id'] = Variable<String>(groupId);
    map['created_at'] = Variable<String>(createdAt);
    map['updated_at'] = Variable<String>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['expense_id'] = Variable<String>(expenseId);
    map['member_id'] = Variable<String>(memberId);
    map['share_cents'] = Variable<int>(shareCents);
    map['weight'] = Variable<int>(weight);
    return map;
  }

  ExpenseSharesCompanion toCompanion(bool nullToAbsent) {
    return ExpenseSharesCompanion(
      id: Value(id),
      groupId: Value(groupId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
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
      id: serializer.fromJson<String>(json['id']),
      groupId: serializer.fromJson<String>(json['groupId']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
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
      'id': serializer.toJson<String>(id),
      'groupId': serializer.toJson<String>(groupId),
      'createdAt': serializer.toJson<String>(createdAt),
      'updatedAt': serializer.toJson<String>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'expenseId': serializer.toJson<String>(expenseId),
      'memberId': serializer.toJson<String>(memberId),
      'shareCents': serializer.toJson<int>(shareCents),
      'weight': serializer.toJson<int>(weight),
    };
  }

  ExpenseShareRow copyWith({
    String? id,
    String? groupId,
    String? createdAt,
    String? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? expenseId,
    String? memberId,
    int? shareCents,
    int? weight,
  }) => ExpenseShareRow(
    id: id ?? this.id,
    groupId: groupId ?? this.groupId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    expenseId: expenseId ?? this.expenseId,
    memberId: memberId ?? this.memberId,
    shareCents: shareCents ?? this.shareCents,
    weight: weight ?? this.weight,
  );
  ExpenseShareRow copyWithCompanion(ExpenseSharesCompanion data) {
    return ExpenseShareRow(
      id: data.id.present ? data.id.value : this.id,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
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
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('expenseId: $expenseId, ')
          ..write('memberId: $memberId, ')
          ..write('shareCents: $shareCents, ')
          ..write('weight: $weight')
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
    expenseId,
    memberId,
    shareCents,
    weight,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExpenseShareRow &&
          other.id == this.id &&
          other.groupId == this.groupId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.expenseId == this.expenseId &&
          other.memberId == this.memberId &&
          other.shareCents == this.shareCents &&
          other.weight == this.weight);
}

class ExpenseSharesCompanion extends UpdateCompanion<ExpenseShareRow> {
  final Value<String> id;
  final Value<String> groupId;
  final Value<String> createdAt;
  final Value<String> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> expenseId;
  final Value<String> memberId;
  final Value<int> shareCents;
  final Value<int> weight;
  final Value<int> rowid;
  const ExpenseSharesCompanion({
    this.id = const Value.absent(),
    this.groupId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.expenseId = const Value.absent(),
    this.memberId = const Value.absent(),
    this.shareCents = const Value.absent(),
    this.weight = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExpenseSharesCompanion.insert({
    required String id,
    required String groupId,
    required String createdAt,
    required String updatedAt,
    this.deletedAt = const Value.absent(),
    required String expenseId,
    required String memberId,
    required int shareCents,
    required int weight,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       groupId = Value(groupId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       expenseId = Value(expenseId),
       memberId = Value(memberId),
       shareCents = Value(shareCents),
       weight = Value(weight);
  static Insertable<ExpenseShareRow> custom({
    Expression<String>? id,
    Expression<String>? groupId,
    Expression<String>? createdAt,
    Expression<String>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? expenseId,
    Expression<String>? memberId,
    Expression<int>? shareCents,
    Expression<int>? weight,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (groupId != null) 'group_id': groupId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (expenseId != null) 'expense_id': expenseId,
      if (memberId != null) 'member_id': memberId,
      if (shareCents != null) 'share_cents': shareCents,
      if (weight != null) 'weight': weight,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExpenseSharesCompanion copyWith({
    Value<String>? id,
    Value<String>? groupId,
    Value<String>? createdAt,
    Value<String>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? expenseId,
    Value<String>? memberId,
    Value<int>? shareCents,
    Value<int>? weight,
    Value<int>? rowid,
  }) {
    return ExpenseSharesCompanion(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<String>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
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
          ..write('id: $id, ')
          ..write('groupId: $groupId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
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
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
        DriftSqlType.string,
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

  /// Hybrid logical clock string.
  final String createdAt;

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
    map['created_at'] = Variable<String>(createdAt);
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
      createdAt: serializer.fromJson<String>(json['createdAt']),
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
      'createdAt': serializer.toJson<String>(createdAt),
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
    String? createdAt,
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
  final Value<String> createdAt;
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
    required String createdAt,
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
    Expression<String>? createdAt,
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
    Value<String>? createdAt,
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
      map['created_at'] = Variable<String>(createdAt.value);
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
  List<GeneratedColumn> get $columns => [memberId, iban, updatedAt];
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
  final String updatedAt;
  const LocalMemberBankRow({
    required this.memberId,
    required this.iban,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['member_id'] = Variable<String>(memberId);
    map['iban'] = Variable<String>(iban);
    map['updated_at'] = Variable<String>(updatedAt);
    return map;
  }

  LocalMemberBankCompanion toCompanion(bool nullToAbsent) {
    return LocalMemberBankCompanion(
      memberId: Value(memberId),
      iban: Value(iban),
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
      updatedAt: serializer.fromJson<String>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'memberId': serializer.toJson<String>(memberId),
      'iban': serializer.toJson<String>(iban),
      'updatedAt': serializer.toJson<String>(updatedAt),
    };
  }

  LocalMemberBankRow copyWith({
    String? memberId,
    String? iban,
    String? updatedAt,
  }) => LocalMemberBankRow(
    memberId: memberId ?? this.memberId,
    iban: iban ?? this.iban,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMemberBankRow copyWithCompanion(LocalMemberBankCompanion data) {
    return LocalMemberBankRow(
      memberId: data.memberId.present ? data.memberId.value : this.memberId,
      iban: data.iban.present ? data.iban.value : this.iban,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMemberBankRow(')
          ..write('memberId: $memberId, ')
          ..write('iban: $iban, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(memberId, iban, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMemberBankRow &&
          other.memberId == this.memberId &&
          other.iban == this.iban &&
          other.updatedAt == this.updatedAt);
}

class LocalMemberBankCompanion extends UpdateCompanion<LocalMemberBankRow> {
  final Value<String> memberId;
  final Value<String> iban;
  final Value<String> updatedAt;
  final Value<int> rowid;
  const LocalMemberBankCompanion({
    this.memberId = const Value.absent(),
    this.iban = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMemberBankCompanion.insert({
    required String memberId,
    required String iban,
    required String updatedAt,
    this.rowid = const Value.absent(),
  }) : memberId = Value(memberId),
       iban = Value(iban),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMemberBankRow> custom({
    Expression<String>? memberId,
    Expression<String>? iban,
    Expression<String>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (memberId != null) 'member_id': memberId,
      if (iban != null) 'iban': iban,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMemberBankCompanion copyWith({
    Value<String>? memberId,
    Value<String>? iban,
    Value<String>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalMemberBankCompanion(
      memberId: memberId ?? this.memberId,
      iban: iban ?? this.iban,
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
  @override
  List<GeneratedColumn> get $columns => [
    seq,
    entity,
    entityId,
    op,
    payload,
    attempts,
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
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {seq};
  @override
  LocalOutboxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOutboxRow(
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
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
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
    );
  }

  @override
  $LocalOutboxTable createAlias(String alias) {
    return $LocalOutboxTable(attachedDatabase, alias);
  }
}

class LocalOutboxRow extends DataClass implements Insertable<LocalOutboxRow> {
  final int seq;
  final String entity;
  final String entityId;
  final String op;
  final String payload;
  final int attempts;
  const LocalOutboxRow({
    required this.seq,
    required this.entity,
    required this.entityId,
    required this.op,
    required this.payload,
    required this.attempts,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['seq'] = Variable<int>(seq);
    map['entity'] = Variable<String>(entity);
    map['entity_id'] = Variable<String>(entityId);
    map['op'] = Variable<String>(op);
    map['payload'] = Variable<String>(payload);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  LocalOutboxCompanion toCompanion(bool nullToAbsent) {
    return LocalOutboxCompanion(
      seq: Value(seq),
      entity: Value(entity),
      entityId: Value(entityId),
      op: Value(op),
      payload: Value(payload),
      attempts: Value(attempts),
    );
  }

  factory LocalOutboxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOutboxRow(
      seq: serializer.fromJson<int>(json['seq']),
      entity: serializer.fromJson<String>(json['entity']),
      entityId: serializer.fromJson<String>(json['entityId']),
      op: serializer.fromJson<String>(json['op']),
      payload: serializer.fromJson<String>(json['payload']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'seq': serializer.toJson<int>(seq),
      'entity': serializer.toJson<String>(entity),
      'entityId': serializer.toJson<String>(entityId),
      'op': serializer.toJson<String>(op),
      'payload': serializer.toJson<String>(payload),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  LocalOutboxRow copyWith({
    int? seq,
    String? entity,
    String? entityId,
    String? op,
    String? payload,
    int? attempts,
  }) => LocalOutboxRow(
    seq: seq ?? this.seq,
    entity: entity ?? this.entity,
    entityId: entityId ?? this.entityId,
    op: op ?? this.op,
    payload: payload ?? this.payload,
    attempts: attempts ?? this.attempts,
  );
  LocalOutboxRow copyWithCompanion(LocalOutboxCompanion data) {
    return LocalOutboxRow(
      seq: data.seq.present ? data.seq.value : this.seq,
      entity: data.entity.present ? data.entity.value : this.entity,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      op: data.op.present ? data.op.value : this.op,
      payload: data.payload.present ? data.payload.value : this.payload,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOutboxRow(')
          ..write('seq: $seq, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(seq, entity, entityId, op, payload, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOutboxRow &&
          other.seq == this.seq &&
          other.entity == this.entity &&
          other.entityId == this.entityId &&
          other.op == this.op &&
          other.payload == this.payload &&
          other.attempts == this.attempts);
}

class LocalOutboxCompanion extends UpdateCompanion<LocalOutboxRow> {
  final Value<int> seq;
  final Value<String> entity;
  final Value<String> entityId;
  final Value<String> op;
  final Value<String> payload;
  final Value<int> attempts;
  const LocalOutboxCompanion({
    this.seq = const Value.absent(),
    this.entity = const Value.absent(),
    this.entityId = const Value.absent(),
    this.op = const Value.absent(),
    this.payload = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  LocalOutboxCompanion.insert({
    this.seq = const Value.absent(),
    required String entity,
    required String entityId,
    required String op,
    required String payload,
    this.attempts = const Value.absent(),
  }) : entity = Value(entity),
       entityId = Value(entityId),
       op = Value(op),
       payload = Value(payload);
  static Insertable<LocalOutboxRow> custom({
    Expression<int>? seq,
    Expression<String>? entity,
    Expression<String>? entityId,
    Expression<String>? op,
    Expression<String>? payload,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (seq != null) 'seq': seq,
      if (entity != null) 'entity': entity,
      if (entityId != null) 'entity_id': entityId,
      if (op != null) 'op': op,
      if (payload != null) 'payload': payload,
      if (attempts != null) 'attempts': attempts,
    });
  }

  LocalOutboxCompanion copyWith({
    Value<int>? seq,
    Value<String>? entity,
    Value<String>? entityId,
    Value<String>? op,
    Value<String>? payload,
    Value<int>? attempts,
  }) {
    return LocalOutboxCompanion(
      seq: seq ?? this.seq,
      entity: entity ?? this.entity,
      entityId: entityId ?? this.entityId,
      op: op ?? this.op,
      payload: payload ?? this.payload,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
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
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOutboxCompanion(')
          ..write('seq: $seq, ')
          ..write('entity: $entity, ')
          ..write('entityId: $entityId, ')
          ..write('op: $op, ')
          ..write('payload: $payload, ')
          ..write('attempts: $attempts')
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
  late final GroupsDao groupsDao = GroupsDao(this as AppDatabase);
  late final MembersDao membersDao = MembersDao(this as AppDatabase);
  late final ExpensesDao expensesDao = ExpensesDao(this as AppDatabase);
  late final SettlementsDao settlementsDao = SettlementsDao(
    this as AppDatabase,
  );
  late final LocalMemberBankDao localMemberBankDao = LocalMemberBankDao(
    this as AppDatabase,
  );
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
    membersGroupId,
    expensesGroupId,
    expensePayersExpenseId,
    expensePayersGroupId,
    expensePayersMemberId,
    expenseSharesExpenseId,
    expenseSharesGroupId,
    expenseSharesMemberId,
    settlementsGroupId,
  ];
}

typedef $$GroupsTableCreateCompanionBuilder = GroupsCompanion Function({
  required String id,
  required String name,
  required String currency,
  required String createdBy,
  required String createdAt,
  required String updatedAt,
  Value<DateTime?> deletedAt,
  Value<int> rowid,
});
typedef $$GroupsTableUpdateCompanionBuilder = GroupsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> currency,
  Value<String> createdBy,
  Value<String> createdAt,
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

  ColumnFilters<String> get createdAt => $composableBuilder(
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

  ColumnOrderings<String> get createdAt => $composableBuilder(
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

  GeneratedColumn<String> get createdAt =>
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
                Value<String> createdAt = const Value.absent(),
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
                required String createdAt,
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (membersRefs) db.members,
                    if (expensesRefs) db.expenses,
                    if (expensePayersRefs) db.expensePayers,
                    if (expenseSharesRefs) db.expenseShares,
                    if (settlementsRefs) db.settlements,
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
      })
    >;
typedef $$MembersTableCreateCompanionBuilder = MembersCompanion Function({
  required String id,
  required String groupId,
  required String createdAt,
  required String updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  required int position,
  Value<String?> paypalMe,
  Value<String?> userId,
  Value<String?> ibanHint,
  Value<int> rowid,
});
typedef $$MembersTableUpdateCompanionBuilder = MembersCompanion Function({
  Value<String> id,
  Value<String> groupId,
  Value<String> createdAt,
  Value<String> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<int> position,
  Value<String?> paypalMe,
  Value<String?> userId,
  Value<String?> ibanHint,
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

  ColumnFilters<String> get createdAt => $composableBuilder(
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

  ColumnOrderings<String> get createdAt => $composableBuilder(
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

  GeneratedColumn<String> get createdAt =>
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
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> paypalMe = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> ibanHint = const Value.absent(),
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
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required int position,
                Value<String?> paypalMe = const Value.absent(),
                Value<String?> userId = const Value.absent(),
                Value<String?> ibanHint = const Value.absent(),
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensePayersRefs) db.expensePayers,
                    if (expenseSharesRefs) db.expenseShares,
                    if (sentSettlements) db.settlements,
                    if (receivedSettlements) db.settlements,
                    if (localMemberBankRefs) db.localMemberBank,
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
      })
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  required String id,
  required String groupId,
  required String createdAt,
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
  Value<String> createdAt,
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

  ColumnFilters<String> get createdAt => $composableBuilder(
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

  ColumnOrderings<String> get createdAt => $composableBuilder(
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

  GeneratedColumn<String> get createdAt =>
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
                Value<String> createdAt = const Value.absent(),
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
                required String createdAt,
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (expensePayersRefs) db.expensePayers,
                    if (expenseSharesRefs) db.expenseShares,
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
      })
    >;
typedef $$ExpensePayersTableCreateCompanionBuilder =
    ExpensePayersCompanion Function({
      required String id,
      required String groupId,
      required String createdAt,
      required String updatedAt,
      Value<DateTime?> deletedAt,
      required String expenseId,
      required String memberId,
      required int paidCents,
      Value<int> rowid,
    });
typedef $$ExpensePayersTableUpdateCompanionBuilder =
    ExpensePayersCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<DateTime?> deletedAt,
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
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
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
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

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
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> paidCents = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpensePayersCompanion(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                expenseId: expenseId,
                memberId: memberId,
                paidCents: paidCents,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String expenseId,
                required String memberId,
                required int paidCents,
                Value<int> rowid = const Value.absent(),
              }) => ExpensePayersCompanion.insert(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
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
      required String id,
      required String groupId,
      required String createdAt,
      required String updatedAt,
      Value<DateTime?> deletedAt,
      required String expenseId,
      required String memberId,
      required int shareCents,
      required int weight,
      Value<int> rowid,
    });
typedef $$ExpenseSharesTableUpdateCompanionBuilder =
    ExpenseSharesCompanion Function({
      Value<String> id,
      Value<String> groupId,
      Value<String> createdAt,
      Value<String> updatedAt,
      Value<DateTime?> deletedAt,
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
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
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
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
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
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

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
                Value<String> id = const Value.absent(),
                Value<String> groupId = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
                Value<String> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> expenseId = const Value.absent(),
                Value<String> memberId = const Value.absent(),
                Value<int> shareCents = const Value.absent(),
                Value<int> weight = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExpenseSharesCompanion(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                expenseId: expenseId,
                memberId: memberId,
                shareCents: shareCents,
                weight: weight,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String groupId,
                required String createdAt,
                required String updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String expenseId,
                required String memberId,
                required int shareCents,
                required int weight,
                Value<int> rowid = const Value.absent(),
              }) => ExpenseSharesCompanion.insert(
                id: id,
                groupId: groupId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
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
      required String createdAt,
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
      Value<String> createdAt,
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

  ColumnFilters<String> get createdAt => $composableBuilder(
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

  ColumnOrderings<String> get createdAt => $composableBuilder(
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

  GeneratedColumn<String> get createdAt =>
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
                Value<String> createdAt = const Value.absent(),
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
                required String createdAt,
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
      required String updatedAt,
      Value<int> rowid,
    });
typedef $$LocalMemberBankTableUpdateCompanionBuilder =
    LocalMemberBankCompanion Function({
      Value<String> memberId,
      Value<String> iban,
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
                Value<String> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMemberBankCompanion(
                memberId: memberId,
                iban: iban,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String memberId,
                required String iban,
                required String updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalMemberBankCompanion.insert(
                memberId: memberId,
                iban: iban,
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
      required String entity,
      required String entityId,
      required String op,
      required String payload,
      Value<int> attempts,
    });
typedef $$LocalOutboxTableUpdateCompanionBuilder =
    LocalOutboxCompanion Function({
      Value<int> seq,
      Value<String> entity,
      Value<String> entityId,
      Value<String> op,
      Value<String> payload,
      Value<int> attempts,
    });

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

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );
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

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );
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

  GeneratedColumn<String> get entity =>
      $composableBuilder(column: $table.entity, builder: (column) => column);

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get op =>
      $composableBuilder(column: $table.op, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
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
          (
            LocalOutboxRow,
            BaseReferences<_$AppDatabase, $LocalOutboxTable, LocalOutboxRow>,
          ),
          LocalOutboxRow,
          PrefetchHooks Function()
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
                Value<String> entity = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> op = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> attempts = const Value.absent(),
              }) => LocalOutboxCompanion(
                seq: seq,
                entity: entity,
                entityId: entityId,
                op: op,
                payload: payload,
                attempts: attempts,
              ),
          createCompanionCallback:
              ({
                Value<int> seq = const Value.absent(),
                required String entity,
                required String entityId,
                required String op,
                required String payload,
                Value<int> attempts = const Value.absent(),
              }) => LocalOutboxCompanion.insert(
                seq: seq,
                entity: entity,
                entityId: entityId,
                op: op,
                payload: payload,
                attempts: attempts,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocalOutboxTable, LocalOutboxRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocalOutboxTable,
                    LocalOutboxRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
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
      (
        LocalOutboxRow,
        BaseReferences<_$AppDatabase, $LocalOutboxTable, LocalOutboxRow>,
      ),
      LocalOutboxRow,
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
}
