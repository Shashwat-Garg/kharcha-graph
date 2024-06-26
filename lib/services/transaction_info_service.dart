import 'package:kharcha_graph/dbcontext/db_context.dart';
import 'package:kharcha_graph/locator/global_locator.dart';
import 'package:kharcha_graph/models/transaction_info.dart';
import 'package:kharcha_graph/models/transaction_type.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class TransactionInfoService {
  static String tableName = r'transactions';
  final DbContext _dbContext = globalLocator.get<DbContext>();

  Future<bool> insertTransactions(List<TransactionInfo> transactions) async {
    Database db = await _dbContext.getDatabase();
    await db.transaction((transaction) async {
      for (TransactionInfo transactionInfo in transactions) {
        await transaction.insert(tableName, transactionInfo.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });

    return true;
  }

  Future<bool> insertTransaction(TransactionInfo transaction) async {
    Database db = await _dbContext.getDatabase();
    await db.insert(tableName, transaction.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore);
    return true;
  }

  Future<List<TransactionInfo>> getAllTransactions({DateTime? start, DateTime? end, TransactionType? transactionType}) async {
    String whereString = '';
    List<dynamic> whereArgs = [];
    if (start != null) {
      whereString = 'DATE(date) >= DATE(?)';
      whereArgs.add(start.toString());
    }

    if (end != null) {
      if (whereString.isNotEmpty) {
        whereString = '$whereString and ';
      }

      whereString = '$whereString DATE(date) < DATE(?)';
      whereArgs.add(end.toString());
    }

    if (transactionType != null) {
      if (whereString.isNotEmpty) {
        whereString = '$whereString and ';
      }

      whereString = '$whereString type = ?';
      whereArgs.add(transactionType.displayName);
    }

    Database db = await _dbContext.getDatabase();
    List<Map<String, Object?>> transactions = await db.query(tableName, where: whereString, whereArgs: whereArgs);
    List<TransactionInfo> transactionsList = transactions.map((transactionMap) => TransactionInfo.fromMap(transactionMap)).toList();
    return transactionsList;
  }

  Future<bool> setMerchantToCategory(String merchant, String category) async {
    Database db = await _dbContext.getDatabase();
    await db.update(tableName, {'category': category}, where: 'merchant = ?', whereArgs: [merchant]);
    return true;
  }

  Future<bool> deleteAllTransactions() async {
    Database db = await _dbContext.getDatabase();
    await db.delete(tableName);
    return true;
  }
}