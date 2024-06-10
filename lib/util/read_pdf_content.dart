import 'dart:typed_data';

import 'package:kharcha_graph/models/transaction_info.dart';
import 'package:kharcha_graph/models/transaction_type.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

Future<List<TransactionInfo>> readTransactionPdf(Uint8List pdfBytes) async {
  // Contains the list of transactions present in the doc
  List<TransactionInfo> transactionsList = [];

  final PdfDocument pdfDocument = PdfDocument(inputBytes: pdfBytes);
  final PdfTextExtractor pdfTextExtractor = PdfTextExtractor(pdfDocument);
  
  // Extract all text lines from the PDF
  final List<TextLine> textLines = pdfTextExtractor.extractTextLines();

  // Stores the column bounds' left value
  // so that we can understand which texts are lying in which column
  List<double> columnBeginnings = _getColumnBeginnings(textLines, pdfDocument.pages[0].size.width);

  // Now, let's try getting the debit or credit transactions
  for (int lineIndex = 0; lineIndex < textLines.length; lineIndex++) {
    final String lineText = textLines[lineIndex].text.replaceAll(' ', '');

    // The number of columns are actually 1 less, since we add the page's end as well
    List<String> currentLine = List.filled(columnBeginnings.length - 1, '');

    // If it is a debit or credit transaction
    if (lineText.contains(r'DEBIT') || lineText.contains(r'CREDIT')) {
      currentLine = _getCurrentLine(textLines, lineIndex, columnBeginnings);
    }

    // All columns should be non-empty
    if (currentLine.where((col) => col.isEmpty).isEmpty) {
      transactionsList.add(_getTransactionInfoForLine(currentLine));
    }
  }

  return transactionsList;
}   

List<String> _getCurrentLine(List<TextLine> textLines, int lineIndex, List<double> columnBeginnings) {
  // The number of columns are actually 1 less, since we add the page's end as well
  List<String> currentLine = List.filled(columnBeginnings.length - 1, '');

  // Do these for previous 2 lines as well as the current line
  // These lines contain the transaction date and time
  for (int lookBack = 2; lookBack >= 0; lookBack--) {
    for (TextWord textWord in textLines[lineIndex - lookBack].wordCollection) {
      final String currentText = textWord.text.trim();
      if (currentText.isNotEmpty) {
        final double wordRight = textWord.bounds.right;
        for (int columnIndex = 0; columnIndex < currentLine.length; columnIndex++) {
          if (columnBeginnings[columnIndex] <= wordRight && columnBeginnings[columnIndex + 1] >= wordRight) {
            currentLine[columnIndex] += currentText;
            break;
          }
        }
      }
    }
  }

  return currentLine;
}

List<double> _getColumnBeginnings(List<TextLine> textLines, double pdfWidth) {
  final List<double> columnBeginnings = [];

  // Find the first text line that contains headers
  final TextLine headersLine = textLines.where((textLine) => textLine.text.replaceAll(' ', '').contains(r'TransactionDetails')).first;

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
        case r'Date':
        case r'TransactionDetails':
        case r'Type':
        case r'Amount':
          columnBeginnings.add(columnStart);
          currentWord = '';
          columnStart = -1;
      }
    }
  }

  // As the last bound, add the pdf document width, which is the end of all texts
  columnBeginnings.add(pdfWidth);

  return columnBeginnings;
}

TransactionInfo _getTransactionInfoForLine(List<String> currentLine) {
  return TransactionInfo(
    date: _convertDateToDateTime(currentLine[0]),
    type: TransactionType.values.where((type) => type.displayName == currentLine[2]).first,
    amount: double.parse(currentLine[3].replaceAll(RegExp(r'[^0-9.]'), r'')),

    // Replace unnecessary text
    merchant: currentLine[1].replaceAll(r'Paidto', r'').replaceAll(r'Receivedfrom', r''),
  );
}

// Converts the given date string to a DateTime
// Format of the date string here is:
// MMMdd,yyyyhh:mm[am/pm]
DateTime _convertDateToDateTime(String dateString) {
  // DateTime date = DateFormat('MMMdd,yyyyhh:mmaa').parse(dateString);
  // return date;
  int month = _getMonthIndex(dateString.substring(0, 3));
  int day = int.parse(dateString.substring(3, 5));
  int year = int.parse(dateString.substring(6, 10));
  int hour = int.parse(dateString.substring(10, 12));
  int minute = int.parse(dateString.substring(13, 15));
  if (dateString.substring(16) == 'pm') {
    hour += 12;
  }

  DateTime date = DateTime(year, month, day, hour, minute);
  return date;
}

// Gets the month index for given MMM string
int _getMonthIndex(String monthString) {
  switch(monthString) {
    case 'Jan':
      return 1;
    case 'Feb':
      return 2;
    case 'Mar':
      return 3;
    case 'Apr':
      return 4;
    case 'May':
      return 5;
    case 'Jun':
      return 6;
    case 'Jul':
      return 7;
    case 'Aug':
      return 8;
    case 'Sep':
      return 9;
    case 'Oct':
      return 10;
    case 'Nov':
      return 11;
    case 'Dec':
      return 12;
    default:
      return 0;
  }
}