
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:field_report/providers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';

import 'package:provider/provider.dart';

import 'package:path/path.dart' as path;

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  _FileUploadPageState createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  bool _isUploading = false; // Tracks if an upload is in progress
  bool _isConnected = true; // Tracks internet connectivity
  late Providers providers;


  @override
  void initState() {
    super.initState();
    _checkInitialConnectivity();
    _startConnectivityListener();
  }

  @override
  void dispose() {
    // No need to dispose the connectivity stream as it's handled by the package
    super.dispose();
  }

  // Check initial connectivity status
  Future<void> _checkInitialConnectivity() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });
  }

  // Listen to connectivity changes
  Future<void> _startConnectivityListener() async {
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (!results.contains(ConnectivityResult.none)) {
        setState(() {
          _isConnected = true;
        });
      }
    });
  }


  // Function to handle file selection and upload
  Future<void> _selectAndUploadFile() async {
    if (!_isConnected) {
      // If not connected, show a Cupertino dialog
      _showOfflineDialog();
      return;
    }

    // Let the user pick a file
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      // Optional: Validate file type and size
      // Example: Allow only specific extensions and limit file size to 10MB
      const int maxFileSize = 10 * 1024 * 1024; // 10MB
      List<String> allowedExtensions = ['pdf']; // Adjust as needed

      String fileExtension = path.extension(fileName).replaceAll('.', '').toLowerCase();

      if (file.lengthSync() > maxFileSize) {
        _showErrorDialog('File size exceeds the maximum allowed limit of 10MB.');
        return;
      }

      if (!allowedExtensions.contains(fileExtension)) {
        _showErrorDialog('Unsupported file type. Allowed types: pdf');
        return;
      }

      // Show uploading state
      setState(() {
        _isUploading = true;
      });

      // Show a modal with wait icon and message
      showCupertinoDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissal
        builder: (context) {
          return const CupertinoAlertDialog(
            title: Text('Uploading'),
            content: Column(
              children: [
                SizedBox(height: 10),
                CupertinoActivityIndicator(radius: 15),
                SizedBox(height: 20),
                Text('File is being uploaded...'),
              ],
            ),
          );
        },
      );

      try {
        // Get supabase provider for storage
        

        // Generate a unique file path or use the file name
        String filePath = 'user_uploads/${DateTime.now().millisecondsSinceEpoch}_${fileName}'; // Example path

        

        
        // Close the uploading dialog
        Navigator.of(context).pop();

        // Show success dialog
        _showSuccessDialog('fileUrl');
      } catch (e) {
        // Close the uploading dialog
        Navigator.of(context).pop();

        // Show error dialog
        _showErrorDialog(e.toString());
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    } else {
      // User canceled the picker
    }
  }

  // Show a dialog when offline
  void _showOfflineDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('No Internet Connection'),
        content: const Text('Please connect to the internet to upload files.'),
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

  // Show a success dialog
  void _showSuccessDialog(String? fileUrl) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Upload Successful'),
        content: const Text('Your file has been uploaded and is being processed.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    // Optionally, you can display the file URL or perform other actions
    // For example:
    // if (fileUrl != null) {
    //   print('File available at: $fileUrl');
    // }
  }

  // Show an error dialog
  void _showErrorDialog(String errorMessage) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Upload Failed'),
        content: Text('An error occurred: $errorMessage'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Retry'),
            onPressed: () {
              Navigator.of(context).pop();
              _selectAndUploadFile(); // Retry upload
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Dismiss keyboard on tap or horizontal swipe
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      onHorizontalDragEnd: (details) {
        FocusScope.of(context).unfocus();
      },
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Upload Files'),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  const Text(
                    'Upload a file to create a new workflow.',
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  Opacity(
                    opacity: 0.5,
                    child: CupertinoButton.filled(
                      focusColor: CupertinoColors.systemGrey,
                      disabledColor: CupertinoColors.systemGrey,
                      child: _isUploading
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                CupertinoActivityIndicator(radius: 10),
                                SizedBox(width: 10),
                                Text('Uploading...'),
                              ],
                            )
                          : const Text('Coming Soon'),
                      onPressed: () {}
                      // _isUploading ? null : _selectAndUploadFile,
                      
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (!_isConnected)
                    const Text(
                      'You are offline. Please connect to the internet to upload files.',
                      style: TextStyle(color: CupertinoColors.systemRed),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
