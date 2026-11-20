import 'package:material_ui/material_ui.dart';
import 'first_screen.dart';

class SecondScreen extends StatelessWidget {
  const SecondScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryOrange = Color(0xFFFF550D);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryOrange),
        title: const Text(
          'Screen 2',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Badge
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: primaryOrange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: primaryOrange, width: 2),
                ),
                child: const Icon(
                  Icons.looks_two_rounded,
                  size: 50,
                  color: primaryOrange,
                ),
              ),
              const SizedBox(height: 24),

              // Title Label
              const Text(
                'welcome to screen 2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You are currently on the second screen.',
                style: TextStyle(
                  color: Color(0xFFAAAAAA),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Button: Go to Screen 1
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FirstScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  label: const Text(
                    'Go to Screen 1',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryOrange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Button: Back to Main Screen
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home_rounded, color: primaryOrange),
                  label: const Text(
                    'Back to Main Screen',
                    style: TextStyle(
                      color: primaryOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryOrange, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
