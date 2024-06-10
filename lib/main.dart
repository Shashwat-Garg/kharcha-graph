import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:kharcha_graph/models/transaction_info.dart';
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

  // Updates the transations list that is shown on the app
  void _updateTransactionsList(List<TransactionInfo> transactionsList) {
    setState(() {
      _transactionsList = transactionsList;
    });
  }

  @override
  void initState() {
    super.initState();
    
    // As the page is rendered, ensure to read the PDF
    readPdf();
  }

  Future<void> readPdf() async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                border: TableBorder.all(color: Colors.black, style: BorderStyle.solid, width: 2),
                children: [
                  const TableRow(
                    children: [
                      Text(r'Date'),
                      Text(r'Merchant'),
                      Text(r'Type'),
                      Text(r'Amount'),
                    ],
                  ),
                  for (TransactionInfo transactionInfo in _transactionsList) TableRow(
                    children: [
                      Text(transactionInfo.date),
                      Text(transactionInfo.merchant),
                      Text(transactionInfo.type.name),
                      Text(transactionInfo.amount.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
