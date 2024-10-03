import 'dart:io';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:pdf/widgets.dart' as pw;

import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cross_file/cross_file.dart';



class PdfGeneratorPage extends StatefulWidget {
  final Map<String, dynamic> submitForm; // Form data

  const PdfGeneratorPage({super.key, required this.submitForm});

  @override
  _PdfGeneratorPageState createState() => _PdfGeneratorPageState();
}

class _PdfGeneratorPageState extends State<PdfGeneratorPage> {
  final pdf = pw.Document();
  File? _pdfFile;
  PDFDocument? _pdfDocument;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Automatically generate the PDF when the page loads
    _generatePdf();
  }

  // Method to generate the PDF using form data and images
  Future<void> _generatePdf() async {
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text("Site Name: ${widget.submitForm['site_name']}"),
              pw.Text("Site Number: ${widget.submitForm['site_number']}"),
              pw.Text("Contractor: ${widget.submitForm['contractor']}"),
              pw.Text("Tech's Initials: ${widget.submitForm['techs_initals']}"),
              pw.Text("Date: ${widget.submitForm['created_at']}"),
              pw.Text("Comments: ${widget.submitForm['comments']}"),
              pw.SizedBox(height: 20),
              // Attach photos
              pw.Text('Attached Photos:'),
              for (var photo in widget.submitForm['photos'] as List<dynamic>)
                pw.Image(pw.MemoryImage(photo.readAsBytesSync()), height: 150, width: 150),
            ],
          );
        },
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/generated_site_closeout.pdf");
    await file.writeAsBytes(await pdf.save());

    setState(() {
      _pdfFile = file;
    });

    // Load the PDF document to display it in the app
    await _loadPdfDocument();
  }

  // Load the generated PDF file into a PDFDocument to display in the PDF viewer
  Future<void> _loadPdfDocument() async {
    if (_pdfFile != null) {
      PDFDocument doc = await PDFDocument.fromFile(_pdfFile!);
      setState(() {
        _pdfDocument = doc;
        _isLoading = false;
      });
    }
  }

  // Share or save the PDF
  Future<void> _sharePdf() async {
    if (_pdfFile != null) {
      // Share the PDF file
      Share.shareXFiles([XFile(_pdfFile!.path)], text: "Here's the completed site closeout PDF.");

      // Save to Supabase when sharing/saving
      await _saveToSupabase();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No PDF generated yet!')),
      );
    }
  }

  // Save form data and photos to Supabase when user shares/saves the PDF
  Future<void> _saveToSupabase() async {
    final supabaseClient = Supabase.instance.client; // Your Supabase client

    try {
      // Save form data and images to Supabase
      await supabaseClient
        .from('at_site_closeout')
        .insert({
          'contractor': widget.submitForm['contractor'],
          'techs_initals': widget.submitForm['techs_initals'],
          'main_checkbox': widget.submitForm['main_checkbox'],
          'main_comments': widget.submitForm['main_comments'],
          'iai_checkbox': widget.submitForm['iai_checkbox'],
          'iai_comments': widget.submitForm['iai_comments'],
          'oosw_checkbox': widget.submitForm['oosw_checkbox'],
          'oosw_comments': widget.submitForm['oosw_comments'],
          'photos': widget.submitForm['photos'],
        })
        .select();
        

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form and photos saved to Supabase!')),
      );
    } catch (e) {
      print('Error saving to Supabase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save to Supabase: $e')),
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
            // PDF Viewer
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pdfDocument != null
                      ? PDFViewer(
                          document: _pdfDocument!,
                        )
                      : const Text('Failed to load PDF'),
            ),
            // Share/Save Button
            ElevatedButton(
              onPressed: _sharePdf, // Save and share the PDF
              child: const Text('Share/Save PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
