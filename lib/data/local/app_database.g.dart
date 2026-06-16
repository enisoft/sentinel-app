// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OccurrencesTable extends Occurrences
    with TableInfo<$OccurrencesTable, Occurrence> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<DateTime> occurredAt = GeneratedColumn<DateTime>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta(
    'resolvedAt',
  );
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _observableIdMeta = const VerificationMeta(
    'observableId',
  );
  @override
  late final GeneratedColumn<String> observableId = GeneratedColumn<String>(
    'observable_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
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
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('local_saved'),
      ).withConverter<SyncState>($OccurrencesTable.$convertersyncState);
  @override
  late final GeneratedColumnWithTypeConverter<SyncPhase?, String> failedPhase =
      GeneratedColumn<String>(
        'failed_phase',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SyncPhase?>($OccurrencesTable.$converterfailedPhasen);
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdLocalAtMeta = const VerificationMeta(
    'createdLocalAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdLocalAt =
      GeneratedColumn<DateTime>(
        'created_local_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _mediaUploadedAtMeta = const VerificationMeta(
    'mediaUploadedAt',
  );
  @override
  late final GeneratedColumn<DateTime> mediaUploadedAt =
      GeneratedColumn<DateTime>(
        'media_uploaded_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _failedReasonMeta = const VerificationMeta(
    'failedReason',
  );
  @override
  late final GeneratedColumn<String> failedReason = GeneratedColumn<String>(
    'failed_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    status,
    priority,
    location,
    latitude,
    longitude,
    occurredAt,
    resolvedAt,
    observableId,
    categoryId,
    createdAt,
    updatedAt,
    syncState,
    failedPhase,
    retryCount,
    createdLocalAt,
    mediaUploadedAt,
    syncedAt,
    lastAttemptAt,
    failedReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Occurrence> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('resolved_at')) {
      context.handle(
        _resolvedAtMeta,
        resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta),
      );
    }
    if (data.containsKey('observable_id')) {
      context.handle(
        _observableIdMeta,
        observableId.isAcceptableOrUnknown(
          data['observable_id']!,
          _observableIdMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
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
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_local_at')) {
      context.handle(
        _createdLocalAtMeta,
        createdLocalAt.isAcceptableOrUnknown(
          data['created_local_at']!,
          _createdLocalAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdLocalAtMeta);
    }
    if (data.containsKey('media_uploaded_at')) {
      context.handle(
        _mediaUploadedAtMeta,
        mediaUploadedAt.isAcceptableOrUnknown(
          data['media_uploaded_at']!,
          _mediaUploadedAtMeta,
        ),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('failed_reason')) {
      context.handle(
        _failedReasonMeta,
        failedReason.isAcceptableOrUnknown(
          data['failed_reason']!,
          _failedReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Occurrence map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Occurrence(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred_at'],
      )!,
      resolvedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resolved_at'],
      ),
      observableId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}observable_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      ),
      syncState: $OccurrencesTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      failedPhase: $OccurrencesTable.$converterfailedPhasen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}failed_phase'],
        ),
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdLocalAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_local_at'],
      )!,
      mediaUploadedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}media_uploaded_at'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      failedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failed_reason'],
      ),
    );
  }

  @override
  $OccurrencesTable createAlias(String alias) {
    return $OccurrencesTable(attachedDatabase, alias);
  }

  static TypeConverter<SyncState, String> $convertersyncState =
      const SyncStateConverter();
  static TypeConverter<SyncPhase, String> $converterfailedPhase =
      const SyncPhaseConverter();
  static TypeConverter<SyncPhase?, String?> $converterfailedPhasen =
      NullAwareTypeConverter.wrap($converterfailedPhase);
}

