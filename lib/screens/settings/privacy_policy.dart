import 'package:material_ui/material_ui.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color primaryOrange = Color(0xFFFF550D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Last updated: November 2026',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),

              _buildSection(
                '1. Introduction',
                'Welcome to our game. We are dedicated to respecting and protecting your privacy. This Privacy Policy describes how we handle any information when you play our mobile game.',
              ),

              _buildSection(
                '2. Information We Collect',
                'We do not collect personal identities such as your name or physical address. We may store gameplay preferences locally on your device (such as sound, music, and high scores) to provide a seamless offline experience.',
              ),

              _buildSection(
                '3. Device & Performance Data',
                'Non-personal technical information, such as operating system version, device model, and crash reports, may be processed to optimize game performance and fix bugs.',
              ),

              _buildSection(
                '4. Third-Party Services',
                'Our game may use standard platform services (e.g., Google Play Services) for achievements and leaderboard rankings in accordance with their respective privacy policies.',
              ),

              _buildSection(
                '5. Children\'s Privacy',
                'Our games are designed for general audiences and do not knowingly collect personal identifiable information from children under the age of 13.',
              ),

              _buildSection(
                '6. Contact Us',
                'If you have any questions or feedback regarding this Privacy Policy, please reach out to our support team.',
              ),

              const SizedBox(height: 32),

              // Bottom back button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryOrange, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Back to Settings',
                    style: TextStyle(
                      color: primaryOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(
              color: Color(0xFF444444),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
