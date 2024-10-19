import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' as services;
import 'package:image/image.dart' as img;

class PdfGeneratorPage extends StatefulWidget {
  final Map<String, dynamic> submitForm;

  const PdfGeneratorPage({super.key, required this.submitForm});

  @override
  _PdfGeneratorPageState createState() => _PdfGeneratorPageState();
}

class _PdfGeneratorPageState extends State<PdfGeneratorPage> {
  File? _pdfFile;
  PDFDocument? _pdfDocument;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPdfFromAssets(); // Load and fill the existing form from assets
  }

  Future<void> _loadPdfFromAssets() async {
    try {
      // Load the PDF file from the assets directory
      final ByteData bytes = await services.rootBundle.load('assets/NonVisitedATC.pdf');
      final Uint8List pdfBytes = bytes.buffer.asUint8List();

      // Save the downloaded PDF to a local file
      final outputDir = await getTemporaryDirectory();
      final localFile = File("${outputDir.path}/ACT.pdf");

      // Write the response data to the local file
      await localFile.writeAsBytes(pdfBytes);

      // Now, fill the form using the downloaded file
      _fillExistingPdfForm(localFile);
    } catch (e) {
      print("Error loading or filling PDF: $e");
    }
  }

  Map<String, dynamic> _mapPdfFields(Map<String, dynamic> formData) {
    return {
      'Text1': formData['siteName'],
      'Text2': formData['siteNumber'],
      'Text3': formData['contractor'],
      'Text4': formData['techInitials'],
      'Text5': formData['selectedDate'],
      'Text6': formData['visitedDays'],
      'Text7': formData['iaiComments'],
      'Comments': formData['mainComments'],
      'Comments_3': formData['ooswComments'],
      'Check Box1': formData['iaiCheckbox'][0],
      'Check Box2': formData['iaiCheckbox'][1],
      'Check Box3': formData['iaiCheckbox'][2],
      'Check Box4': formData['iaiCheckbox'][3],
      'Check Box5': formData['iaiCheckbox'][4],
      'Check Box6': formData['iaiCheckbox'][5],
      'Check Box7': formData['iaiCheckbox'][6],
      'Check Box8': formData['iaiCheckbox'][7],
      'Check Box9': formData['ooswCheckbox'][0],
      'Check Box10': formData['ooswCheckbox'][1],
      'Check Box11': formData['ooswCheckbox'][2],
      'Check Box12': formData['ooswCheckbox'][3],
      'Check Box13': formData['ooswCheckbox'][4],
      'Check Box14': formData['ooswCheckbox'][5],
      'Check Box15': formData['ooswCheckbox'][6],
      'Check Box16': formData['ooswCheckbox'][7],
      'Check Box17': formData['ooswCheckbox'][8],
      'Check Box18': formData['ooswCheckbox'][9],
      'Check Box19': formData['mainCheckbox'][0],
      'Check Box20': formData['mainCheckbox'][1],
      'Check Box21': formData['mainCheckbox'][2],
      'Check Box22': formData['mainCheckbox'][3],
      'Check Box23': formData['mainCheckbox'][4],
      'Check Box24': formData['mainCheckbox'][5],
      'Check Box25': formData['mainCheckbox'][6],
      'Check Box26': formData['mainCheckbox'][7],
    };
  }

  Future<void> _fillExistingPdfForm(File pdfFile) async {
  const int maxRetries = 3;  
  int retryCount = 0;
  


  setState(() {
    _isLoading = true; 
  });

  while (retryCount < maxRetries) {
    try {
      final PdfDocument document = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
      Map<String, dynamic> mappedFields = _mapPdfFields(widget.submitForm);

      // Populate PDF fields
      for (int i = 0; i < document.form.fields.count; i++) {
        var field = document.form.fields[i];

        if (field is PdfTextBoxField && mappedFields.containsKey(field.name)) {
          field.text = mappedFields[field.name] ?? '';
        } else if (field is PdfCheckBoxField && mappedFields.containsKey(field.name)) {
          field.isChecked = mappedFields[field.name] ?? false;
        }
      }

      // Flatten the fields after populating them
      document.form.flattenAllFields();

      // If photos are present, add them to the PDF
      if (widget.submitForm['photos'] != null) {
        await _addPhotosToPdf(document, widget.submitForm['photos']);
      }

      final String siteNumber = mappedFields['Text2'] ?? 'UnknownSite';
      final String visitedDays = mappedFields['Text6'] ?? 'UnknownVisit';
      final String year = DateTime.now().year.toString();

      // Save the filled PDF to a local file
      final outputDir = await getTemporaryDirectory();
      final filledPdfFile = File("${outputDir.path}/$siteNumber-Visit$visitedDays-$year.pdf");
      await filledPdfFile.writeAsBytes(await document.save());

    
      setState(() {
        _pdfFile = filledPdfFile;
        _isLoading = false;  
      });

      _pdfDocument = await PDFDocument.fromFile(_pdfFile!);  
      return; 

    } catch (e) {
      retryCount++;
      print("Error filling PDF (Attempt $retryCount): $e");


      if (retryCount >= maxRetries) {
        setState(() {
          _isLoading = false;
        });


        _showRetryDialog("Failed to generate PDF after multiple attempts.");
      } else {
        await Future.delayed(Duration(seconds: 1 * retryCount));  
      }
    }
  }
}


  void _showRetryDialog(String message) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('Error'),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          isDefaultAction: true,
          child: const Text('Retry'),
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
            _loadPdfFromAssets(); // Retry loading the PDF
          },
        ),
        CupertinoDialogAction(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}


  Future<void> _addPhotosToPdf(PdfDocument document, List<File> photos) async {
    for (var photo in photos) {
      PdfPage page = document.pages.add();
      final Uint8List imageBytes = await photo.readAsBytes();
      img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage != null) {
        PdfBitmap pdfImage = PdfBitmap(imageBytes);
        double pageWidth = page.getClientSize().width;
        double pageHeight = page.getClientSize().height;

        page.graphics.drawImage(
          pdfImage,
          Rect.fromLTWH(0, 0, pageWidth, pageHeight),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    if (_pdfFile != null) {
      Share.shareXFiles([XFile(_pdfFile!.path)]);
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('No PDF generated yet!'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }
  }

  Widget _showErrorDialogAndRetry() {
  // Delay to let the widget tree settle before showing the dialog
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!_isLoading && _pdfDocument == null) {
      _showRetryDialog("Failed to load PDF. Would you like to retry?");
    }
  });

  return const SizedBox(); // Return an empty widget while the dialog is displayed
}


  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor: MediaQuery.of(context).platformBrightness == Brightness.dark
      ? CupertinoColors.black 
      : CupertinoColors.white, 
        middle: const Text('PDF Generator'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _sharePdf,
          child: const Icon(CupertinoIcons.share),
        ),
      ),
      child: Center(
        child: Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    _isLoading
        ? const CupertinoActivityIndicator()
        : _pdfDocument != null
            ? Expanded(
                child: PDFViewer(document: _pdfDocument!),
              )
            : _showErrorDialogAndRetry(), // Call the method to show error dialog
  ],
),

      ),
    );
  }
}
