import 'package:material_ui/material_ui.dart';
import 'screens/first_screen.dart';
import 'screens/second_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color primaryOrange = Color(0xFFFF550D);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Navigation App',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: primaryOrange,
          secondary: primaryOrange,
          surface: Colors.black,
        ),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF550D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Main Screen',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top accent icon
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: primaryOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: primaryOrange, width: 2),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    size: 50,
                    color: primaryOrange,
                  ),
                ),
                const SizedBox(height: 28),

                // Main Title
                const Text(
                  'Select a Screen',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose where you would like to navigate:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Button 1: Screen 1
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FirstScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.looks_one_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    label: const Text(
                      'Screen 1',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryOrange,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Button 2: Screen 2
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SecondScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.looks_two_rounded,
                      color: primaryOrange,
                      size: 24,
                    ),
                    label: const Text(
                      'Screen 2',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: primaryOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      side: const BorderSide(color: primaryOrange, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
