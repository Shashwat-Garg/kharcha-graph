import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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

  // Updates the transations list that is shown on the app
  void _updateTransactionsList(List<TransactionInfo> transactionsList) {
    setState(() {
      _transactionsList = transactionsList;
    });
  }

  @override
  void initState() {
    super.initState();
  }

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
      _updateTransactionsList(transactionsList);
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

  Widget getChild() {
    if (showLoader) {
      return const Center(child: CircularProgressIndicator());
    }

    if (showPickPdfButton) {
      return renderPickPdfButton();
    }

    return renderPdfData();
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
            child: getChild()
          ),
        ],
      ),
    );
  }
}
