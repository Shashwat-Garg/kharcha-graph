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

String getMonthShortHandByIndex(int monthIndex) {
  switch(monthIndex) {
    case 1:
      return r'Jan';
    case 2:
      return r'Feb';
    case 3:
      return r'Mar';
    case 4:
      return r'Apr';
    case 5:
      return r'May';
    case 6:
      return r'Jun';
    case 7:
      return r'Jul';
    case 8:
      return r'Aug';
    case 9:
      return r'Sep';
    case 10:
      return r'Oct';
    case 11:
      return r'Nov';
    default:
      return r'Dec';
  }
}