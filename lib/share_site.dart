import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' as services;
import 'package:image/image.dart' as img;

class PdfGeneratorPage extends StatefulWidget {
  final Map<String, dynamic> submitForm; // Form data

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

  Future<void> _fillExistingPdfForm(File pdfFile) async {
  try {
    // Load the existing PDF document from the file
    final PdfDocument document = PdfDocument(inputBytes: pdfFile.readAsBytesSync());

    // Loop through the fields using the count and access fields by index
    for (int i = 0; i < document.form.fields.count; i++) {
      var field = document.form.fields[i];

      if (field is PdfTextBoxField) {
        // Handle text box fields
        switch (field.name) {
          case 'siteName':
            field.text = widget.submitForm['siteName'] ?? '';
            break;
          case 'siteNumber':
            field.text = widget.submitForm['siteNumber'] ?? '';
            break;
          case 'contractor':
            field.text = widget.submitForm['contractor'] ?? '';
            break;
          case 'techInitials':
            field.text = widget.submitForm['techInitials'] ?? '';
            break;
          case 'selectedDate':
            field.text = widget.submitForm['selectedDate'] ?? '';
            break;
        }
      } else if (field is PdfCheckBoxField) {
        // Handle checkbox fields
        switch (field.name) {
          case 'mainCheckbox1':
            field.isChecked = widget.submitForm['mainCheckbox'][0] ?? false;
            break;
          case 'mainCheckbox2':
            field.isChecked = widget.submitForm['mainCheckbox'][1] ?? false;
            break;
          case 'mainCheckbox3':
            field.isChecked = widget.submitForm['mainCheckbox'][2] ?? false;
            break;
          // Add more cases if there are additional checkboxes
        }
      }
      // You can handle other field types (e.g., radio buttons) similarly.
    }

    // Add photos to the PDF at the end of the file
    if (widget.submitForm['photos'] != null) {
      await _addPhotosToPdf(document, widget.submitForm['photos']);
    }

    // Save the filled PDF to a new file
    final outputDir = await getTemporaryDirectory();
    final filledPdfFile = File("${outputDir.path}/filled_act_form_with_photos.pdf");
    await filledPdfFile.writeAsBytes(await document.save());


    setState(() {
      _pdfFile = filledPdfFile;
      _isLoading = false;
    });

    // Load the filled PDF for viewing
    _pdfDocument = await PDFDocument.fromFile(_pdfFile!);

    // document.dispose();
  } catch (e) {
    print("Error filling PDF: $e");
  }
}

  Future<void> _addPhotosToPdf(PdfDocument document, List<File> photos) async {
    for (var photo in photos) {
      // Create a new page for each photo
      PdfPage page = document.pages.add();

      // Load the image from file
      final Uint8List imageBytes = await photo.readAsBytes();
      img.Image? decodedImage = img.decodeImage(imageBytes);

      if (decodedImage != null) {
        // Convert the image to PdfBitmap
        PdfBitmap pdfImage = PdfBitmap(imageBytes);

        // Get the page dimensions
        double pageWidth = page.getClientSize().width;
        double pageHeight = page.getClientSize().height;

        // Calculate the aspect ratio of the image and the page
        double imageAspectRatio = decodedImage.width / decodedImage.height;
        double pageAspectRatio = pageWidth / pageHeight;

        double drawWidth, drawHeight;

        // Determine whether to scale by width or height to maintain the aspect ratio
        if (imageAspectRatio > pageAspectRatio) {
          // Image is wider than the page, scale by width
          drawWidth = pageWidth;
          drawHeight = pageWidth / imageAspectRatio;
        } else {
          // Image is taller than the page, scale by height
          drawHeight = pageHeight;
          drawWidth = pageHeight * imageAspectRatio;
        }

        // Calculate the position to center the image on the page
        double xPosition = (pageWidth - drawWidth) / 2;
        double yPosition = (pageHeight - drawHeight) / 2;

        // Draw the image on the page, centered and scaled to fit
        page.graphics.drawImage(
          pdfImage,
          Rect.fromLTWH(xPosition, yPosition, drawWidth, drawHeight),
        );
      }
    }
  }

  // Share the generated PDF
  Future<void> _sharePdf() async {
    if (_pdfFile != null) {
      Share.shareXFiles([XFile(_pdfFile!.path)]);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF generated yet!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Generator')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isLoading
                ? const CircularProgressIndicator()
                : _pdfDocument != null
                    ? Expanded(child: PDFViewer(document: _pdfDocument!))
                    : const Text('Failed to load PDF'),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 36),
              child: ElevatedButton(
                onPressed: _sharePdf,
                child: const Text('Share/Save PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
