import 'dart:io';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;

class PdfGeneratorPage extends StatefulWidget {
  final Map<String, dynamic> submitForm; // Form data

  const PdfGeneratorPage({super.key, required this.submitForm});

  @override
  _PdfGeneratorPageState createState() => _PdfGeneratorPageState();
}

class _PdfGeneratorPageState extends State<PdfGeneratorPage> {

  PDFDocument? _pdfDocument;
  bool _isLoading = true;
  File? _pdfFile;

  @override
  void initState() {
    super.initState();
    _loadPdfFromAssets();
  }

  Future<void> _loadPdfFromAssets() async {
    try {
      // Load the PDF file from assets
      final ByteData data = await rootBundle.load('assets/VisitedATC.pdf');
      final Uint8List bytes = data.buffer.asUint8List();

      // Save the PDF to the device's temporary directory
      final output = await getTemporaryDirectory();
      final file = File("${output.path}/VisitedATC.pdf");
      await file.writeAsBytes(bytes);

      // Load the saved PDF into PDFDocument for the viewer
      PDFDocument doc = await PDFDocument.fromFile(file);

      setState(() {
        _pdfDocument = doc;
        _isLoading = false;
        _pdfFile = file;
      });
    } catch (e) {
      print("Error loading PDF: $e");
    }
  }

  // Method to generate the PDF using form data and images
  // Future<void> _generatePdf() async {
  //   try {
  //     // Load the existing ATC.pdf as the template
  //     final ByteData bytes = await rootBundle.load('assets/ATC.pdf'); // Ensure ATC.pdf is in assets
  //     final Uint8List pdfTemplateBytes = bytes.buffer.asUint8List();

  //     // Add a page using the loaded template
  //     pdf.addPage(
  //       pw.Page(
  //         build: (pw.Context context) {
  //           return pw.Stack(
  //             children: [
  //               pw.Image(
  //                 pw.MemoryImage(pdfTemplateBytes),
  //                 fit: pw.BoxFit.cover,
  //                 width: PdfPageFormat.a4.width,
  //                 height: PdfPageFormat.a4.height,
  //               ),
  //               // Overlay the text fields on top of the PDF
  //               pw.Positioned(
  //                 left: 100, // Adjust position based on ATC.pdf layout
  //                 top: 100,
  //                 child: pw.Text("Site Name: ${widget.submitForm['siteName']}",
  //                     style: const pw.TextStyle(fontSize: 12)),
  //               ),
  //               pw.Positioned(
  //                 left: 100,
  //                 top: 150,
  //                 child: pw.Text("Site Number: ${widget.submitForm['siteNumber']}",
  //                     style: const pw.TextStyle(fontSize: 12)),
  //               ),
  //               pw.Positioned(
  //                 left: 100,
  //                 top: 200,
  //                 child: pw.Text("Contractor: ${widget.submitForm['contractor']}",
  //                     style: const pw.TextStyle(fontSize: 12)),
  //               ),
  //               pw.Positioned(
  //                 left: 100,
  //                 top: 250,
  //                 child: pw.Text("Tech's Initials: ${widget.submitForm['techInitials']}",
  //                     style: const pw.TextStyle(fontSize: 12)),
  //               ),
  //               pw.Positioned(
  //                 left: 100,
  //                 top: 300,
  //                 child: pw.Text("Date: ${widget.submitForm['selectedDate']}",
  //                     style: const pw.TextStyle(fontSize: 12)),
  //               ),
  //               pw.Positioned(
  //                 left: 100,
  //                 top: 350,
  //                 child: pw.Text("Main Comments: ${widget.submitForm['mainComments']}",
  //                     style: const pw.TextStyle(fontSize: 12)),
  //               ),
  //             ],
  //           );
  //         },
  //       ),
  //     );

  //     // Add a new page for each photo
  //     if (widget.submitForm['photos'] != null) {
  //       List<File> photos = widget.submitForm['photos'];
  //       for (var photo in photos) {
  //         final image = pw.MemoryImage(photo.readAsBytesSync());

  //         pdf.addPage(
  //           pw.Page(
  //             pageFormat: PdfPageFormat.a4,
  //             build: (pw.Context context) {
  //               return pw.Center(
  //                 child: pw.Image(image, width: PdfPageFormat.a4.width, height: PdfPageFormat.a4.height),
  //               );
  //             },
  //           ),
  //         );
  //       }
  //     }

  //     // Save the generated PDF to a temporary directory
  //     final output = await getTemporaryDirectory();
  //     final file = File("${output.path}/generated_site_closeout.pdf");
  //     await file.writeAsBytes(await pdf.save());
      

  //     setState(() {
  //       _pdfFile = file;
  //     });

  //     // Load the PDF document to display it in the app
  //     await _loadPdfDocument();
  //   } catch (e) {
  //     // Log the error
  //     print("Error generating PDF: $e");
  //   }
  // }

  // Load the generated PDF file into a PDFDocument to display in the PDF viewer
  // Future<void> _loadPdfDocument() async {
  //   if (_pdfFile != null) {
  //     try {
  //       PDFDocument doc = await PDFDocument.fromFile(_pdfFile!);

  //       setState(() {
  //         _pdfDocument = doc;
  //         _isLoading = false;
  //       });
  //     } catch (e) {
  //       print("Error loading PDF for preview: $e");
  //     }
  //   }
  // }

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
      appBar: AppBar(
        title: const Text('PDF Generator'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _pdfDocument != null
                  ? PDFViewer(
                      document: _pdfDocument!,
                    )
                  : const Text('Failed to load PDF'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 36),
              child: ElevatedButton(
                onPressed: _sharePdf, // Save and share the PDF
                child: const Text('Share/Save PDF'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
