import 'package:kharcha_graph/models/transaction_type.dart';

class TransactionInfo {
  String id;
  DateTime date;
  TransactionType type;
  double amount;
  String merchant;
  String? category;

  TransactionInfo(this.id, this.date, this.type, this.amount, this.merchant, [this.category]);

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'date': date.toString(),
      'type': type.displayName,
      'amount': amount,
      'merchant': merchant,
      'category': category ?? '',
    };
  }

  static TransactionInfo fromMap(Map<String, Object?> transactionMap) {
    return TransactionInfo(
      transactionMap['id'] as String,
      DateTime.parse(transactionMap['date'] as String),
      getTransactionTypeFromDisplayNameString(transactionMap['type'] as String),
      transactionMap['amount'] as double,
      transactionMap['merchant'] as String,
      transactionMap['category'] as String?);
  }
}