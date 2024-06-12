import 'package:kharcha_graph/models/transaction_type.dart';

class TransactionInfo {
  String id;
  DateTime date;
  TransactionType type;
  double amount;
  String merchant;


  TransactionInfo({required this.id, required this.date, required this.type, required this.amount, required this.merchant});
}