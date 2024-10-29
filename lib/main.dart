import 'package:field_report/firebase_options.dart';
import 'package:field_report/history_page.dart';
import 'package:field_report/fileupload.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'providers.dart';
import 'package:feedback/feedback.dart';
import 'package:firebase_auth/firebase_auth.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await FirebaseAuth.instance.signInAnonymously();

  // Get available cameras
  final cameras = await availableCameras();
  final firstCamera = cameras.first;


  runApp(
    BetterFeedback(
      child: MultiProvider(
        providers: [
          Provider<Providers>(
            create: (_) => Providers(
             
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