import 'dart:io';

import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:field_report/at_site_closeout.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileEntry {
  final String id;
  final String title;
  final String thumbnailPath;
  bool isOnline; // Indicates if the file is synced online

  FileEntry({
    required this.id,
    required this.title,
    required this.thumbnailPath,
    this.isOnline = false,
  });
}

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<FileEntry> _fileEntries = [];
  // bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _loadFileEntries();
    _startConnectivityListener();
  }



  Future<void> _loadFileEntries() async {
    List<FileEntry> localFiles = await _loadLocalFiles();
    List<FileEntry> onlineFiles = await _loadOnlineFiles();

    setState(() {
      _fileEntries = [...localFiles, ...onlineFiles];
    });
  }

  Future<void> _startConnectivityListener() async {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        _syncOfflineFiles();
      }
    });
  }

  Future<void> _syncOfflineFiles() async {
    List<FileEntry> unsyncedFiles =
        _fileEntries.where((file) => !file.isOnline).toList();
    for (var file in unsyncedFiles) {
      bool success = await _uploadFileToCloud(file);
      if (success) {
        setState(() {
          file.isOnline = true;
        });
      }
    }
  }

  Future<bool> _uploadFileToCloud(FileEntry file) async {
    // Implement your upload logic here
    // Return true if successful
    return true;
  }

  Future<List<FileEntry>> _loadLocalFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = directory.listSync();
    List<FileEntry> fileEntries = [];

    for (var file in files) {
      if (file is File && file.path.endsWith('.pdf')) {
        final String fileName = file.path.split('/').last;

        // You can create a thumbnail or use a placeholder image
        String thumbnailPath = 'assets/PDFLOGO.png'; // Use an appropriate image

        fileEntries.add(FileEntry(
          id: file.path,
          title: fileName,
          thumbnailPath: thumbnailPath,
          isOnline: false, // Update this based on your synchronization logic
        ));
      }
    }

    return fileEntries;
  }

  Future<List<FileEntry>> _loadOnlineFiles() async {
    bool isConnected = await _isConnected();
    if (isConnected) {
      // Fetch files from cloud storage
      return await _fetchFilesFromCloud();
    } else {
      return [];
    }
  }

  Future<bool> _isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<List<FileEntry>> _fetchFilesFromCloud() async {
    // Fetch files from Supabase or your cloud storage
    // For now, return an empty list
    return [];
  }

  void _navigateToCreateReport() async {
    final result = await Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(builder: (context) => const SiteCloseoutForm()),
    );
    if (result != null && result == 'saved') {
      setState(() {
        _loadFileEntries(); // Refresh data or change state variables
      });
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'No Field Reports Yet',
            style: TextStyle(
              fontSize: 20,
              color: CupertinoColors.inactiveGray,
            ),
          ),
          const SizedBox(height: 20),
          CupertinoButton.filled(
            onPressed: _navigateToCreateReport,
            child: const Text('Create New Field Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileGridView() {
    return Column(
      children: [
        Expanded(
          child: _buildGridView(),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: _fileEntries.length,
        itemBuilder: (context, index) {
          final file = _fileEntries[index];
          return _buildFileCard(file);
        },
      ),
    );
  }


  Widget _buildFileCard(FileEntry file) {
    return GestureDetector(
              onTap: () {
          // Open the PDF file
          final result = Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => PdfViewerPage(filePath: file.id),
            ),
          );
          if (result == 'delete') {
            // A file was deleted, refresh the list
            setState(() {
              _loadFileEntries();
            });
          }
        },

      child: Container(
        padding: const EdgeInsets.fromLTRB(8.0, 8.0, 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                file.thumbnailPath,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                file.title,
                style: const TextStyle(fontSize: 16.0),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
          // leading: CupertinoButton(
          //   padding: EdgeInsets.zero,
          //   child: const Icon(size: 33, CupertinoIcons.ant_circle),
          //   onPressed: () {},
          // ),
          middle: const Text('History'),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _navigateToCreateReport,
            child: const Icon(CupertinoIcons.add),
          )),
      child: _fileEntries.isEmpty ? _buildEmptyState() : _buildFileGridView(),
    );
  }
}


class PdfViewerPage extends StatefulWidget {
  final String filePath;

  const PdfViewerPage({Key? key, required this.filePath}) : super(key: key);

  @override
  _PdfViewerPageState createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  bool _isLoading = true;
  PDFDocument? _document;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      PDFDocument document = await PDFDocument.fromFile(File(widget.filePath));
      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading PDF: $e');
      setState(() {
        _isLoading = false;
      });
      // Show error dialog
      await showCupertinoDialog(
        context: context,
        builder: (BuildContext context) {
          return CupertinoAlertDialog(
            title: Text('Error'),
            content: Text('Failed to load PDF.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _sharePdf() {
    Share.shareXFiles([XFile(widget.filePath)]);
  }

  void _deletePdf() async {
    // Show a confirmation dialog
    bool? confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text('Delete PDF'),
          content: Text(
              'Are you sure you want to delete this PDF? This action cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text('Delete'),
              onPressed: () {
                // Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(true); // Return true
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      // Proceed to delete the file
      try {
        final file = File(widget.filePath);
        if (await file.exists()) {
          await file.delete();
        }

        Navigator.of(context).pop('delete');
      } catch (e) {
        print('Error deleting file: $e');
        // Show an error message to the user
        await showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return CupertinoAlertDialog(
              title: Text('Error'),
              content: Text('An error occurred while deleting the PDF.'),
              actions: [
                CupertinoDialogAction(
                  isDefaultAction: true,
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.filePath.split('/').last),
        trailing: Row(
          mainAxisSize: MainAxisSize.min, // Ensures Row takes minimal space
          children: [
            CupertinoButton(
              padding: const EdgeInsets.fromLTRB(0, 0, 16, 0),
              onPressed: _deletePdf,
              child: const Icon(CupertinoIcons.trash),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _sharePdf,
              child: const Icon(CupertinoIcons.share),
            ),
          ],
        ),
      ),
      child: Center(
        child: _isLoading
            ? const CupertinoActivityIndicator()
            : PDFViewer(document: _document!),
      ),
    );
  }
}
