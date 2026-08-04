import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../Model/model.dart';
import '../Provider/chat_provider.dart';
import '../Theme/app_theme.dart';
import '../chat_screen.dart';
import '../chat_list_screen.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _selectedInterests = [];

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.pureBlack,
      body: Stack(
        children: [
          // Background Gradient Glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.03),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.02),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Main Pages
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), // Managed navigation only
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
              _SplashPage(onFinished: _nextPage),
              _EmotionalIntroPage(onFinished: _nextPage),
              _PersonaShowcasePage(onFinished: _nextPage, onBack: _previousPage),
              _ChallengeShowcasePage(onFinished: _nextPage, onBack: _previousPage),
              _EmotionShowcasePage(onFinished: _nextPage, onBack: _previousPage),
              _ChooseInterestsPage(
                selectedInterests: _selectedInterests,
                onInterestToggled: (interest) {
                  setState(() {
                    if (_selectedInterests.contains(interest)) {
                      _selectedInterests.remove(interest);
                    } else {
                      _selectedInterests.add(interest);
                    }
                  });
                  // Preload personas from backend on selection interaction
                  context.read<ChatProvider>().fetchAllPersonas();
                },
                onFinished: _nextPage,
                onBack: _previousPage,
              ),
              _RecommendedPersonasPage(
                selectedInterests: _selectedInterests,
                onBack: _previousPage,
              ),
            ],
          ),

          // Top Segmented Progress Bar (Visible from Step 2 to Step 6)
          if (_currentPage > 0 && _currentPage < 6)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 24,
              right: 24,
              child: Row(
                children: List.generate(5, (index) {
                  // Index 0 represents Step 2 (page 1)
                  final stepIndex = index + 1;
                  final isActive = stepIndex <= _currentPage;
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: isActive 
                            ? AppTheme.accentColor 
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 1. Splash Page
// ----------------------------------------------------
class _SplashPage extends StatefulWidget {
  final VoidCallback onFinished;
  const _SplashPage({required this.onFinished});

  @override
  State<_SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<_SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _controller.forward();

    Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/ripple_splash.png',
                width: 140,
                height: 140,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.accentColor.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Icon(Icons.waves, size: 64, color: AppTheme.accentColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'RIPPLE',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 2. Emotional Introduction Page
// ----------------------------------------------------
class _EmotionalIntroPage extends StatefulWidget {
  final VoidCallback onFinished;
  const _EmotionalIntroPage({required this.onFinished});

  @override
  State<_EmotionalIntroPage> createState() => _EmotionalIntroPageState();
}

class _EmotionalIntroPageState extends State<_EmotionalIntroPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _fadeAnimations = [];
  final List<String> _sentences = [
    "The world is full of extraordinary minds.",
    "Some inspire.",
    "Some challenge.",
    "Some disagree.",
    "Some change you.",
    "Today, you can talk to them.",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Create staggered fade intervals for 6 text blocks + 1 button
    final stepFraction = 1.0 / (_sentences.length + 1);
    for (int i = 0; i < _sentences.length + 1; i++) {
      final start = i * stepFraction;
      final end = (i + 1) * stepFraction;
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeInOut),
          ),
        ),
      );
    }

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 3),
          ...List.generate(_sentences.length, (index) {
            final isHighlight = index == _sentences.length - 1;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimations[index].value,
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1.0 - _fadeAnimations[index].value)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        _sentences[index],
                        style: GoogleFonts.outfit(
                          fontSize: isHighlight ? 24 : 20,
                          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                          color: isHighlight ? Colors.white : Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          const Spacer(flex: 2),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimations.last.value,
                child: Transform.translate(
                  offset: Offset(0, 15 * (1.0 - _fadeAnimations.last.value)),
                  child: child,
                ),
              );
            },
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: widget.onFinished,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Enter Ripple',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// 3. Persona Showcase Page
// ----------------------------------------------------
class _PersonaShowcasePage extends StatefulWidget {
  final VoidCallback onFinished;
  final VoidCallback onBack;
  const _PersonaShowcasePage({required this.onFinished, required this.onBack});

  @override
  State<_PersonaShowcasePage> createState() => _PersonaShowcasePageState();
}

class _PersonaShowcasePageState extends State<_PersonaShowcasePage> {
  final PageController _carouselController = PageController(viewportFraction: 0.82);
  int _focusedIndex = 0;

  final List<Map<String, String>> _personas = [
    {
      "name": "Steve Jobs",
      "tag": "CO-FOUNDER OF APPLE",
      "quote": "Innovation begins with saying no.",
      "image": "https://images.unsplash.com/photo-1581092921461-eab62e97a780?auto=format&fit=crop&q=80&w=400",
    },
    {
      "name": "Virat Kohli",
      "tag": "CRICKET LEGEND",
      "quote": "Pressure reveals who you really are.",
      "image": "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?auto=format&fit=crop&q=80&w=400",
    },
    {
      "name": "Sherlock Holmes",
      "tag": "CONSULTING DETECTIVE",
      "quote": "Observation is a habit, not a talent.",
      "image": "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=400",
    }
  ];

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Meet Great Minds',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Step into discussions with historic personalities, leaders, and thinkers.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _personas.length,
            onPageChanged: (idx) {
              setState(() {
                _focusedIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              final persona = _personas[index];
              final isFocused = index == _focusedIndex;
              final scale = isFocused ? 1.0 : 0.9;

              return AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isFocused 
                          ? AppTheme.accentColor.withOpacity(0.3) 
                          : Colors.white.withOpacity(0.05),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image background
                        CachedNetworkImage(
                          imageUrl: persona["image"]!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.black26),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.white.withOpacity(0.02),
                            child: const Icon(Icons.person, size: 64, color: Colors.white10),
                          ),
                        ),
                        // Dark glass gradient panel overlay
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.black.withOpacity(0.1),
                                  Colors.black.withOpacity(0.5),
                                  Colors.black.withOpacity(0.9),
                                ],
                                stops: const [0.0, 0.45, 1.0],
                              ),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  persona["tag"]!,
                                  style: TextStyle(
                                    color: AppTheme.accentColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                persona["name"]!,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '"${persona["quote"]!}"',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Spacer(),
        // Navigation Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(60, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: widget.onFinished,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 4. Challenge Showcase Page
// ----------------------------------------------------
class _ChallengeShowcasePage extends StatefulWidget {
  final VoidCallback onFinished;
  final VoidCallback onBack;
  const _ChallengeShowcasePage({required this.onFinished, required this.onBack});

  @override
  State<_ChallengeShowcasePage> createState() => _ChallengeShowcasePageState();
}

class _ChallengeShowcasePageState extends State<_ChallengeShowcasePage> {
  final PageController _carouselController = PageController(viewportFraction: 0.82);
  int _focusedIndex = 0;

  final List<Map<String, dynamic>> _challenges = [
    {
      "title": "Negotiation Challenge",
      "desc": "Acquire corporate funding from a stubborn angel investor without giving up excess equity.",
      "difficulty": 4,
      "attempts": "14,291",
      "successRate": "21%",
      "color": Colors.blueAccent,
    },
    {
      "title": "Crisis Management",
      "desc": "Defuse a severe PR crisis with a hostile journalist before public rumors tank your stock.",
      "difficulty": 5,
      "attempts": "9,842",
      "successRate": "8%",
      "color": Colors.redAccent,
    },
    {
      "title": "Public Speaking Coach",
      "desc": "Pitch a disruptive technological solution to a board of skeptical executives.",
      "difficulty": 3,
      "attempts": "18,290",
      "successRate": "54%",
      "color": Colors.green,
    }
  ];

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Test Your Strategies',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Accept complex prompts and see if you have what it takes to succeed.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const Spacer(),
        SizedBox(
          height: 350,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _challenges.length,
            onPageChanged: (idx) {
              setState(() {
                _focusedIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              final challenge = _challenges[index];
              final isFocused = index == _focusedIndex;
              final scale = isFocused ? 1.0 : 0.9;
              final Color borderCol = challenge["color"];

              return AnimatedScale(
                scale: scale,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isFocused 
                          ? borderCol.withOpacity(0.4) 
                          : Colors.white.withOpacity(0.05),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shield_outlined, color: borderCol, size: 36),
                      const SizedBox(height: 20),
                      Text(
                        challenge["title"]!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        challenge["desc"]!,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      const Spacer(),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DIFFICULTY', style: TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Row(
                                children: List.generate(5, (starIdx) {
                                  final active = starIdx < (challenge["difficulty"] as int);
                                  return Icon(
                                    Icons.star,
                                    size: 13,
                                    color: active ? AppTheme.accentColor : Colors.white12,
                                  );
                                }),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ATTEMPTS', style: TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(
                                challenge["attempts"]!,
                                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('SUCCESS RATE', style: TextStyle(color: Colors.white30, fontSize: 9, letterSpacing: 0.5)),
                              const SizedBox(height: 4),
                              Text(
                                challenge["successRate"]!,
                                style: GoogleFonts.outfit(color: borderCol, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Spacer(),
        // Navigation Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(60, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: widget.onFinished,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 5. Emotion Showcase Page
// ----------------------------------------------------
class _EmotionShowcasePage extends StatefulWidget {
  final VoidCallback onFinished;
  final VoidCallback onBack;
  const _EmotionShowcasePage({required this.onFinished, required this.onBack});

  @override
  State<_EmotionShowcasePage> createState() => _EmotionShowcasePageState();
}

class _EmotionShowcasePageState extends State<_EmotionShowcasePage> {
  int _moodIndex = 0;
  final List<Map<String, String>> _moods = [
    {"emoji": "🙂", "text": "Calm"},
    {"emoji": "🤔", "text": "Curious"},
    {"emoji": "😠", "text": "Annoyed"},
  ];
  Timer? _moodTimer;

  @override
  void initState() {
    super.initState();
    _moodTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _moodIndex = (_moodIndex + 1) % _moods.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Dynamic Relationships',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Each conversation alters the mindset, trust, and response metrics of the AI.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const Spacer(),
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28.0),
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: AppTheme.cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'CURRENT MOOD',
                  style: TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 16),
                // Mood emoji and name
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Column(
                    key: ValueKey<int>(_moodIndex),
                    children: [
                      Text(
                        _moods[_moodIndex]["emoji"]!,
                        style: const TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _moods[_moodIndex]["text"]!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Progress Bars
                _buildProgressBar('Trust', 0.8),
                const SizedBox(height: 16),
                _buildProgressBar('Patience', 0.5),
                const SizedBox(height: 16),
                _buildProgressBar('Respect', 0.35),
                const SizedBox(height: 28),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                Text(
                  'Every conversation changes the relationship.',
                  style: GoogleFonts.outfit(
                    color: AppTheme.accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
        // Navigation Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(60, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: widget.onFinished,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentColor.withOpacity(0.8)),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 6. Choose Interests Page
// ----------------------------------------------------
class _ChooseInterestsPage extends StatelessWidget {
  final List<String> selectedInterests;
  final Function(String) onInterestToggled;
  final VoidCallback onFinished;
  final VoidCallback onBack;

  const _ChooseInterestsPage({
    required this.selectedInterests,
    required this.onInterestToggled,
    required this.onFinished,
    required this.onBack,
  });

  static const List<String> _interests = [
    'Entrepreneurship',
    'Technology',
    'Sports',
    'Comedy',
    'Psychology',
    'Business',
    'Movies',
    'Science',
    'Politics',
    'Philosophy',
    'History',
    'Music',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'What excites you?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Select interests to help display recommended personas to discuss and chat with.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _interests.map((interest) {
              final isSelected = selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () => onInterestToggled(interest),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.accentColor.withOpacity(0.08) 
                        : AppTheme.cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected 
                          ? AppTheme.accentColor.withOpacity(0.8) 
                          : Colors.white.withOpacity(0.05),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    interest,
                    style: TextStyle(
                      color: isSelected ? AppTheme.accentColor : Colors.white70,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const Spacer(),
        // Navigation Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Row(
            children: [
              OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  minimumSize: const Size(60, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: selectedInterests.isEmpty ? null : onFinished,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: AppTheme.cardBgColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: selectedInterests.isEmpty ? Colors.white24 : Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 7. Recommended Personas Page (API Integration)
// ----------------------------------------------------
class _RecommendedPersonasPage extends StatelessWidget {
  final List<String> selectedInterests;
  final VoidCallback onBack;

  const _RecommendedPersonasPage({
    required this.selectedInterests,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final personas = provider.allPersonas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 80),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Recommended for You',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Select a profile to start your very first live discussion.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),

        // Persona List Grid
        Expanded(
          child: provider.isLoading && personas.isEmpty
              ? Center(child: CircularProgressIndicator(color: AppTheme.accentColor))
              : personas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.people_outline, size: 48, color: Colors.white24),
                          const SizedBox(height: 16),
                          Text(
                            'No personas found',
                            style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Verify the API connection and reload.',
                            style: TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      itemCount: personas.length,
                      separatorBuilder: (context, idx) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final persona = personas[index];
                        return InkWell(
                          onTap: () async {
                            // 1. Complete onboarding locally
                            await provider.completeOnboarding();
                            
                            // 2. Perform a reset and route directly to Live Chat Screen
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (context) => const ChatListScreen()),
                                (route) => false,
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(persona: persona),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppTheme.cardBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Row(
                              children: [
                                // Avatar photo
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white.withOpacity(0.02),
                                  backgroundImage: persona.imageUrl != null && persona.imageUrl!.isNotEmpty
                                      ? CachedNetworkImageProvider(persona.imageUrl!)
                                      : null,
                                  child: persona.imageUrl == null || persona.imageUrl!.isEmpty
                                      ? Text(
                                          persona.name[0].toUpperCase(),
                                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                // Text fields
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        persona.name,
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        persona.desc,
                                        style: const TextStyle(
                                          color: Colors.white54,
                                          fontSize: 12,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.accentColor),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Navigation Back Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                'Back',
                style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
