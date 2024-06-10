import 'package:kharcha_graph/models/transaction_type.dart';

class TransactionInfo {
  String date;
  TransactionType type;
  double amount;
  String merchant;


  TransactionInfo({required this.date, required this.type, required this.amount, required this.merchant});
}