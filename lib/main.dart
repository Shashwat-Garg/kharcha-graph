import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kharcha_graph/locator/global_locator.dart';
import 'package:kharcha_graph/models/transaction_info.dart';
import 'package:kharcha_graph/models/transaction_type.dart';
import 'package:kharcha_graph/services/transaction_info_service.dart';
import 'package:kharcha_graph/ui/category_add_dialog.dart';
import 'package:kharcha_graph/ui/visualize_tab.dart';
import 'package:kharcha_graph/ui/visualize_tab_line_chart.dart';
import 'package:kharcha_graph/util/common.dart';
import 'package:kharcha_graph/util/read_pdf_content.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  setupGlobalLocator();
  runApp(const KharchaGraph());
}

class KharchaGraph extends StatelessWidget {
  const KharchaGraph({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kharcha Graph',
      theme: ThemeData(
        // This is the theme of your application.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const KharchaGraphHomePage(title: 'Kharcha Graph'),
    );
  }
}

class KharchaGraphHomePage extends StatefulWidget {
  const KharchaGraphHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<KharchaGraphHomePage> createState() => _KharchaGraphHomePageState();
}

class _KharchaGraphHomePageState extends State<KharchaGraphHomePage> {
  final TransactionInfoService _transactionInfoService = globalLocator.get<TransactionInfoService>();
  List<TransactionInfo> _transactionsList = [];
  bool _showLoader = true;

  Map<String, double> _transactionCategories = {};

  Map<String, String> _categorizedMerchants = {};
  String? _currentMerchant;
  String? _currentCategory;

  @override
  void initState() {
    _readTransactionsDataFromDb();
    super.initState();
  }

  Future<void> _readTransactionsDataFromDb() async {
    // Only get the list of debit transactions
    List<TransactionInfo> transactions =
      await _transactionInfoService.getAllTransactions(transactionType: TransactionType.debit);
    _updateStateBasedOnTransactions(transactions);
  }

  Future<void> _updateStateBasedOnTransactions(List<TransactionInfo> transactionsList) async {
    if (transactionsList.isNotEmpty) {
      transactionsList.addAll(_transactionsList);
      Iterable<TransactionInfo> transactionsWithCategory = transactionsList
        .where((transaction) => transaction.category != null && transaction.category!.isNotEmpty);
      setState(() {
        _showLoader = false;
        _transactionsList = transactionsList;
        _transactionCategories = getCategoryToAmountMapForTransactions(transactionsWithCategory);
        _categorizedMerchants = {for (TransactionInfo transaction in transactionsWithCategory) transaction.merchant : transaction.category!};
      });
    }
    else {
      setState(() {
        _showLoader = false;
      });
    }
  }

  Future<void> _updateDbWithTransactions(List<TransactionInfo> transactionsList) async {
    await _transactionInfoService.insertTransactions(transactionsList);
    _readTransactionsDataFromDb();
  }

  void _handlePdfButtonClick() {
    setState(() {
      _showLoader = true;
    });

    _readPdf();
  }

  Future<void> _readPdf() async {
    // If the platform is Android, ensure we have storage access
    if (Platform.isAndroid) {
      await Permission.manageExternalStorage.request();
    }

    // Ask the user to pick a PDF file which we'll parse
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      dialogTitle: 'Pick a transaction document',
      type: FileType.custom,
      allowedExtensions: ['pdf']);
    
    // If the user has correctly chosen a file
    if (pickedFile != null && pickedFile.files.single.path != null) {
      final pdfBytes = await File(pickedFile.files.single.path!).readAsBytes();
      
      // Need to use the compute method since the pdf extraction is not async
      // And we don't want to block the UI thread
      List<TransactionInfo> transactionsList = await compute(readTransactionPdf, pdfBytes);

      // Save to DB and update state
      _updateDbWithTransactions(transactionsList);
    }
  }

