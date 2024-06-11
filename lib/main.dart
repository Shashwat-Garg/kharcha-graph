import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kharcha_graph/models/transaction_category.dart';
import 'package:kharcha_graph/models/transaction_info.dart';
import 'package:kharcha_graph/models/transaction_type.dart';
import 'package:kharcha_graph/util/read_pdf_content.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
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
  List<TransactionInfo> _transactionsList = [];
  bool showPickPdfButton = true;
  bool showLoader = false;

  // TODO: add ability for user to create categories of their own
  final List<TransactionCategory> _transactionCategories = [
    TransactionCategory("Food"),
    TransactionCategory("Groceries"),
    TransactionCategory("Internet bill"),
    TransactionCategory("Medical"),
    TransactionCategory("Petrol")
  ];

  final Map<String, String> _categorizedMerchants = {};
  String? _currentMerchant;
  String? _currentCategory;

  Future<void> readPdf() async {
    setState(() {
      showPickPdfButton = false;
      showLoader = true;
    });

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
      List<TransactionInfo> transactionsList = await readTransactionPdf(pdfBytes);
      setState(() {
        _transactionsList = transactionsList;
        showPickPdfButton = false;
        showLoader = false;
      });
    }
    else {
      setState(() {
        showPickPdfButton = true;
        showLoader = false;
      });
    }
  }

  void addMerchantToCategory(String merchantString, String category) {
    double totalExpensesForMerchant = _transactionsList
      .where((transaction) => transaction.type == TransactionType.debit && transaction.merchant == merchantString)
      .map((transaction) => transaction.amount)
      .reduce((value, element) => value + element);

    int index = _transactionCategories.indexWhere((transactionCategory) => transactionCategory.name == category);
    if (index == -1) {
      TransactionCategory transactionCategory = TransactionCategory(category);
      transactionCategory.addMerchant(merchantString);
      transactionCategory.addAmount(totalExpensesForMerchant);
      setState(() {
        _transactionCategories.add(transactionCategory);
        _categorizedMerchants[merchantString] = category;
        _currentCategory = null;
        _currentMerchant = null;
      });
    }
    else {
      TransactionCategory transactionCategory = _transactionCategories[index];
      transactionCategory.addAmount(totalExpensesForMerchant);
      transactionCategory.addMerchant(merchantString);
      setState(() {
        _transactionCategories[index] = transactionCategory;
        _categorizedMerchants[merchantString] = category;
        _currentCategory = null;
        _currentMerchant = null;
      });
    }
  }

  Widget renderChild() {
    if (showLoader) {
      return const Center(child: CircularProgressIndicator());
    }

    if (showPickPdfButton) {
      return renderPickPdfButton();
    }

    // return renderPdfData();
    return renderCategorization();
  }

  Widget renderPickPdfButton() {
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
        onPressed: () => readPdf(),
        child: const Text('Pick a pdf')
      ),
    );
  }

  Widget renderPdfData() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Table(
        border: TableBorder.all(color: Colors.black, style: BorderStyle.solid, width: 1),
        children: [
          const TableRow(
            children: [
              Text(r'Date', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
              Text(r'Merchant', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text(r'Type', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              Text(r'Amount', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ],
          ),
          for (TransactionInfo transactionInfo in _transactionsList) TableRow(
            children: [
              Text(transactionInfo.date.toString(), textAlign: TextAlign.center),
              Text(transactionInfo.merchant, textAlign: TextAlign.center),
              Text(transactionInfo.type.displayName, textAlign: TextAlign.center),
              Text(transactionInfo.amount.toString(), textAlign: TextAlign.center),
            ],
          ),
        ],
      ),
    );
  }

  Widget renderCategorization() {
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
            _transactionCategories
              .map((transactionCategory) => DropdownMenuItem(
                value: transactionCategory.name,
                child: Text(transactionCategory.name)
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
          onPressed: (_currentCategory != null && _currentMerchant != null) ? () => addMerchantToCategory(_currentMerchant!, _currentCategory!) : null,
          child: const Text(r'Add merchant to category')
        ),
        Container(
          margin: const EdgeInsets.only(top: 20),
          child: Table(
            border: TableBorder.all(color: Colors.black, style: BorderStyle.solid, width: 1),
            children: [ const TableRow(
                children: [
                  Text(r'Category', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                  Text(r'Amount', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ],
              ),
              for (TransactionCategory transactionCategory in _transactionCategories) TableRow(
                children: [
                  Text(transactionCategory.name, textAlign: TextAlign.center),
                  Text(transactionCategory.amount.toStringAsFixed(2), textAlign: TextAlign.center),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: renderChild(),
          ),
        ],
      ),
    );
  }
}
