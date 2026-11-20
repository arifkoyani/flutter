import 'package:material_ui/material_ui.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
                '1. Acceptance of Terms',
                'By downloading, accessing, or playing this game, you agree to be bound by these Terms of Service. If you do not agree with any part of these terms, please discontinue using the application.',
              ),

              _buildSection(
                '2. License to Play',
                'We grant you a personal, non-exclusive, non-transferable, revocable license to install and play the game for personal entertainment on your Android device.',
              ),

              _buildSection(
                '3. Fair Play & Conduct',
                'You agree not to exploit glitches, use unauthorized cheats or bots, reverse engineer the code, or attempt to disrupt the game services for other players.',
              ),

              _buildSection(
                '4. Intellectual Property',
                'All trademarks, graphics, characters, sounds, artwork, and code are the exclusive property of Weconnect Games and are protected by applicable intellectual property laws.',
              ),

              _buildSection(
                '5. Disclaimer & Limitation of Liability',
                'The game is provided on an "as is" and "as available" basis without warranties of any kind. We are not liable for any indirect, incidental, or consequential damages resulting from gameplay.',
              ),

              _buildSection(
                '6. Changes to Terms',
                'We reserve the right to revise or update these Terms of Service at any time. Continued use of the game following updates signifies your acceptance of the revised terms.',
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