  Future<void> _addMerchantToCategory(String merchantString, String category) async {
    double totalExpensesForMerchant = _transactionsList
      .where((transaction) => transaction.type == TransactionType.debit && transaction.merchant == merchantString)
      .map((transaction) => transaction.amount)
      .reduce((value, element) => value + element);

    _transactionCategories.putIfAbsent(category, () => 0);

    await _transactionInfoService.setMerchantToCategory(merchantString, category);

    setState(() {
      _transactionCategories[category] = _transactionCategories[category]! + totalExpensesForMerchant;
      _categorizedMerchants[merchantString] = category;
      _currentCategory = null;
      _currentMerchant = null;
    });
  }

  void _addNewCategory(String? categoryName) {
    if (categoryName != null && categoryName.isNotEmpty) {
      setState(() {
        _transactionCategories.putIfAbsent(categoryName, () => 0);
      });
    }
  }

  Widget _renderPickPdfButton() {
    return Center(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          backgroundColor: Colors.lightBlueAccent,
          foregroundColor: Colors.blueGrey,
        ),
        onPressed: () => _handlePdfButtonClick(),
        child: const Text('Pick a pdf')
      ),
    );
  }

  Widget _renderHome() {
    if (_showLoader) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _renderCategorizationInput(),
          _renderCategorization()
        ],
      ),
    );
  }

  Widget _renderCategorizationInput() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(r'Select a merchant and map to a category'),
        DropdownButton(
          hint: const Text(r'Select Merchant'),
          value: _currentMerchant,
          items:
            _transactionsList
              .where((transactionInfo) => !_categorizedMerchants.containsKey(transactionInfo.merchant))
              .map((transactionInfo) => transactionInfo.merchant)
              .toSet()
              .map((merchant) => DropdownMenuItem(
                value: merchant,
                child: Text(merchant)
              ))
              .toList(),
          onChanged: (selectedValue) => {
            if (selectedValue != null && selectedValue.isNotEmpty) {
              setState(() {
                _currentMerchant = selectedValue;
              })
            }
          }
        ),
        DropdownButton(
          hint: const Text(r'Select Category'),
          value: _currentCategory,
          items:
            _transactionCategories.keys
              .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category)
              ))
              .toList(),
          onChanged: (selectedValue) => {
            if (selectedValue != null && selectedValue.isNotEmpty) {
              setState(() {
                _currentCategory = selectedValue;
              })
            }
          }
        ),
        OutlinedButton(
          onPressed: (_currentCategory != null && _currentMerchant != null) ? () => _addMerchantToCategory(_currentMerchant!, _currentCategory!) : null,
          child: const Text(r'Add merchant to category')
        ),
        OutlinedButton(
          onPressed: () async { _addNewCategory(await CategoryAddDialog(context).openCategoryAddDialog()); },
          child: const Text(r'Add another category')
        ),
      ],
    );
  }

  Widget _renderCategorization() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(r'Below is the total expenditure in each category:'),
        const SizedBox(height: 20),
        Table(
          border: TableBorder.all(color: Colors.black, style: BorderStyle.solid, width: 1),
          children: [ const TableRow(
              children: [
                Text(r'Category', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                Text(r'Amount', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ],
            ),
            // Shows the total expense
            TableRow(
              children: [
                const Text(r'Total', textAlign: TextAlign.center),
                Text(
                  _transactionCategories.values.isEmpty ? r'0'
                    : _transactionCategories.values.reduce((sum, value) => sum + value).toStringAsFixed(2),
                  textAlign: TextAlign.center)
              ]
            ),
            for (var category in _transactionCategories.keys) TableRow(
              children: [
                Text(category, textAlign: TextAlign.center),
                Text(_transactionCategories[category]!.toStringAsFixed(2), textAlign: TextAlign.center),
              ],
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.home), text: r'Home',),
              Tab(icon: Icon(Icons.data_object), text: r'Add more data'),
              Tab(icon: Icon(Icons.bar_chart), text: r'Visualize')
            ]
          ),
        ),
        body: TabBarView(
          children: [
            _renderHome(),
            _renderPickPdfButton(),
            // VisualizeTab(transactions: _transactionsList),
            VisualizeTabLineChart(transactions: _transactionsList)
          ],
        ),
      ),
    );
  }
}
