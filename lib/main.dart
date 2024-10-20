import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:field_report/at_site_closeout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://wtzgjzinkqbxnierobum.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0emdqemlua3FieG5pZXJvYnVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc2NzI4NDUsImV4cCI6MjA0MzI0ODg0NX0.dBzXj8ULNUenZSFAb6MsSjp9rksCVM_pB476XtQMVjU',
  );
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  final supabase = Supabase.instance.client;

  runApp(
    MultiProvider(
      providers: [
        Provider<Providers>(
          create: (_) => Providers(
            supabaseClient: supabase,
            camera: firstCamera,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Field Report',
      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
        barBackgroundColor: CupertinoColors.white,
      ),
      home: SiteCloseoutForm(), 
    );
  }
}