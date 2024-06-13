import 'package:kharcha_graph/models/transaction_info.dart';

Map<String, double> getCategoryToAmountMapForTransactions(Iterable<TransactionInfo> transactionsList) {
  Map<String, double> categoryToAmount = {};
  for (TransactionInfo transaction in transactionsList) {
    if (transaction.category != null && transaction.category!.isNotEmpty) {
      categoryToAmount.putIfAbsent(transaction.category!, () => 0);
      categoryToAmount[transaction.category!] = categoryToAmount[transaction.category!]! + transaction.amount;
    }
  }

  return categoryToAmount;
}