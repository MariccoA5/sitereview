import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle, Uint8List;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:field_report/providers.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class TakePictureScreen extends StatefulWidget {
  final List<File>? existingImages;
  const TakePictureScreen({super.key, this.existingImages});

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  List<File> _capturedImages = [];
  late Providers providers;

  @override
  void initState() {
    super.initState();
    providers = Provider.of<Providers>(context, listen: false);
    _controller = CameraController(providers.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
    if (widget.existingImages != null) {
      _capturedImages = List.from(widget.existingImages!);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcessImage() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      final processedImage = await _processImage(File(image.path));
      setState(() {
        _capturedImages.add(processedImage);
      });
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<Position> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('Location services are disabled.');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }
    return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, String>> _getAddressFromLatLng(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      return {
        'city': place.locality ?? '',
        'state': place.administrativeArea ?? '',
        'zip': place.postalCode ?? '',
        'country': place.country ?? '',
      };
    }
    return {
      'city': '',
      'state': '',
      'zip': '',
      'country': '',
    };
  }

  Future<bool> _isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    return connectivityResult != ConnectivityResult.none;
  }

  Future<File> _processImage(File imageFile) async {
  final outputPath = await _getNewImagePath();
  final ByteData data = await rootBundle.load('assets/GRC.png');
  final Uint8List watermarkBytes = data.buffer.asUint8List();

  DateTime now = DateTime.now();
  String formattedDate = DateFormat('yyyy-MM-dd h:mm a').format(now);

  Position position;
  String location = '';
  String addressString = '';
  String country = '';
  bool isOffline = false;

  try {
    // Fetch the user location
    position = await _getUserLocation();
    location = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

    // Check if the device is online
    if (await _isConnected()) {
      // Fetch the address from the coordinates if online
      Map<String, String> address = await _getAddressFromLatLng(position);
      addressString = '${address['city']}, ${address['state']}, ${address['zip']}';
      country = address['country'].toString();
    } else {
      // If offline, only display the time and lat/long
      isOffline = true;
      addressString = '';
      country = '';
    }
  } catch (e) {
    // Handle location or address failures gracefully
    addressString = '';
    country = '';
    isOffline = true;
    print('Error fetching location or address: $e');
  }


  

  // Initialize the image processing command
  final command = img.Command()
    ..decodeImageFile(imageFile.path)
    ..drawString(formattedDate, font: img.arial24, x: 450, y: 40)
    ..drawString(location, font: img.arial24, x: 450, y: 65);

  // Conditionally display additional information if online
  if (!isOffline) {
    command
      ..drawString(addressString, font: img.arial24, x: 450, y: 90)
      ..drawString(country, font: img.arial24, x: 450, y: 115);
  }

  // Add watermark image
  command.compositeImage(img.Command()..decodeImage(watermarkBytes),
        dstX: 450, dstY: 1080, blend: img.BlendMode.alpha);

  // Write to file
  command.writeToFile(outputPath);
  await command.executeThread();

  return File(outputPath);
}

  Future<String> _getNewImagePath() async {
    final directory = await getTemporaryDirectory();
    return '${directory.path}/processed_image_${DateTime.now().millisecondsSinceEpoch}.png';
  }

  void _removeImage(File image) {
    setState(() {
      _capturedImages.remove(image);
    });
  }

  Future<void> _finishAndReturnImages() async {
    Navigator.pop(context, _capturedImages);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        backgroundColor:
            MediaQuery.of(context).platformBrightness == Brightness.dark
                ? CupertinoColors.black
                : CupertinoColors.white,
        middle: const Text('Take Picture'),
        leading: CupertinoButton(
          onPressed: () async {
            Navigator.pop(context, _capturedImages);
          },
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () async {
            await _finishAndReturnImages();
          },
          child: const Icon(CupertinoIcons.check_mark),
        ),
      ),
      child: Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return SizedBox(
                  width: MediaQuery.sizeOf(context).width,
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: CameraPreview(_controller),
                );
              } else {
                return const Center(child: CupertinoActivityIndicator());
              }
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
                child: CupertinoButton(
                  onPressed: () {
                    _showDeleteConfirmationDialog();
                  },
                  child: const Icon(CupertinoIcons.delete,
                      color: CupertinoColors.systemRed),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: CupertinoButton.filled(
                  onPressed: _captureAndProcessImage,
                  child: const Icon(CupertinoIcons.camera,
                      color: CupertinoColors.white),
                ),
              ),
              Text('Count: ${_capturedImages.length}'),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height *
                0.25, // Half of previous height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _capturedImages.length,
              itemBuilder: (context, index) {
                int reverseIndex = _capturedImages.length - 1 - index;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => ImagePreviewScreen(
                          image: _capturedImages[reverseIndex],
                          onDelete: () =>
                              _removeImage(_capturedImages[reverseIndex]),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width / 3.23,
                    margin: const EdgeInsets.only(
                        right: 3), // Spacing between images
                    child: Image.file(
                      _capturedImages[reverseIndex],
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

// Show confirmation dialog for deleting all photos
  void _showDeleteConfirmationDialog() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text("Delete All Photos?"),
          content: const Text(
              "Are you sure you want to delete all the photos? This action cannot be undone."),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog

                _deleteAllPhotos(); // Delete all photos
              },
            ),
            CupertinoDialogAction(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

// Function to delete all photos
  void _deleteAllPhotos() {
    setState(() {
      _capturedImages.clear(); // Clear the list of captured images
    });
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final File image;
  final VoidCallback onDelete;

  const ImagePreviewScreen(
      {super.key, required this.image, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double screenHeight = MediaQuery.sizeOf(context).height;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Preview'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.delete),
          onPressed: () {
            onDelete();
            Navigator.pop(context);
          },
        ),
      ),
      child: SizedBox(
        width: screenWidth,
        height: screenHeight,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(child: Image.file(image)),
        ),
      ),
    );
  }
}
