import 'dart:io';

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
  String text = '';

  void _updateText(String newText) {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // test without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      text += newText;
    });
  }

  @override
  void initState() {
    super.initState();
    readTransactionPdf();
  }

  Future<void> readTransactionPdf() async {
    if (Platform.isAndroid) {
      await Permission.manageExternalStorage.request();
    } else {
      await Permission.storage.request();
    }
    final pdfBytes = await File('/storage/emulated/0/Download/test.pdf').readAsBytes();
    final PdfDocument pdfDocument = PdfDocument(inputBytes: pdfBytes);
    final List<TextLine> textLines = PdfTextExtractor(pdfDocument).extractTextLines();
    for (TextLine textLine in textLines) {
      _updateText('${textLine.fontName} | ${textLine.fontSize} | ${textLine.bounds.center.dx},${textLine.bounds.center.dy} | ${textLine.text}\n');
    }

    pdfDocument.dispose();
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
                text,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
