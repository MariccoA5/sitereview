import 'dart:io';

import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:field_report/at_site_closeout.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileEntry {
  final String id;
  final String title;
  final String thumbnailPath;
  bool isOnline;
  DateTime timestamp;
  bool locationAvailable;
  Position? location;

  FileEntry({
    required this.id,
    required this.title,
    required this.thumbnailPath,
    this.isOnline = false,
    required this.timestamp,
    this.locationAvailable = false,
    this.location,
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



  void _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete(); // Delete the file from the file system

        setState(() {
          // Remove the file from _fileEntries
          _fileEntries.removeWhere((entry) => entry.id == filePath);
        });
      }
    } catch (e) {
      print('Error deleting file: $e');
      // Optionally, show a dialog to notify the user of the error
    }
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

  Future<void> _updateOfflineFilesWithLocation() async {
    for (var file in _fileEntries) {
      if (!file.isOnline && !file.locationAvailable) {
        try {
          Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high);

          setState(() {
            // Update file with location data
            file.location = position;
            file.locationAvailable = true;
            file.isOnline = true; // Mark it as now updated with online data
          });

          // Optionally, sync this update to cloud storage or database
          // await _syncFileLocation(file);
        } catch (e) {
          print("Error retrieving location for file ${file.id}: $e");
        }
      }
    }
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
    final List<FileSystemEntity> files =
        await directory.list().toList(); // Asynchronous file listing
    List<FileEntry> fileEntries = [];

    for (var file in files) {
      if (file is File && file.path.endsWith('.pdf')) {
        final String fileName = file.path.split('/').last;

        // You can create a thumbnail or use a placeholder image
        String thumbnailPath = 'assets/PDFLOGO.png'; // Placeholder for PDF logo

        try {
          // Get file's last modified time
          DateTime lastModified =
              await file.lastModified(); // Asynchronous call

          // Add file entry
          fileEntries.add(FileEntry(
            id: file.path,
            title: fileName,
            thumbnailPath: thumbnailPath,
            isOnline: false, // Default to false for offline mode
            timestamp: lastModified, // File's last modified timestamp
          ));
        } catch (e) {
          print(
              "Error retrieving last modified time for file ${file.path}: $e");
        }
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
    //result != null && result == 'saved'
    if (result == 'saved') {
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
      onTap: () async {
        // Open the PDF file
        final result = await Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            builder: (context) => PdfViewerPage(filePath: file.id),
          ),
        );
        if (result != null && result is String) {
          _deleteFile(result); // Call the delete method with the file path
          _loadFileEntries(); // Refresh the file entries
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

  const PdfViewerPage({super.key, required this.filePath});

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
            title: const Text('Error'),
            content: const Text('Failed to load PDF.'),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('OK'),
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
          title: const Text('Delete PDF'),
          content: const Text(
              'Are you sure you want to delete this PDF? This action cannot be undone.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false); // Return false
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Delete'),
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
      // Instead of deleting the file here, just return to HistoryPage with confirmation
      Navigator.of(context)
          .pop(widget.filePath); // Return the filePath to be deleted
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
