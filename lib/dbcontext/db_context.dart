import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbContext {
  late final Future<Database> _database;
  DbContext() {
    _database = _connectToDb();
  }

  Future<Database> _connectToDb() async {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String dbPath = join(await getDatabasesPath(), r'kharcha_graph.db');

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE transactions(id TEXT NOT NULL PRIMARY KEY, date DATETIME, type TEXT, amount REAL, merchant TEXT, category TEXT)'
          );
        },
        version: 1,
      ),
    );
  }

  Future<Database> getDatabase() {
    return _database;
  }
}