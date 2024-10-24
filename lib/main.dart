import 'package:field_report/history_page.dart';
import 'package:field_report/fileupload.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers.dart';
import 'package:feedback/feedback.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://wtzgjzinkqbxnierobum.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind0emdqemlua3FieG5pZXJvYnVtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc2NzI4NDUsImV4cCI6MjA0MzI0ODg0NX0.dBzXj8ULNUenZSFAb6MsSjp9rksCVM_pB476XtQMVjU',
  );

  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  // Create Supabase client instance
  final supabase = Supabase.instance.client;

  runApp(
    BetterFeedback(
      child: MultiProvider(
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
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'Field Report',
      theme: const CupertinoThemeData(
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.today),
              label: 'Reports',
            ),
            BottomNavigationBarItem(
              icon: Icon(CupertinoIcons.upload_circle),
              label: 'Upload',
            ),
          ],
        ),
        tabBuilder: (context, index) {
          switch (index) {
            case 0:
              return CupertinoTabView(
                builder: (context) => const HistoryPage(),
              );
            case 1:
              return CupertinoTabView(
                builder: (context) => const FileUploadPage(),
              );
            default:
              return CupertinoTabView(
                builder: (context) => const HistoryPage(),
              );
          }
        },
      ),
    );
  }
}