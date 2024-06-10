enum TransactionType {
  debit,
  credit,
  unknown
}

extension TransationTypeExtension on TransactionType {
  String get name {
    switch(this) {
      case TransactionType.debit:
        return r'DEBIT';
      case TransactionType.credit:
        return r'CREDIT';
      default:
        return r'UNKNOWN';
    }
  }
}