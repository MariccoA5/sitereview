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
      if (permission == LocationPermission.denied) return Future.error('Location permissions are denied.');
    }
    if (permission == LocationPermission.deniedForever) return Future.error('Location permissions are permanently denied.');
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
    final outputPath = await _getNewImagePath();
    final ByteData data = await rootBundle.load('assets/GRC.png');
    final Uint8List watermarkBytes = data.buffer.asUint8List();
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd h:mm a').format(now);
    Position position = await _getUserLocation();
    String location = '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    Map<String, String> address = await _getAddressFromLatLng(position);
    String addressString = '${address['city']}, ${address['state']}, ${address['zip']}';

    final command = img.Command()
      ..decodeImageFile(imageFile.path)
      ..drawString(formattedDate, font: img.arial24, x: 460, y: 40)
      ..drawString(location, font: img.arial24, x: 428, y: 65)
      ..drawString(addressString, font: img.arial24, x: 460, y: 90)
      ..drawString(address['country'] ?? '', font: img.arial24, x: 544, y: 115)
      ..compositeImage(img.Command()..decodeImage(watermarkBytes), dstX: 435, dstY: 1080, blend: img.BlendMode.alpha);

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
        middle: const Text('Take Picture'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _finishAndReturnImages,
          child: const Icon(CupertinoIcons.check_mark),
          
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              color: CupertinoColors.black,
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
                    return const Center(child: CupertinoActivityIndicator());
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: CupertinoButton.filled(
                onPressed: _captureAndProcessImage,
                child: const Icon(CupertinoIcons.camera, color: CupertinoColors.white),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.15),
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
                            CupertinoPageRoute(
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
