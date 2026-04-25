import 'common_import.dart';

late SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Obtain shared preferences.
  prefs = await SharedPreferences.getInstance();
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyB0-l7Q3HrrVZbNmhUjOnBBgmVuJd2K9uA",
          authDomain: "fir-project-f9280.firebaseapp.com",
          projectId: "fir-project-f9280",
          storageBucket: "fir-project-f9280.firebasestorage.app",
          messagingSenderId: "1034915017442",
          appId: "1:1034915017442:web:92cbc9c74e2b5323d564bb"
      ),
    );
  // }
  runApp(const MyApp());
}


