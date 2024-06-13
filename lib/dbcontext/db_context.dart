import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DbContext {
  late final Future<Database> _database;
  DbContext() {
    _database = _connectToDb();
  }

  Future<Database> _connectToDb() async {
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;
    return databaseFactory.openDatabase(
      join(await getDatabasesPath(), r'kharcha_graph'),
      options: OpenDatabaseOptions(
        onCreate: (db, version) {
          return db.execute(
            'CREATE TABLE transactions(id TEXT, date TEXT, type TEXT, amount REAL, merchant TEXT, category TEXT)'
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