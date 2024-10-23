import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:field_report/at_site_closeout.dart';

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
  bool _isGridView = true;

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
    bool isConnected = await _isConnected();
    if (isConnected) {
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
  }

  Future<bool> _uploadFileToCloud(FileEntry file) async {
    // Implement your upload logic here
    // Return true if successful
    return true;
  }

  Future<List<FileEntry>> _loadLocalFiles() async {
    // Load files from local storage
    // For now, return an empty list
    return [];
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
      CupertinoPageRoute(builder: (context) => SiteCloseoutForm()),
    );
    if (result != null && result == 'deleted') {
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
          child: _isGridView ? _buildGridView() : _buildListView(),
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
      ),
      itemCount: _fileEntries.length,
      itemBuilder: (context, index) {
        final file = _fileEntries[index];
        return _buildFileCard(file);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: _fileEntries.length,
      itemBuilder: (context, index) {
        final file = _fileEntries[index];
        return _buildFileListTile(file);
      },
    );
  }

  Widget _buildFileCard(FileEntry file) {
    return GestureDetector(
      onTap: () {
        // Handle file tap
      },
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Expanded(
              child: Image.file(
                File(file.thumbnailPath),
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

  Widget _buildFileListTile(FileEntry file) {
    return GestureDetector(
      onTap: () {
        // Handle file tap
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        decoration: BoxDecoration(
          color: CupertinoColors.systemGrey6,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: ListTile(
          leading: Image.file(
            File(file.thumbnailPath),
            fit: BoxFit.cover,
            width: 50,
            height: 50,
          ),
          title: Text(file.title),
          trailing: file.isOnline
              ? const Icon(CupertinoIcons.cloud_upload_fill)
              : const Icon(CupertinoIcons.cloud_upload),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        leading: CupertinoButton(
                padding: EdgeInsets.zero,
                child: const Icon(
                  size: 33,
                  CupertinoIcons.ant_circle),

                onPressed: () {
                  
                },
              ),
        middle: const Text('History'),
        trailing: _fileEntries.isEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _navigateToCreateReport,
                child: const Icon(CupertinoIcons.add),
              )
            : CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(
                  _isGridView
                      ? CupertinoIcons.square_list
                      : CupertinoIcons.square_grid_2x2,
                ),
                onPressed: () {
                  setState(() {
                    _isGridView = !_isGridView;
                  });
                },
              ),
      ),
      child: _fileEntries.isEmpty ? _buildEmptyState() : _buildFileGridView(),
    );
  }
}
