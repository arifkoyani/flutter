import 'package:material_ui/material_ui.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryOrange = Color(0xFFFF550D);

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
          primary: primaryOrange,
          secondary: primaryOrange,
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
