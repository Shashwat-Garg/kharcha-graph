class TransactionCategory {
  String name;

  double amount;

  List<String> merchants;

  // TransactionCategory(this.name, this.amount, {this.merchants = []});
  TransactionCategory(this.name, {this.amount = 0, List<String>? merchantsList}) : merchants = merchantsList ?? [];

  void addAmount(double newAmount) {
    amount += newAmount;
  }

  void addMerchant(String merchant) {
    merchants.add(merchant);
  }
}