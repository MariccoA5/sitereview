import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:site_connect/take_picture.dart';
import 'package:site_connect/at_site_closeout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;
  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera Watermark App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SiteCloseoutForm()//TakePictureScreen(camera: camera),
    );
  }
}




