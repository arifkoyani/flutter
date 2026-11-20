import 'dart:async';
import 'package:material_ui/material_ui.dart';
import 'dash_board.dart';

class AmazeScreen extends StatefulWidget {
  const AmazeScreen({super.key});

  @override
  State<AmazeScreen> createState() => _AmazeScreenState();
}

class _AmazeScreenState extends State<AmazeScreen> {
  Timer? _timer;

  static const Color primaryOrange = Color(0xFFFF550D);

  @override
  void initState() {
    super.initState();
    // Automatically transition to DashboardScreen after 2.5 seconds
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'one rouhd is all it take, cool!\nyour mood right down.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
                SizedBox(height: 18),
                Text(
                  '---Amaze GO!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: primaryOrange,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
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
