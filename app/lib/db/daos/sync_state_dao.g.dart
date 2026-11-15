// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_state_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncStateDaoMixin on DatabaseAccessor<AppDatabase> {
  $GroupsTable get groups => attachedDatabase.groups;
  $LocalGroupSyncTable get localGroupSync => attachedDatabase.localGroupSync;
  $LocalSyncCursorTable get localSyncCursor => attachedDatabase.localSyncCursor;
  $LocalSettingsTable get localSettings => attachedDatabase.localSettings;
  $LocalOutboxTable get localOutbox => attachedDatabase.localOutbox;
  SyncStateDaoManager get managers => SyncStateDaoManager(this);
}

class SyncStateDaoManager {
  final _$SyncStateDaoMixin _db;
  SyncStateDaoManager(this._db);
  $$GroupsTableTableManager get groups =>
      $$GroupsTableTableManager(_db.attachedDatabase, _db.groups);
  $$LocalGroupSyncTableTableManager get localGroupSync =>
      $$LocalGroupSyncTableTableManager(
        _db.attachedDatabase,
        _db.localGroupSync,
      );
  $$LocalSyncCursorTableTableManager get localSyncCursor =>
      $$LocalSyncCursorTableTableManager(
        _db.attachedDatabase,
        _db.localSyncCursor,
      );
  $$LocalSettingsTableTableManager get localSettings =>
      $$LocalSettingsTableTableManager(_db.attachedDatabase, _db.localSettings);
  $$LocalOutboxTableTableManager get localOutbox =>
      $$LocalOutboxTableTableManager(_db.attachedDatabase, _db.localOutbox);
}
