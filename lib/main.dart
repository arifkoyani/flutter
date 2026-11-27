import 'package:material_ui/material_ui.dart';
import 'data/levels_data.dart';
import 'database/game_database.dart';
import 'screens/splash_screen.dart';
import 'services/audio_service.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioService.instance.init();
  await PreferencesService.instance.init();
  await GameDatabase.instance.init();
  await LevelsData.load();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static const Color primaryOrange = Color(0xFFFF550D);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AudioService.instance.handleAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amaze GO',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: MyApp.primaryOrange,
          secondary: MyApp.primaryOrange,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
