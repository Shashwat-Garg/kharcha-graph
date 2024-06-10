import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

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
  String _text = '';
  
  // Stores the column bounds' left value
  // so that we can understand which texts are lying in which column
  final List<double> _columnBeginnings = [];

  // Updates the text that is shown on the app
  void _updateText(String newText) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // test without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _text += newText;
    });
  }

  // Adds a column beginning to the state's array
  void _addColumnBeginning(double columnBeginning) {
    // setState(() {
    //   _columnBeginnings.add(columnBeginning);
    // });
    _columnBeginnings.add(columnBeginning);
  }

  @override
  void initState() {
    super.initState();
    
    // As the page is rendered, ensure to read the PDF
    readTransactionPdf();
  }

  Future<void> readTransactionPdf() async {
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
      final PdfDocument pdfDocument = PdfDocument(inputBytes: pdfBytes);
      final PdfTextExtractor pdfTextExtractor = PdfTextExtractor(pdfDocument);
      
      // Extract all text lines from the PDF
      final List<TextLine> textLines = pdfTextExtractor.extractTextLines();

      // Find the first text line that contains headers
      final TextLine headersLine = textLines.where((textLine) => textLine.text.replaceAll(' ', '').contains('TransactionDetails')).first;
      
      String currentWord = '';
      double columnStart = -1;

      // Get the column bounds
      for (TextWord text in headersLine.wordCollection) {
        if (text.text.trim().isNotEmpty) {
          if (currentWord.isEmpty) {
            columnStart = text.bounds.left;
          }

          currentWord += text.text;
          
          // If the current word is any of the following
          // it means that the header is complete and we should move to next
          switch(currentWord) {
            case 'Date':
            case 'TransactionDetails':
            case 'Type':
            case 'Amount':
              _addColumnBeginning(columnStart);
              currentWord = '';
              columnStart = -1;
          }
        }
      }

      // As the last bound, add the pdf document width, which is the end of all texts
      _addColumnBeginning(pdfDocument.pages[0].size.width);

      // Contains all transaction lines of the PDF
      List<String> allLines = [];

      // Now, let's try getting the debit or credit transactions
      for (int lineIndex = 0; lineIndex < textLines.length; lineIndex++) {
        // print(textLine.text);
        final String lineText = textLines[lineIndex].text.replaceAll(' ', '');

        // The number of columns are actually 1 less, since we add the page's end as well
        List<String> currentLine = List.filled(_columnBeginnings.length - 1, '');

        // If it is a debit transaction
        if (lineText.contains('DEBIT')) {
          // Do these for previous 2 lines as well as the current line
          // These lines contain the transaction date and time
          for (int lookBack = 2; lookBack >= 0; lookBack--) {
            for (TextWord textWord in textLines[lineIndex - lookBack].wordCollection) {
              final String currentText = textWord.text.trim();
              if (currentText.isNotEmpty) {
                final double wordRight = textWord.bounds.right;
                for (int columnIndex = 0; columnIndex < currentLine.length; columnIndex++) {
                  if (_columnBeginnings[columnIndex] <= wordRight && _columnBeginnings[columnIndex + 1] >= wordRight) {
                    currentLine[columnIndex] += currentText;
                    break;
                  }
                }
              }
            }
          }
        }

        // Else if it is a credit transaction
        else if (lineText.contains('CREDIT')) {
          // Do these for previous 2 lines as well as the current line
          // These lines contain the transaction date and time
          for (int lookBack = 2; lookBack >= 0; lookBack--) {
            for (TextWord textWord in textLines[lineIndex - lookBack].wordCollection) {
              final String currentText = textWord.text.trim();
              if (currentText.isNotEmpty) {
                final double wordRight = textWord.bounds.right;
                for (int columnIndex = 0; columnIndex < currentLine.length; columnIndex++) {
                  if (_columnBeginnings[columnIndex] <= wordRight && _columnBeginnings[columnIndex + 1] >= wordRight) {
                    currentLine[columnIndex] += currentText;
                    break;
                  }
                }
              }
            }
          }
        }

        // If there's a column that is not empty, show it in the app
        if (currentLine.where((col) => col.isNotEmpty).isNotEmpty) {
          allLines.add(currentLine.join(' | '));
        }
      }

      _updateText(allLines.join('\n'));
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
              child: Text(
                _text,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