class Occurrence extends DataClass implements Insertable<Occurrence> {
  final String id;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? location;
  final double? latitude;
  final double? longitude;
  final DateTime occurredAt;
  final DateTime? resolvedAt;
  final String? observableId;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final SyncState syncState;
  final SyncPhase? failedPhase;
  final int retryCount;
  final DateTime createdLocalAt;
  final DateTime? mediaUploadedAt;
  final DateTime? syncedAt;
  final DateTime? lastAttemptAt;
  final String? failedReason;
  const Occurrence({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.location,
    this.latitude,
    this.longitude,
    required this.occurredAt,
    this.resolvedAt,
    this.observableId,
    this.categoryId,
    required this.createdAt,
    this.updatedAt,
    required this.syncState,
    this.failedPhase,
    required this.retryCount,
    required this.createdLocalAt,
    this.mediaUploadedAt,
    this.syncedAt,
    this.lastAttemptAt,
    this.failedReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<String>(priority);
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    map['occurred_at'] = Variable<DateTime>(occurredAt);
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    if (!nullToAbsent || observableId != null) {
      map['observable_id'] = Variable<String>(observableId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<String>(categoryId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<DateTime>(updatedAt);
    }
    {
      map['sync_state'] = Variable<String>(
        $OccurrencesTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || failedPhase != null) {
      map['failed_phase'] = Variable<String>(
        $OccurrencesTable.$converterfailedPhasen.toSql(failedPhase),
      );
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_local_at'] = Variable<DateTime>(createdLocalAt);
    if (!nullToAbsent || mediaUploadedAt != null) {
      map['media_uploaded_at'] = Variable<DateTime>(mediaUploadedAt);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || failedReason != null) {
      map['failed_reason'] = Variable<String>(failedReason);
    }
    return map;
  }

  OccurrencesCompanion toCompanion(bool nullToAbsent) {
    return OccurrencesCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      status: Value(status),
      priority: Value(priority),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      occurredAt: Value(occurredAt),
      resolvedAt: resolvedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAt),
      observableId: observableId == null && nullToAbsent
          ? const Value.absent()
          : Value(observableId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      createdAt: Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      syncState: Value(syncState),
      failedPhase: failedPhase == null && nullToAbsent
          ? const Value.absent()
          : Value(failedPhase),
      retryCount: Value(retryCount),
      createdLocalAt: Value(createdLocalAt),
      mediaUploadedAt: mediaUploadedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(mediaUploadedAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      failedReason: failedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failedReason),
    );
  }

  factory Occurrence.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Occurrence(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<String>(json['priority']),
      location: serializer.fromJson<String?>(json['location']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      occurredAt: serializer.fromJson<DateTime>(json['occurredAt']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      observableId: serializer.fromJson<String?>(json['observableId']),
      categoryId: serializer.fromJson<String?>(json['categoryId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime?>(json['updatedAt']),
      syncState: serializer.fromJson<SyncState>(json['syncState']),
      failedPhase: serializer.fromJson<SyncPhase?>(json['failedPhase']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdLocalAt: serializer.fromJson<DateTime>(json['createdLocalAt']),
      mediaUploadedAt: serializer.fromJson<DateTime?>(json['mediaUploadedAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      failedReason: serializer.fromJson<String?>(json['failedReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<String>(priority),
      'location': serializer.toJson<String?>(location),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'occurredAt': serializer.toJson<DateTime>(occurredAt),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'observableId': serializer.toJson<String?>(observableId),
      'categoryId': serializer.toJson<String?>(categoryId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime?>(updatedAt),
      'syncState': serializer.toJson<SyncState>(syncState),
      'failedPhase': serializer.toJson<SyncPhase?>(failedPhase),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdLocalAt': serializer.toJson<DateTime>(createdLocalAt),
      'mediaUploadedAt': serializer.toJson<DateTime?>(mediaUploadedAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'failedReason': serializer.toJson<String?>(failedReason),
    };
  }

  Occurrence copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    String? priority,
    Value<String?> location = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    DateTime? occurredAt,
    Value<DateTime?> resolvedAt = const Value.absent(),
    Value<String?> observableId = const Value.absent(),
    Value<String?> categoryId = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> updatedAt = const Value.absent(),
    SyncState? syncState,
    Value<SyncPhase?> failedPhase = const Value.absent(),
    int? retryCount,
    DateTime? createdLocalAt,
    Value<DateTime?> mediaUploadedAt = const Value.absent(),
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> failedReason = const Value.absent(),
  }) => Occurrence(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    location: location.present ? location.value : this.location,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    occurredAt: occurredAt ?? this.occurredAt,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    observableId: observableId.present ? observableId.value : this.observableId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    syncState: syncState ?? this.syncState,
    failedPhase: failedPhase.present ? failedPhase.value : this.failedPhase,
    retryCount: retryCount ?? this.retryCount,
    createdLocalAt: createdLocalAt ?? this.createdLocalAt,
    mediaUploadedAt: mediaUploadedAt.present
        ? mediaUploadedAt.value
        : this.mediaUploadedAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    failedReason: failedReason.present ? failedReason.value : this.failedReason,
  );
  Occurrence copyWithCompanion(OccurrencesCompanion data) {
    return Occurrence(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      location: data.location.present ? data.location.value : this.location,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      resolvedAt: data.resolvedAt.present
          ? data.resolvedAt.value
          : this.resolvedAt,
      observableId: data.observableId.present
          ? data.observableId.value
          : this.observableId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      failedPhase: data.failedPhase.present
          ? data.failedPhase.value
          : this.failedPhase,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdLocalAt: data.createdLocalAt.present
          ? data.createdLocalAt.value
          : this.createdLocalAt,
      mediaUploadedAt: data.mediaUploadedAt.present
          ? data.mediaUploadedAt.value
          : this.mediaUploadedAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      failedReason: data.failedReason.present
          ? data.failedReason.value
          : this.failedReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Occurrence(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('observableId: $observableId, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('failedPhase: $failedPhase, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdLocalAt: $createdLocalAt, ')
          ..write('mediaUploadedAt: $mediaUploadedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('failedReason: $failedReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    description,
    status,
    priority,
    location,
    latitude,
    longitude,
    occurredAt,
    resolvedAt,
    observableId,
    categoryId,
    createdAt,
    updatedAt,
    syncState,
    failedPhase,
    retryCount,
    createdLocalAt,
    mediaUploadedAt,
    syncedAt,
    lastAttemptAt,
    failedReason,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Occurrence &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.location == this.location &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.occurredAt == this.occurredAt &&
          other.resolvedAt == this.resolvedAt &&
          other.observableId == this.observableId &&
          other.categoryId == this.categoryId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.syncState == this.syncState &&
          other.failedPhase == this.failedPhase &&
          other.retryCount == this.retryCount &&
          other.createdLocalAt == this.createdLocalAt &&
          other.mediaUploadedAt == this.mediaUploadedAt &&
          other.syncedAt == this.syncedAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.failedReason == this.failedReason);
}

class OccurrencesCompanion extends UpdateCompanion<Occurrence> {
  final Value<String> id;
  final Value<String> title;
  final Value<String> description;
  final Value<String> status;
  final Value<String> priority;
  final Value<String?> location;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<DateTime> occurredAt;
  final Value<DateTime?> resolvedAt;
  final Value<String?> observableId;
  final Value<String?> categoryId;
  final Value<DateTime> createdAt;
  final Value<DateTime?> updatedAt;
  final Value<SyncState> syncState;
  final Value<SyncPhase?> failedPhase;
  final Value<int> retryCount;
  final Value<DateTime> createdLocalAt;
  final Value<DateTime?> mediaUploadedAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> failedReason;
  final Value<int> rowid;
  const OccurrencesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.observableId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.failedPhase = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdLocalAt = const Value.absent(),
    this.mediaUploadedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.failedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccurrencesCompanion.insert({
    required String id,
    required String title,
    required String description,
    required String status,
    required String priority,
    this.location = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    required DateTime occurredAt,
    this.resolvedAt = const Value.absent(),
    this.observableId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required DateTime createdAt,
    this.updatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.failedPhase = const Value.absent(),
    this.retryCount = const Value.absent(),
    required DateTime createdLocalAt,
    this.mediaUploadedAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.failedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       description = Value(description),
       status = Value(status),
       priority = Value(priority),
       occurredAt = Value(occurredAt),
       createdAt = Value(createdAt),
       createdLocalAt = Value(createdLocalAt);
  static Insertable<Occurrence> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? status,
    Expression<String>? priority,
    Expression<String>? location,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<DateTime>? occurredAt,
    Expression<DateTime>? resolvedAt,
    Expression<String>? observableId,
    Expression<String>? categoryId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? syncState,
    Expression<String>? failedPhase,
    Expression<int>? retryCount,
    Expression<DateTime>? createdLocalAt,
    Expression<DateTime>? mediaUploadedAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? failedReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (location != null) 'location': location,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (observableId != null) 'observable_id': observableId,
      if (categoryId != null) 'category_id': categoryId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (failedPhase != null) 'failed_phase': failedPhase,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdLocalAt != null) 'created_local_at': createdLocalAt,
      if (mediaUploadedAt != null) 'media_uploaded_at': mediaUploadedAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (failedReason != null) 'failed_reason': failedReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccurrencesCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String>? description,
    Value<String>? status,
    Value<String>? priority,
    Value<String?>? location,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<DateTime>? occurredAt,
    Value<DateTime?>? resolvedAt,
    Value<String?>? observableId,
    Value<String?>? categoryId,
    Value<DateTime>? createdAt,
    Value<DateTime?>? updatedAt,
    Value<SyncState>? syncState,
    Value<SyncPhase?>? failedPhase,
    Value<int>? retryCount,
    Value<DateTime>? createdLocalAt,
    Value<DateTime?>? mediaUploadedAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? failedReason,
    Value<int>? rowid,
  }) {
    return OccurrencesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      occurredAt: occurredAt ?? this.occurredAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      observableId: observableId ?? this.observableId,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncState: syncState ?? this.syncState,
      failedPhase: failedPhase ?? this.failedPhase,
      retryCount: retryCount ?? this.retryCount,
      createdLocalAt: createdLocalAt ?? this.createdLocalAt,
      mediaUploadedAt: mediaUploadedAt ?? this.mediaUploadedAt,
      syncedAt: syncedAt ?? this.syncedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      failedReason: failedReason ?? this.failedReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<DateTime>(occurredAt.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (observableId.present) {
      map['observable_id'] = Variable<String>(observableId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $OccurrencesTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (failedPhase.present) {
      map['failed_phase'] = Variable<String>(
        $OccurrencesTable.$converterfailedPhasen.toSql(failedPhase.value),
      );
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdLocalAt.present) {
      map['created_local_at'] = Variable<DateTime>(createdLocalAt.value);
    }
    if (mediaUploadedAt.present) {
      map['media_uploaded_at'] = Variable<DateTime>(mediaUploadedAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (failedReason.present) {
      map['failed_reason'] = Variable<String>(failedReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('location: $location, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('observableId: $observableId, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('failedPhase: $failedPhase, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdLocalAt: $createdLocalAt, ')
          ..write('mediaUploadedAt: $mediaUploadedAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('failedReason: $failedReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OccurrenceMediaTable extends OccurrenceMedia
    with TableInfo<$OccurrenceMediaTable, OccurrenceMediaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrenceMediaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _occurrenceIdMeta = const VerificationMeta(
    'occurrenceId',
  );
  @override
  late final GeneratedColumn<String> occurrenceId = GeneratedColumn<String>(
    'occurrence_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES occurrences (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  @override
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sizeBytesMeta = const VerificationMeta(
    'sizeBytes',
  );
  @override
  late final GeneratedColumn<int> sizeBytes = GeneratedColumn<int>(
    'size_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _originalNameMeta = const VerificationMeta(
    'originalName',
  );
  @override
  late final GeneratedColumn<String> originalName = GeneratedColumn<String>(
    'original_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    occurrenceId,
    mediaType,
    localPath,
    remotePath,
    mimeType,
    sizeBytes,
    durationSeconds,
    sortOrder,
    originalName,
    contentHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrence_media';
  @override
  VerificationContext validateIntegrity(
    Insertable<OccurrenceMediaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('occurrence_id')) {
      context.handle(
        _occurrenceIdMeta,
        occurrenceId.isAcceptableOrUnknown(
          data['occurrence_id']!,
          _occurrenceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurrenceIdMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    } else if (isInserting) {
      context.missing(_localPathMeta);
    }
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('size_bytes')) {
      context.handle(
        _sizeBytesMeta,
        sizeBytes.isAcceptableOrUnknown(data['size_bytes']!, _sizeBytesMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('original_name')) {
      context.handle(
        _originalNameMeta,
        originalName.isAcceptableOrUnknown(
          data['original_name']!,
          _originalNameMeta,
        ),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OccurrenceMediaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OccurrenceMediaData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      occurrenceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}occurrence_id'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      )!,
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      ),
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      sizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size_bytes'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      originalName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_name'],
      ),
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
    );
  }

  @override
  $OccurrenceMediaTable createAlias(String alias) {
    return $OccurrenceMediaTable(attachedDatabase, alias);
  }
}

class OccurrenceMediaData extends DataClass
    implements Insertable<OccurrenceMediaData> {
  final String id;
  final String occurrenceId;
  final String mediaType;
  final String localPath;
  final String? remotePath;
  final String mimeType;
  final int? sizeBytes;
  final int? durationSeconds;
  final int sortOrder;
  final String? originalName;
  final String? contentHash;
  const OccurrenceMediaData({
    required this.id,
    required this.occurrenceId,
    required this.mediaType,
    required this.localPath,
    this.remotePath,
    required this.mimeType,
    this.sizeBytes,
    this.durationSeconds,
    required this.sortOrder,
    this.originalName,
    this.contentHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['occurrence_id'] = Variable<String>(occurrenceId);
    map['media_type'] = Variable<String>(mediaType);
    map['local_path'] = Variable<String>(localPath);
    if (!nullToAbsent || remotePath != null) {
      map['remote_path'] = Variable<String>(remotePath);
    }
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || sizeBytes != null) {
      map['size_bytes'] = Variable<int>(sizeBytes);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || originalName != null) {
      map['original_name'] = Variable<String>(originalName);
    }
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    return map;
  }

  OccurrenceMediaCompanion toCompanion(bool nullToAbsent) {
    return OccurrenceMediaCompanion(
      id: Value(id),
      occurrenceId: Value(occurrenceId),
      mediaType: Value(mediaType),
      localPath: Value(localPath),
      remotePath: remotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(remotePath),
      mimeType: Value(mimeType),
      sizeBytes: sizeBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(sizeBytes),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      sortOrder: Value(sortOrder),
      originalName: originalName == null && nullToAbsent
          ? const Value.absent()
          : Value(originalName),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
    );
  }

  factory OccurrenceMediaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OccurrenceMediaData(
      id: serializer.fromJson<String>(json['id']),
      occurrenceId: serializer.fromJson<String>(json['occurrenceId']),
      mediaType: serializer.fromJson<String>(json['mediaType']),
      localPath: serializer.fromJson<String>(json['localPath']),
      remotePath: serializer.fromJson<String?>(json['remotePath']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      sizeBytes: serializer.fromJson<int?>(json['sizeBytes']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      originalName: serializer.fromJson<String?>(json['originalName']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'occurrenceId': serializer.toJson<String>(occurrenceId),
      'mediaType': serializer.toJson<String>(mediaType),
      'localPath': serializer.toJson<String>(localPath),
      'remotePath': serializer.toJson<String?>(remotePath),
      'mimeType': serializer.toJson<String>(mimeType),
      'sizeBytes': serializer.toJson<int?>(sizeBytes),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'originalName': serializer.toJson<String?>(originalName),
      'contentHash': serializer.toJson<String?>(contentHash),
    };
  }

  OccurrenceMediaData copyWith({
    String? id,
    String? occurrenceId,
    String? mediaType,
    String? localPath,
    Value<String?> remotePath = const Value.absent(),
    String? mimeType,
    Value<int?> sizeBytes = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    int? sortOrder,
    Value<String?> originalName = const Value.absent(),
    Value<String?> contentHash = const Value.absent(),
  }) => OccurrenceMediaData(
    id: id ?? this.id,
    occurrenceId: occurrenceId ?? this.occurrenceId,
    mediaType: mediaType ?? this.mediaType,
    localPath: localPath ?? this.localPath,
    remotePath: remotePath.present ? remotePath.value : this.remotePath,
    mimeType: mimeType ?? this.mimeType,
    sizeBytes: sizeBytes.present ? sizeBytes.value : this.sizeBytes,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    sortOrder: sortOrder ?? this.sortOrder,
    originalName: originalName.present ? originalName.value : this.originalName,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
  );
  OccurrenceMediaData copyWithCompanion(OccurrenceMediaCompanion data) {
    return OccurrenceMediaData(
      id: data.id.present ? data.id.value : this.id,
      occurrenceId: data.occurrenceId.present
          ? data.occurrenceId.value
          : this.occurrenceId,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      sizeBytes: data.sizeBytes.present ? data.sizeBytes.value : this.sizeBytes,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      originalName: data.originalName.present
          ? data.originalName.value
          : this.originalName,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceMediaData(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('mediaType: $mediaType, ')
          ..write('localPath: $localPath, ')
          ..write('remotePath: $remotePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('originalName: $originalName, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    occurrenceId,
    mediaType,
    localPath,
    remotePath,
    mimeType,
    sizeBytes,
    durationSeconds,
    sortOrder,
    originalName,
    contentHash,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OccurrenceMediaData &&
          other.id == this.id &&
          other.occurrenceId == this.occurrenceId &&
          other.mediaType == this.mediaType &&
          other.localPath == this.localPath &&
          other.remotePath == this.remotePath &&
          other.mimeType == this.mimeType &&
          other.sizeBytes == this.sizeBytes &&
          other.durationSeconds == this.durationSeconds &&
          other.sortOrder == this.sortOrder &&
          other.originalName == this.originalName &&
          other.contentHash == this.contentHash);
}

class OccurrenceMediaCompanion extends UpdateCompanion<OccurrenceMediaData> {
  final Value<String> id;
  final Value<String> occurrenceId;
  final Value<String> mediaType;
  final Value<String> localPath;
  final Value<String?> remotePath;
  final Value<String> mimeType;
  final Value<int?> sizeBytes;
  final Value<int?> durationSeconds;
  final Value<int> sortOrder;
  final Value<String?> originalName;
  final Value<String?> contentHash;
  final Value<int> rowid;
  const OccurrenceMediaCompanion({
    this.id = const Value.absent(),
    this.occurrenceId = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.localPath = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.sizeBytes = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.originalName = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccurrenceMediaCompanion.insert({
    required String id,
    required String occurrenceId,
    required String mediaType,
    required String localPath,
    this.remotePath = const Value.absent(),
    required String mimeType,
    this.sizeBytes = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.originalName = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       occurrenceId = Value(occurrenceId),
       mediaType = Value(mediaType),
       localPath = Value(localPath),
       mimeType = Value(mimeType);
  static Insertable<OccurrenceMediaData> custom({
    Expression<String>? id,
    Expression<String>? occurrenceId,
    Expression<String>? mediaType,
    Expression<String>? localPath,
    Expression<String>? remotePath,
    Expression<String>? mimeType,
    Expression<int>? sizeBytes,
    Expression<int>? durationSeconds,
    Expression<int>? sortOrder,
    Expression<String>? originalName,
    Expression<String>? contentHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (occurrenceId != null) 'occurrence_id': occurrenceId,
      if (mediaType != null) 'media_type': mediaType,
      if (localPath != null) 'local_path': localPath,
      if (remotePath != null) 'remote_path': remotePath,
      if (mimeType != null) 'mime_type': mimeType,
      if (sizeBytes != null) 'size_bytes': sizeBytes,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (originalName != null) 'original_name': originalName,
      if (contentHash != null) 'content_hash': contentHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccurrenceMediaCompanion copyWith({
    Value<String>? id,
    Value<String>? occurrenceId,
    Value<String>? mediaType,
    Value<String>? localPath,
    Value<String?>? remotePath,
    Value<String>? mimeType,
    Value<int?>? sizeBytes,
    Value<int?>? durationSeconds,
    Value<int>? sortOrder,
    Value<String?>? originalName,
    Value<String?>? contentHash,
    Value<int>? rowid,
  }) {
    return OccurrenceMediaCompanion(
      id: id ?? this.id,
      occurrenceId: occurrenceId ?? this.occurrenceId,
      mediaType: mediaType ?? this.mediaType,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sortOrder: sortOrder ?? this.sortOrder,
      originalName: originalName ?? this.originalName,
      contentHash: contentHash ?? this.contentHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (occurrenceId.present) {
      map['occurrence_id'] = Variable<String>(occurrenceId.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (sizeBytes.present) {
      map['size_bytes'] = Variable<int>(sizeBytes.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (originalName.present) {
      map['original_name'] = Variable<String>(originalName.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceMediaCompanion(')
          ..write('id: $id, ')
          ..write('occurrenceId: $occurrenceId, ')
          ..write('mediaType: $mediaType, ')
          ..write('localPath: $localPath, ')
          ..write('remotePath: $remotePath, ')
          ..write('mimeType: $mimeType, ')
          ..write('sizeBytes: $sizeBytes, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('originalName: $originalName, ')
          ..write('contentHash: $contentHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns with TableInfo<$CheckInsTable, CheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accuracyMeta = const VerificationMeta(
    'accuracy',
  );
  @override
  late final GeneratedColumn<double> accuracy = GeneratedColumn<double>(
    'accuracy',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _capturedAtMeta = const VerificationMeta(
    'capturedAt',
  );
  @override
  late final GeneratedColumn<DateTime> capturedAt = GeneratedColumn<DateTime>(
    'captured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SyncState, String> syncState =
      GeneratedColumn<String>(
        'sync_state',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('local_saved'),
      ).withConverter<SyncState>($CheckInsTable.$convertersyncState);
  @override
  late final GeneratedColumnWithTypeConverter<SyncPhase?, String> failedPhase =
      GeneratedColumn<String>(
        'failed_phase',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      ).withConverter<SyncPhase?>($CheckInsTable.$converterfailedPhasen);
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdLocalAtMeta = const VerificationMeta(
    'createdLocalAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdLocalAt =
      GeneratedColumn<DateTime>(
        'created_local_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttemptAt =
      GeneratedColumn<DateTime>(
        'last_attempt_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _failedReasonMeta = const VerificationMeta(
    'failedReason',
  );
  @override
  late final GeneratedColumn<String> failedReason = GeneratedColumn<String>(
    'failed_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    latitude,
    longitude,
    accuracy,
    capturedAt,
    note,
    syncState,
    failedPhase,
    retryCount,
    createdLocalAt,
    syncedAt,
    lastAttemptAt,
    failedReason,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy')) {
      context.handle(
        _accuracyMeta,
        accuracy.isAcceptableOrUnknown(data['accuracy']!, _accuracyMeta),
      );
    } else if (isInserting) {
      context.missing(_accuracyMeta);
    }
    if (data.containsKey('captured_at')) {
      context.handle(
        _capturedAtMeta,
        capturedAt.isAcceptableOrUnknown(data['captured_at']!, _capturedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_capturedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('created_local_at')) {
      context.handle(
        _createdLocalAtMeta,
        createdLocalAt.isAcceptableOrUnknown(
          data['created_local_at']!,
          _createdLocalAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdLocalAtMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('failed_reason')) {
      context.handle(
        _failedReasonMeta,
        failedReason.isAcceptableOrUnknown(
          data['failed_reason']!,
          _failedReasonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckIn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      )!,
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      )!,
      accuracy: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}accuracy'],
      )!,
      capturedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}captured_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      syncState: $CheckInsTable.$convertersyncState.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}sync_state'],
        )!,
      ),
      failedPhase: $CheckInsTable.$converterfailedPhasen.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}failed_phase'],
        ),
      ),
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      createdLocalAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_local_at'],
      )!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt_at'],
      ),
      failedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failed_reason'],
      ),
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }

  static TypeConverter<SyncState, String> $convertersyncState =
      const SyncStateConverter();
  static TypeConverter<SyncPhase, String> $converterfailedPhase =
      const SyncPhaseConverter();
  static TypeConverter<SyncPhase?, String?> $converterfailedPhasen =
      NullAwareTypeConverter.wrap($converterfailedPhase);
}

class CheckIn extends DataClass implements Insertable<CheckIn> {
  final String id;
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime capturedAt;
  final String? note;
  final SyncState syncState;
  final SyncPhase? failedPhase;
  final int retryCount;
  final DateTime createdLocalAt;
  final DateTime? syncedAt;
  final DateTime? lastAttemptAt;
  final String? failedReason;
  const CheckIn({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
    this.note,
    required this.syncState,
    this.failedPhase,
    required this.retryCount,
    required this.createdLocalAt,
    this.syncedAt,
    this.lastAttemptAt,
    this.failedReason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['accuracy'] = Variable<double>(accuracy);
    map['captured_at'] = Variable<DateTime>(capturedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    {
      map['sync_state'] = Variable<String>(
        $CheckInsTable.$convertersyncState.toSql(syncState),
      );
    }
    if (!nullToAbsent || failedPhase != null) {
      map['failed_phase'] = Variable<String>(
        $CheckInsTable.$converterfailedPhasen.toSql(failedPhase),
      );
    }
    map['retry_count'] = Variable<int>(retryCount);
    map['created_local_at'] = Variable<DateTime>(createdLocalAt);
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<DateTime>(syncedAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt);
    }
    if (!nullToAbsent || failedReason != null) {
      map['failed_reason'] = Variable<String>(failedReason);
    }
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(
      id: Value(id),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracy: Value(accuracy),
      capturedAt: Value(capturedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      syncState: Value(syncState),
      failedPhase: failedPhase == null && nullToAbsent
          ? const Value.absent()
          : Value(failedPhase),
      retryCount: Value(retryCount),
      createdLocalAt: Value(createdLocalAt),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      failedReason: failedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(failedReason),
    );
  }

  factory CheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckIn(
      id: serializer.fromJson<String>(json['id']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracy: serializer.fromJson<double>(json['accuracy']),
      capturedAt: serializer.fromJson<DateTime>(json['capturedAt']),
      note: serializer.fromJson<String?>(json['note']),
      syncState: serializer.fromJson<SyncState>(json['syncState']),
      failedPhase: serializer.fromJson<SyncPhase?>(json['failedPhase']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      createdLocalAt: serializer.fromJson<DateTime>(json['createdLocalAt']),
      syncedAt: serializer.fromJson<DateTime?>(json['syncedAt']),
      lastAttemptAt: serializer.fromJson<DateTime?>(json['lastAttemptAt']),
      failedReason: serializer.fromJson<String?>(json['failedReason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracy': serializer.toJson<double>(accuracy),
      'capturedAt': serializer.toJson<DateTime>(capturedAt),
      'note': serializer.toJson<String?>(note),
      'syncState': serializer.toJson<SyncState>(syncState),
      'failedPhase': serializer.toJson<SyncPhase?>(failedPhase),
      'retryCount': serializer.toJson<int>(retryCount),
      'createdLocalAt': serializer.toJson<DateTime>(createdLocalAt),
      'syncedAt': serializer.toJson<DateTime?>(syncedAt),
      'lastAttemptAt': serializer.toJson<DateTime?>(lastAttemptAt),
      'failedReason': serializer.toJson<String?>(failedReason),
    };
  }

  CheckIn copyWith({
    String? id,
    double? latitude,
    double? longitude,
    double? accuracy,
    DateTime? capturedAt,
    Value<String?> note = const Value.absent(),
    SyncState? syncState,
    Value<SyncPhase?> failedPhase = const Value.absent(),
    int? retryCount,
    DateTime? createdLocalAt,
    Value<DateTime?> syncedAt = const Value.absent(),
    Value<DateTime?> lastAttemptAt = const Value.absent(),
    Value<String?> failedReason = const Value.absent(),
  }) => CheckIn(
    id: id ?? this.id,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    accuracy: accuracy ?? this.accuracy,
    capturedAt: capturedAt ?? this.capturedAt,
    note: note.present ? note.value : this.note,
    syncState: syncState ?? this.syncState,
    failedPhase: failedPhase.present ? failedPhase.value : this.failedPhase,
    retryCount: retryCount ?? this.retryCount,
    createdLocalAt: createdLocalAt ?? this.createdLocalAt,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    failedReason: failedReason.present ? failedReason.value : this.failedReason,
  );
  CheckIn copyWithCompanion(CheckInsCompanion data) {
    return CheckIn(
      id: data.id.present ? data.id.value : this.id,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracy: data.accuracy.present ? data.accuracy.value : this.accuracy,
      capturedAt: data.capturedAt.present
          ? data.capturedAt.value
          : this.capturedAt,
      note: data.note.present ? data.note.value : this.note,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      failedPhase: data.failedPhase.present
          ? data.failedPhase.value
          : this.failedPhase,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      createdLocalAt: data.createdLocalAt.present
          ? data.createdLocalAt.value
          : this.createdLocalAt,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      failedReason: data.failedReason.present
          ? data.failedReason.value
          : this.failedReason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckIn(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('note: $note, ')
          ..write('syncState: $syncState, ')
          ..write('failedPhase: $failedPhase, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdLocalAt: $createdLocalAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('failedReason: $failedReason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    latitude,
    longitude,
    accuracy,
    capturedAt,
    note,
    syncState,
    failedPhase,
    retryCount,
    createdLocalAt,
    syncedAt,
    lastAttemptAt,
    failedReason,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckIn &&
          other.id == this.id &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracy == this.accuracy &&
          other.capturedAt == this.capturedAt &&
          other.note == this.note &&
          other.syncState == this.syncState &&
          other.failedPhase == this.failedPhase &&
          other.retryCount == this.retryCount &&
          other.createdLocalAt == this.createdLocalAt &&
          other.syncedAt == this.syncedAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.failedReason == this.failedReason);
}

class CheckInsCompanion extends UpdateCompanion<CheckIn> {
  final Value<String> id;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double> accuracy;
  final Value<DateTime> capturedAt;
  final Value<String?> note;
  final Value<SyncState> syncState;
  final Value<SyncPhase?> failedPhase;
  final Value<int> retryCount;
  final Value<DateTime> createdLocalAt;
  final Value<DateTime?> syncedAt;
  final Value<DateTime?> lastAttemptAt;
  final Value<String?> failedReason;
  final Value<int> rowid;
  const CheckInsCompanion({
    this.id = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracy = const Value.absent(),
    this.capturedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.syncState = const Value.absent(),
    this.failedPhase = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.createdLocalAt = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.failedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheckInsCompanion.insert({
    required String id,
    required double latitude,
    required double longitude,
    required double accuracy,
    required DateTime capturedAt,
    this.note = const Value.absent(),
    this.syncState = const Value.absent(),
    this.failedPhase = const Value.absent(),
    this.retryCount = const Value.absent(),
    required DateTime createdLocalAt,
    this.syncedAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.failedReason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       latitude = Value(latitude),
       longitude = Value(longitude),
       accuracy = Value(accuracy),
       capturedAt = Value(capturedAt),
       createdLocalAt = Value(createdLocalAt);
  static Insertable<CheckIn> custom({
    Expression<String>? id,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracy,
    Expression<DateTime>? capturedAt,
    Expression<String>? note,
    Expression<String>? syncState,
    Expression<String>? failedPhase,
    Expression<int>? retryCount,
    Expression<DateTime>? createdLocalAt,
    Expression<DateTime>? syncedAt,
    Expression<DateTime>? lastAttemptAt,
    Expression<String>? failedReason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (capturedAt != null) 'captured_at': capturedAt,
      if (note != null) 'note': note,
      if (syncState != null) 'sync_state': syncState,
      if (failedPhase != null) 'failed_phase': failedPhase,
      if (retryCount != null) 'retry_count': retryCount,
      if (createdLocalAt != null) 'created_local_at': createdLocalAt,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (failedReason != null) 'failed_reason': failedReason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheckInsCompanion copyWith({
    Value<String>? id,
    Value<double>? latitude,
    Value<double>? longitude,
    Value<double>? accuracy,
    Value<DateTime>? capturedAt,
    Value<String?>? note,
    Value<SyncState>? syncState,
    Value<SyncPhase?>? failedPhase,
    Value<int>? retryCount,
    Value<DateTime>? createdLocalAt,
    Value<DateTime?>? syncedAt,
    Value<DateTime?>? lastAttemptAt,
    Value<String?>? failedReason,
    Value<int>? rowid,
  }) {
    return CheckInsCompanion(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      capturedAt: capturedAt ?? this.capturedAt,
      note: note ?? this.note,
      syncState: syncState ?? this.syncState,
      failedPhase: failedPhase ?? this.failedPhase,
      retryCount: retryCount ?? this.retryCount,
      createdLocalAt: createdLocalAt ?? this.createdLocalAt,
      syncedAt: syncedAt ?? this.syncedAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      failedReason: failedReason ?? this.failedReason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracy.present) {
      map['accuracy'] = Variable<double>(accuracy.value);
    }
    if (capturedAt.present) {
      map['captured_at'] = Variable<DateTime>(capturedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(
        $CheckInsTable.$convertersyncState.toSql(syncState.value),
      );
    }
    if (failedPhase.present) {
      map['failed_phase'] = Variable<String>(
        $CheckInsTable.$converterfailedPhasen.toSql(failedPhase.value),
      );
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (createdLocalAt.present) {
      map['created_local_at'] = Variable<DateTime>(createdLocalAt.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<DateTime>(lastAttemptAt.value);
    }
    if (failedReason.present) {
      map['failed_reason'] = Variable<String>(failedReason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('id: $id, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracy: $accuracy, ')
          ..write('capturedAt: $capturedAt, ')
          ..write('note: $note, ')
          ..write('syncState: $syncState, ')
          ..write('failedPhase: $failedPhase, ')
          ..write('retryCount: $retryCount, ')
          ..write('createdLocalAt: $createdLocalAt, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('failedReason: $failedReason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OccurrencesTable occurrences = $OccurrencesTable(this);
  late final $OccurrenceMediaTable occurrenceMedia = $OccurrenceMediaTable(
    this,
  );
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    occurrences,
    occurrenceMedia,
    checkIns,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'occurrences',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('occurrence_media', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$OccurrencesTableCreateCompanionBuilder =
    OccurrencesCompanion Function({
      required String id,
      required String title,
      required String description,
      required String status,
      required String priority,
      Value<String?> location,
      Value<double?> latitude,
      Value<double?> longitude,
      required DateTime occurredAt,
      Value<DateTime?> resolvedAt,
      Value<String?> observableId,
      Value<String?> categoryId,
      required DateTime createdAt,
      Value<DateTime?> updatedAt,
      Value<SyncState> syncState,
      Value<SyncPhase?> failedPhase,
      Value<int> retryCount,
      required DateTime createdLocalAt,
      Value<DateTime?> mediaUploadedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> failedReason,
      Value<int> rowid,
    });
typedef $$OccurrencesTableUpdateCompanionBuilder =
    OccurrencesCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String> description,
      Value<String> status,
      Value<String> priority,
      Value<String?> location,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<DateTime> occurredAt,
      Value<DateTime?> resolvedAt,
      Value<String?> observableId,
      Value<String?> categoryId,
      Value<DateTime> createdAt,
      Value<DateTime?> updatedAt,
      Value<SyncState> syncState,
      Value<SyncPhase?> failedPhase,
      Value<int> retryCount,
      Value<DateTime> createdLocalAt,
      Value<DateTime?> mediaUploadedAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> failedReason,
      Value<int> rowid,
    });

final class $$OccurrencesTableReferences
    extends BaseReferences<_$AppDatabase, $OccurrencesTable, Occurrence> {
  $$OccurrencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OccurrenceMediaTable, List<OccurrenceMediaData>>
  _occurrenceMediaRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.occurrenceMedia,
    aliasName: $_aliasNameGenerator(
      db.occurrences.id,
      db.occurrenceMedia.occurrenceId,
    ),
  );

  $$OccurrenceMediaTableProcessedTableManager get occurrenceMediaRefs {
    final manager = $$OccurrenceMediaTableTableManager(
      $_db,
      $_db.occurrenceMedia,
    ).filter((f) => f.occurrenceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _occurrenceMediaRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$OccurrencesTableFilterComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableFilterComposer({
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

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get observableId => $composableBuilder(
    column: $table.observableId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SyncPhase?, SyncPhase, String>
  get failedPhase => $composableBuilder(
    column: $table.failedPhase,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdLocalAt => $composableBuilder(
    column: $table.createdLocalAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get mediaUploadedAt => $composableBuilder(
    column: $table.mediaUploadedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failedReason => $composableBuilder(
    column: $table.failedReason,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> occurrenceMediaRefs(
    Expression<bool> Function($$OccurrenceMediaTableFilterComposer f) f,
  ) {
    final $$OccurrenceMediaTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrenceMedia,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrenceMediaTableFilterComposer(
            $db: $db,
            $table: $db.occurrenceMedia,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OccurrencesTableOrderingComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableOrderingComposer({
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

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get observableId => $composableBuilder(
    column: $table.observableId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failedPhase => $composableBuilder(
    column: $table.failedPhase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdLocalAt => $composableBuilder(
    column: $table.createdLocalAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get mediaUploadedAt => $composableBuilder(
    column: $table.mediaUploadedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failedReason => $composableBuilder(
    column: $table.failedReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OccurrencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<DateTime> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get resolvedAt => $composableBuilder(
    column: $table.resolvedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get observableId => $composableBuilder(
    column: $table.observableId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoryId => $composableBuilder(
    column: $table.categoryId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncPhase?, String> get failedPhase =>
      $composableBuilder(
        column: $table.failedPhase,
        builder: (column) => column,
      );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdLocalAt => $composableBuilder(
    column: $table.createdLocalAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get mediaUploadedAt => $composableBuilder(
    column: $table.mediaUploadedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failedReason => $composableBuilder(
    column: $table.failedReason,
    builder: (column) => column,
  );

  Expression<T> occurrenceMediaRefs<T extends Object>(
    Expression<T> Function($$OccurrenceMediaTableAnnotationComposer a) f,
  ) {
    final $$OccurrenceMediaTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrenceMedia,
      getReferencedColumn: (t) => t.occurrenceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrenceMediaTableAnnotationComposer(
            $db: $db,
            $table: $db.occurrenceMedia,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$OccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrencesTable,
          Occurrence,
          $$OccurrencesTableFilterComposer,
          $$OccurrencesTableOrderingComposer,
          $$OccurrencesTableAnnotationComposer,
          $$OccurrencesTableCreateCompanionBuilder,
          $$OccurrencesTableUpdateCompanionBuilder,
          (Occurrence, $$OccurrencesTableReferences),
          Occurrence,
          PrefetchHooks Function({bool occurrenceMediaRefs})
        > {
  $$OccurrencesTableTableManager(_$AppDatabase db, $OccurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<DateTime> occurredAt = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> observableId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<SyncPhase?> failedPhase = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdLocalAt = const Value.absent(),
                Value<DateTime?> mediaUploadedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> failedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrencesCompanion(
                id: id,
                title: title,
                description: description,
                status: status,
                priority: priority,
                location: location,
                latitude: latitude,
                longitude: longitude,
                occurredAt: occurredAt,
                resolvedAt: resolvedAt,
                observableId: observableId,
                categoryId: categoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncState: syncState,
                failedPhase: failedPhase,
                retryCount: retryCount,
                createdLocalAt: createdLocalAt,
                mediaUploadedAt: mediaUploadedAt,
                syncedAt: syncedAt,
                lastAttemptAt: lastAttemptAt,
                failedReason: failedReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required String description,
                required String status,
                required String priority,
                Value<String?> location = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                required DateTime occurredAt,
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String?> observableId = const Value.absent(),
                Value<String?> categoryId = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> updatedAt = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<SyncPhase?> failedPhase = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                required DateTime createdLocalAt,
                Value<DateTime?> mediaUploadedAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> failedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrencesCompanion.insert(
                id: id,
                title: title,
                description: description,
                status: status,
                priority: priority,
                location: location,
                latitude: latitude,
                longitude: longitude,
                occurredAt: occurredAt,
                resolvedAt: resolvedAt,
                observableId: observableId,
                categoryId: categoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                syncState: syncState,
                failedPhase: failedPhase,
                retryCount: retryCount,
                createdLocalAt: createdLocalAt,
                mediaUploadedAt: mediaUploadedAt,
                syncedAt: syncedAt,
                lastAttemptAt: lastAttemptAt,
                failedReason: failedReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OccurrencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({occurrenceMediaRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (occurrenceMediaRefs) db.occurrenceMedia,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (occurrenceMediaRefs)
                    await $_getPrefetchedData<
                      Occurrence,
                      $OccurrencesTable,
                      OccurrenceMediaData
                    >(
                      currentTable: table,
                      referencedTable: $$OccurrencesTableReferences
                          ._occurrenceMediaRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$OccurrencesTableReferences(
                            db,
                            table,
                            p0,
                          ).occurrenceMediaRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.occurrenceId == item.id,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$OccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrencesTable,
      Occurrence,
      $$OccurrencesTableFilterComposer,
      $$OccurrencesTableOrderingComposer,
      $$OccurrencesTableAnnotationComposer,
      $$OccurrencesTableCreateCompanionBuilder,
      $$OccurrencesTableUpdateCompanionBuilder,
      (Occurrence, $$OccurrencesTableReferences),
      Occurrence,
      PrefetchHooks Function({bool occurrenceMediaRefs})
    >;
typedef $$OccurrenceMediaTableCreateCompanionBuilder =
    OccurrenceMediaCompanion Function({
      required String id,
      required String occurrenceId,
      required String mediaType,
      required String localPath,
      Value<String?> remotePath,
      required String mimeType,
      Value<int?> sizeBytes,
      Value<int?> durationSeconds,
      Value<int> sortOrder,
      Value<String?> originalName,
      Value<String?> contentHash,
      Value<int> rowid,
    });
typedef $$OccurrenceMediaTableUpdateCompanionBuilder =
    OccurrenceMediaCompanion Function({
      Value<String> id,
      Value<String> occurrenceId,
      Value<String> mediaType,
      Value<String> localPath,
      Value<String?> remotePath,
      Value<String> mimeType,
      Value<int?> sizeBytes,
      Value<int?> durationSeconds,
      Value<int> sortOrder,
      Value<String?> originalName,
      Value<String?> contentHash,
      Value<int> rowid,
    });

final class $$OccurrenceMediaTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $OccurrenceMediaTable,
          OccurrenceMediaData
        > {
  $$OccurrenceMediaTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $OccurrencesTable _occurrenceIdTable(_$AppDatabase db) =>
      db.occurrences.createAlias(
        $_aliasNameGenerator(
          db.occurrenceMedia.occurrenceId,
          db.occurrences.id,
        ),
      );

  $$OccurrencesTableProcessedTableManager get occurrenceId {
    final $_column = $_itemColumn<String>('occurrence_id')!;

    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_occurrenceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$OccurrenceMediaTableFilterComposer
    extends Composer<_$AppDatabase, $OccurrenceMediaTable> {
  $$OccurrenceMediaTableFilterComposer({
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

  ColumnFilters<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  $$OccurrencesTableFilterComposer get occurrenceId {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrenceMediaTableOrderingComposer
    extends Composer<_$AppDatabase, $OccurrenceMediaTable> {
  $$OccurrenceMediaTableOrderingComposer({
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

  ColumnOrderings<String> get mediaType => $composableBuilder(
    column: $table.mediaType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sizeBytes => $composableBuilder(
    column: $table.sizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  $$OccurrencesTableOrderingComposer get occurrenceId {
    final $$OccurrencesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableOrderingComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrenceMediaTableAnnotationComposer
    extends Composer<_$AppDatabase, $OccurrenceMediaTable> {
  $$OccurrenceMediaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get mediaType =>
      $composableBuilder(column: $table.mediaType, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get sizeBytes =>
      $composableBuilder(column: $table.sizeBytes, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get originalName => $composableBuilder(
    column: $table.originalName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  $$OccurrencesTableAnnotationComposer get occurrenceId {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.occurrenceId,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$OccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrenceMediaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrenceMediaTable,
          OccurrenceMediaData,
          $$OccurrenceMediaTableFilterComposer,
          $$OccurrenceMediaTableOrderingComposer,
          $$OccurrenceMediaTableAnnotationComposer,
          $$OccurrenceMediaTableCreateCompanionBuilder,
          $$OccurrenceMediaTableUpdateCompanionBuilder,
          (OccurrenceMediaData, $$OccurrenceMediaTableReferences),
          OccurrenceMediaData,
          PrefetchHooks Function({bool occurrenceId})
        > {
  $$OccurrenceMediaTableTableManager(
    _$AppDatabase db,
    $OccurrenceMediaTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OccurrenceMediaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OccurrenceMediaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OccurrenceMediaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> occurrenceId = const Value.absent(),
                Value<String> mediaType = const Value.absent(),
                Value<String> localPath = const Value.absent(),
                Value<String?> remotePath = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int?> sizeBytes = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> originalName = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceMediaCompanion(
                id: id,
                occurrenceId: occurrenceId,
                mediaType: mediaType,
                localPath: localPath,
                remotePath: remotePath,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                durationSeconds: durationSeconds,
                sortOrder: sortOrder,
                originalName: originalName,
                contentHash: contentHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String occurrenceId,
                required String mediaType,
                required String localPath,
                Value<String?> remotePath = const Value.absent(),
                required String mimeType,
                Value<int?> sizeBytes = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String?> originalName = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrenceMediaCompanion.insert(
                id: id,
                occurrenceId: occurrenceId,
                mediaType: mediaType,
                localPath: localPath,
                remotePath: remotePath,
                mimeType: mimeType,
                sizeBytes: sizeBytes,
                durationSeconds: durationSeconds,
                sortOrder: sortOrder,
                originalName: originalName,
                contentHash: contentHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$OccurrenceMediaTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({occurrenceId = false}) {
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
                    if (occurrenceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.occurrenceId,
                                referencedTable:
                                    $$OccurrenceMediaTableReferences
                                        ._occurrenceIdTable(db),
                                referencedColumn:
                                    $$OccurrenceMediaTableReferences
                                        ._occurrenceIdTable(db)
                                        .id,
                              )
                              as T;
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

typedef $$OccurrenceMediaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrenceMediaTable,
      OccurrenceMediaData,
      $$OccurrenceMediaTableFilterComposer,
      $$OccurrenceMediaTableOrderingComposer,
      $$OccurrenceMediaTableAnnotationComposer,
      $$OccurrenceMediaTableCreateCompanionBuilder,
      $$OccurrenceMediaTableUpdateCompanionBuilder,
      (OccurrenceMediaData, $$OccurrenceMediaTableReferences),
      OccurrenceMediaData,
      PrefetchHooks Function({bool occurrenceId})
    >;
typedef $$CheckInsTableCreateCompanionBuilder =
    CheckInsCompanion Function({
      required String id,
      required double latitude,
      required double longitude,
      required double accuracy,
      required DateTime capturedAt,
      Value<String?> note,
      Value<SyncState> syncState,
      Value<SyncPhase?> failedPhase,
      Value<int> retryCount,
      required DateTime createdLocalAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> failedReason,
      Value<int> rowid,
    });
typedef $$CheckInsTableUpdateCompanionBuilder =
    CheckInsCompanion Function({
      Value<String> id,
      Value<double> latitude,
      Value<double> longitude,
      Value<double> accuracy,
      Value<DateTime> capturedAt,
      Value<String?> note,
      Value<SyncState> syncState,
      Value<SyncPhase?> failedPhase,
      Value<int> retryCount,
      Value<DateTime> createdLocalAt,
      Value<DateTime?> syncedAt,
      Value<DateTime?> lastAttemptAt,
      Value<String?> failedReason,
      Value<int> rowid,
    });

class $$CheckInsTableFilterComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
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

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SyncState, SyncState, String> get syncState =>
      $composableBuilder(
        column: $table.syncState,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<SyncPhase?, SyncPhase, String>
  get failedPhase => $composableBuilder(
    column: $table.failedPhase,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdLocalAt => $composableBuilder(
    column: $table.createdLocalAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failedReason => $composableBuilder(
    column: $table.failedReason,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
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

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get accuracy => $composableBuilder(
    column: $table.accuracy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failedPhase => $composableBuilder(
    column: $table.failedPhase,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdLocalAt => $composableBuilder(
    column: $table.createdLocalAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failedReason => $composableBuilder(
    column: $table.failedReason,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracy =>
      $composableBuilder(column: $table.accuracy, builder: (column) => column);

  GeneratedColumn<DateTime> get capturedAt => $composableBuilder(
    column: $table.capturedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncState, String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SyncPhase?, String> get failedPhase =>
      $composableBuilder(
        column: $table.failedPhase,
        builder: (column) => column,
      );

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdLocalAt => $composableBuilder(
    column: $table.createdLocalAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failedReason => $composableBuilder(
    column: $table.failedReason,
    builder: (column) => column,
  );
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheckInsTable,
          CheckIn,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (CheckIn, BaseReferences<_$AppDatabase, $CheckInsTable, CheckIn>),
          CheckIn,
          PrefetchHooks Function()
        > {
  $$CheckInsTableTableManager(_$AppDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<double> latitude = const Value.absent(),
                Value<double> longitude = const Value.absent(),
                Value<double> accuracy = const Value.absent(),
                Value<DateTime> capturedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<SyncPhase?> failedPhase = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<DateTime> createdLocalAt = const Value.absent(),
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> failedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion(
                id: id,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                capturedAt: capturedAt,
                note: note,
                syncState: syncState,
                failedPhase: failedPhase,
                retryCount: retryCount,
                createdLocalAt: createdLocalAt,
                syncedAt: syncedAt,
                lastAttemptAt: lastAttemptAt,
                failedReason: failedReason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required double latitude,
                required double longitude,
                required double accuracy,
                required DateTime capturedAt,
                Value<String?> note = const Value.absent(),
                Value<SyncState> syncState = const Value.absent(),
                Value<SyncPhase?> failedPhase = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                required DateTime createdLocalAt,
                Value<DateTime?> syncedAt = const Value.absent(),
                Value<DateTime?> lastAttemptAt = const Value.absent(),
                Value<String?> failedReason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheckInsCompanion.insert(
                id: id,
                latitude: latitude,
                longitude: longitude,
                accuracy: accuracy,
                capturedAt: capturedAt,
                note: note,
                syncState: syncState,
                failedPhase: failedPhase,
                retryCount: retryCount,
                createdLocalAt: createdLocalAt,
                syncedAt: syncedAt,
                lastAttemptAt: lastAttemptAt,
                failedReason: failedReason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheckInsTable,
      CheckIn,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckIn, BaseReferences<_$AppDatabase, $CheckInsTable, CheckIn>),
      CheckIn,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OccurrencesTableTableManager get occurrences =>
      $$OccurrencesTableTableManager(_db, _db.occurrences);
  $$OccurrenceMediaTableTableManager get occurrenceMedia =>
      $$OccurrenceMediaTableTableManager(_db, _db.occurrenceMedia);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
}
