
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Providers {
  final SupabaseClient supabaseClient;
  final CameraDescription camera;

  Providers({
    required this.supabaseClient,
    required this.camera,
  });
}