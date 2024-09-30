import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:site_connect/at_site_closeout.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://wtzgjzinkqbxnierobum.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0emdqemlua3FieG5pZXJvYnVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc2NzI4NDUsImV4cCI6MjA0MzI0ODg0NX0.dBzXj8ULNUenZSFAb6MsSjp9rksCVM_pB476XtQMVjU',
  );
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(camera: firstCamera,));
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




