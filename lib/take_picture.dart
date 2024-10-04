import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle, Uint8List;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:site_connect/providers.dart';



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

      // Ensure that the camera is initialized
      await _initializeControllerFuture;

      // Capture the image
      final image = await _controller.takePicture();

      // Process the image (add watermark and timestamp)
      final processedImage = await _processImage(File(image.path));

      // Add processed image to the list and update the UI
      setState(() {
        _capturedImages.add(processedImage);
      });
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<Position> _getUserLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled, return an error
    return Future.error('Location services are disabled.');
  }

  // Check for location permissions
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, return an error
      return Future.error('Location permissions are denied.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, return an error
    return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  }

  // Get the current location
  return await Geolocator.getCurrentPosition();
  }

  Future<Map<String, String>> _getAddressFromLatLng(Position position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
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

  Future<File> _processImage(File imageFile) async {
    // Get the path to save the new image
    final outputPath = await _getNewImagePath();

    // Load the watermark image from the assets
    final ByteData data = await rootBundle.load('assets/GRC.png');
    final Uint8List watermarkBytes = data.buffer.asUint8List();
   
    // final img.Image? watermarkImage = img.decodeImage(watermarkBytes);
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd h:mm a').format(now);
    // get geolocation in lat long
    Position position = await _getUserLocation();
    String location = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    
    // Get the address from the coordinates
    Map<String, String> address = await _getAddressFromLatLng(position);
    String city = address['city'] ?? '';
    String state = address['state'] ?? '';
    String zip = address['zip'] ?? '';
    String country = address['country'] ?? '';
    String addressString = '$city, $state, $zip';

    final command = img.Command()
      ..decodeImageFile(imageFile.path)
      // ..copyResize(width: 800)

      // 5/16/2023 12:00:00
      ..drawString(
        formattedDate,
        font: img.arial24,
        x: 460,
        y: 40, 
      )
      // Lat Long, 6 decimal places
      ..drawString(
        location,
        font: img.arial24,
        x: 428,
        y: 65, 
      )
      // City, State, Zip
      ..drawString(
        addressString,
        font: img.arial24,
        x: 460,
        y: 90, 
      )
      // Country
      ..drawString(
        country,
        font: img.arial24,
        x: 544,
        y: 115, 
      )

      // Composite the watermark image (if available)
      ..compositeImage(
        img.Command()
          ..decodeImage(watermarkBytes),
        dstX: 435, // Adjust positioning as needed
        dstY: 1080, // Bottom-right corner
        blend: img.BlendMode.alpha,  // Apply alpha blending
      );

    // Save the processed image as PNG to outputPath
    command.writeToFile(outputPath);

    await command.executeThread();

    return File(outputPath);
  }

  // Function to get a new file path for processed image
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
    // Pop the screen and return the captured images
    Navigator.pop(context, _capturedImages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Picture'),
      actions: [
        IconButton(
          icon: const Icon(Icons.check),
          onPressed: _finishAndReturnImages,
        ),
      ]),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Camera Preview
            Container(
              color: Colors.black,
              child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SizedBox(
                        width: MediaQuery.sizeOf(context).width,
                        height: MediaQuery.sizeOf(context).height * 0.61,
                        child: CameraPreview(_controller),
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),

            // Capture Button
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: _captureAndProcessImage,
                child: const Icon(
                  color: Colors.black,
                  Icons.camera_alt,
                  size: 26,
                ),
              ),
            ),

            // Display Captured Images
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.15,
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 3,
                    ),
                    itemCount: _capturedImages.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ImagePreviewScreen(
                                image: _capturedImages[index],
                                onDelete: () => _removeImage(_capturedImages[index]),
                              ),
                            ),
                          );
                        },
                        child: Image.file(_capturedImages[index], fit: BoxFit.fill),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final File image;
  final VoidCallback onDelete;

  const ImagePreviewScreen({super.key, required this.image, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              onDelete(); // This will trigger the delete function in the parent
              Navigator.pop(context); // Close the preview after deletion
            },
          ),
        ],
      ),
      body: SizedBox(
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

