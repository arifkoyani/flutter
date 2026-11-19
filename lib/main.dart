import 'package:material_ui/material_ui.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Game Dev Journey',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090D16),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C5CE7),
          secondary: Color(0xFF00D2D3),
          surface: Color(0xFF131B2E),
        ),
        useMaterial3: true,
      ),
      home: const GameDevWelcomeScreen(),
    );
  }
}

class GameDevWelcomeScreen extends StatefulWidget {
  const GameDevWelcomeScreen({super.key});

  @override
  State<GameDevWelcomeScreen> createState() => _GameDevWelcomeScreenState();
}

class _GameDevWelcomeScreenState extends State<GameDevWelcomeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;

  // Staggered entrance animations
  late final Animation<double> _fadeHeader;
  late final Animation<Offset> _slideHeader;
  late final Animation<double> _fadeCards;
  late final Animation<Offset> _slideCards;
  late final Animation<double> _fadeButton;
  late final Animation<Offset> _slideButton;

  // Ambient floating animation
  late final Animation<double> _floatAnim;
  late final Animation<double> _glowAnim;

  int _selectedPillarIndex = -1;

  @override
  void initState() {
    super.initState();

    // Entrance Animation (1400ms)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeHeader = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideHeader = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    _fadeCards = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
    );
    _slideCards = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.8, curve: Curves.easeOutCubic),
    ));

    _fadeButton = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOut),
    );
    _slideButton = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeOutCubic),
    ));

    // Floating / Breathing glow loop (2400ms)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
    _glowAnim = Tween<double>(begin: 0.35, end: 0.8).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _onStartPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF6C5CE7), width: 1),
        ),
        content: const Row(
          children: [
            Icon(Icons.rocket_launch_rounded, color: Color(0xFF00D2D3), size: 22),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Quest accepted! Preparing your game dev environment...',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Ambient background glow circles
          _buildBackgroundAura(),

          // Main scrollable content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 28.0,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Badge & Hero Icon section
                      SlideTransition(
                        position: _slideHeader,
                        child: FadeTransition(
                          opacity: _fadeHeader,
                          child: Column(
                            children: [
                              _buildQuestBadge(),
                              const SizedBox(height: 32),
                              _buildAnimatedHeroIcon(),
                              const SizedBox(height: 28),
                              _buildHeadline(),
                              const SizedBox(height: 12),
                              _buildSubheadline(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // Feature Cards (Modern Minimalist Pillars)
                      SlideTransition(
                        position: _slideCards,
                        child: FadeTransition(
                          opacity: _fadeCards,
                          child: _buildPillarsGrid(),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Call to action button
                      SlideTransition(
                        position: _slideButton,
                        child: FadeTransition(
                          opacity: _fadeButton,
                          child: _buildStartButton(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Footer minimal hint
                      SlideTransition(
                        position: _slideButton,
                        child: FadeTransition(
                          opacity: _fadeButton,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bolt_rounded,
                                size: 14,
                                color: Color(0xFF64748B),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Real-time physics • 2D & 3D • Cross-platform',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundAura() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF070B12),
              Color(0xFF0D1220),
              Color(0xFF090D17),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, _) {
            return Stack(
              children: [
                // Top-left violet orb
                Positioned(
                  top: -80,
                  left: -60,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF6C5CE7).withValues(
                        alpha: 0.12 * _glowAnim.value,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withValues(
                            alpha: 0.22 * _glowAnim.value,
                          ),
                          blurRadius: 100,
                          spreadRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom-right cyan orb
                Positioned(
                  bottom: -60,
                  right: -60,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00D2D3).withValues(
                        alpha: 0.08 * _glowAnim.value,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D2D3).withValues(
                            alpha: 0.18 * _glowAnim.value,
                          ),
                          blurRadius: 110,
                          spreadRadius: 45,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuestBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF151C2C),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_esports_rounded,
            size: 15,
            color: Color(0xFF00D2D3),
          ),
          SizedBox(width: 8),
          Text(
            'CHAPTER 01 • QUEST UNLOCKED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFFD6E4FF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeroIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: child,
        );
      },
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient outer glow ring
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Container(
                  width: 124,
                  height: 124,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF6C5CE7).withValues(
                          alpha: 0.35 * _glowAnim.value,
                        ),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

            // Icon card
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1E2842),
                    Color(0xFF131A2B),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.gamepad_rounded,
                size: 48,
                color: Color(0xFF00E5FF),
              ),
            ),

            // Floating mini sparkles
            Positioned(
              top: 4,
              right: 6,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF6C5CE7),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 13,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 6,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00D2D3),
                ),
                child: const Icon(
                  Icons.code_rounded,
                  size: 13,
                  color: Color(0xFF090D16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeadline() {
    return Column(
      children: [
        const Text(
          'Welcome to the',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFF70A1FF),
              Color(0xFF00D2D3),
            ],
            stops: [0.1, 0.65, 1.0],
          ).createShader(bounds),
          child: const Text(
            'Game Developing\nJourney',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: -0.5,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubheadline() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(
        'develop mechanics, and transform pure imagination into playable reality.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14.5,
          color: Color(0xFF8B9CB3),
          height: 1.5,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildPillarsGrid() {
    final pillars = [
      (
        icon: Icons.palette_outlined,
        color: const Color(0xFFFF7675),
        title: 'develop game ju',
        desc: 'Levels, visual assets & story dynamics',
      ),
      (
        icon: Icons.terminal_rounded,
        color: const Color(0xFF00D2D3),
        title: 'develop game',
        desc: 'Physics engines, player controls & state',
      ),
      (
        icon: Icons.rocket_launch_rounded,
        color: const Color(0xFFA29BFE),
        title: 'Launch & Polish',
        desc: 'Optimization, audio FX & distribution',
      ),
    ];

    return Column(
      children: List.generate(pillars.length, (index) {
        final item = pillars[index];
        final isSelected = _selectedPillarIndex == index;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedPillarIndex = isSelected ? -1 : index;
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF1B243B)
                    : const Color(0xFF111726),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? item.color.withValues(alpha: 0.8)
                      : const Color(0xFF232D42),
                  width: isSelected ? 1.4 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: item.color.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.color, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.desc,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF8290A5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isSelected ? item.color : const Color(0xFF475569),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _onStartPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF6C5CE7),
                Color(0xFF4834D4),
                Color(0xFF00CEC9),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Start Development',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 10),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
