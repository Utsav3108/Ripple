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
import '../core/config/app_config.dart';

// Custom reusable premium scale button for tactile feedback
class _AnimatedScaleButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;

  const _AnimatedScaleButton({
    required this.onPressed,
    required this.child,
    this.backgroundColor,
  });

  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) {
          setState(() {
            _scale = 0.96; // Tactile squeeze
          });
        }
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          setState(() {
            _scale = 1.0;
          });
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) {
          setState(() {
            _scale = 1.0;
          });
        }
      },
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: null, // Tap events are captured by parent GestureDetector
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor ?? AppTheme.accentColor,
              foregroundColor: Colors.black,
              disabledBackgroundColor: widget.backgroundColor ?? AppTheme.accentColor,
              disabledForegroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

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
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 550),
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
    return Scaffold(
      backgroundColor: AppTheme.pureBlack,
      body: Stack(
        children: [
          // Background Gradient Glows
          Positioned(
            top: -120,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.04),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -150,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.03),
                    blurRadius: 150,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),

          // Pages (Progress bar removed completely to feel like a journey, not a form)
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: [
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
        ],
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
    
    final interval = AppConfig.onboardingStatementInterval;
    final fadeDuration = const Duration(milliseconds: 800);
    final totalSteps = _sentences.length + 1; // 6 sentences + 1 button
    final totalDuration = (interval * (totalSteps - 1)) + fadeDuration;

    _controller = AnimationController(
      vsync: this,
      duration: totalDuration,
    );

    final totalMs = totalDuration.inMilliseconds.toDouble();
    for (int i = 0; i < totalSteps; i++) {
      final startMs = i * interval.inMilliseconds.toDouble();
      final endMs = startMs + fadeDuration.inMilliseconds.toDouble();
      
      _fadeAnimations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(
              (startMs / totalMs).clamp(0.0, 1.0),
              (endMs / totalMs).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(flex: 3), // Centers the message block more vertically
          ...List.generate(_sentences.length, (index) {
            final isHighlight = index == _sentences.length - 1;
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimations[index].value,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1.0 - _fadeAnimations[index].value)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Text(
                        _sentences[index],
                        style: GoogleFonts.outfit(
                          fontSize: isHighlight ? 24 : 19,
                          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w400,
                          color: isHighlight ? Colors.white : Colors.white70,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          const Spacer(flex: 3),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimations.last.value,
                child: Transform.translate(
                  offset: Offset(0, 10 * (1.0 - _fadeAnimations.last.value)),
                  child: child,
                ),
              );
            },
            child: _AnimatedScaleButton(
              onPressed: widget.onFinished,
              child: Text(
                'Enter Ripple',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 50),
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
  final PageController _carouselController = PageController(viewportFraction: 0.80);
  int _focusedIndex = 0;
  Timer? _autoPlayTimer;

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
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _carouselController.hasClients) {
        final nextPage = (_carouselController.page!.round() + 1) % _personas.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 110), // Large breathing space below Status Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Who would you ask if they were still here?',
            style: GoogleFonts.outfit(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'History is ready to answer.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 36), // Balanced breathing room above Card Hero

        // Dynamic Swipe-scale Carousel
        SizedBox(
          height: 380,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _personas.length,
            onPageChanged: (idx) {
              setState(() {
                _focusedIndex = idx;
              });
              _startTimer();
            },
            itemBuilder: (context, index) {
              final persona = _personas[index];
              return AnimatedBuilder(
                animation: _carouselController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_carouselController.position.hasContentDimensions) {
                    value = _carouselController.page! - index;
                    value = (1.0 - (value.abs() * 0.12)).clamp(0.88, 1.0);
                  } else {
                    value = index == 0 ? 1.0 : 0.88;
                  }
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: index == _focusedIndex 
                          ? AppTheme.accentColor.withOpacity(0.35) 
                          : Colors.white.withOpacity(0.05),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 24,
                        spreadRadius: -4,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Image background (Brightened, overlay only at text area)
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
                                  Colors.black.withOpacity(0.0),   // Keeps hero face bright
                                  Colors.black.withOpacity(0.3),   // Mid transition
                                  Colors.black.withOpacity(0.85),  // Dark background for typography
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
                                    fontSize: 9,
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
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4), // Reduced spacing as requested
                              Text(
                                '"${persona["quote"]!}"',
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 13.5,
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

        // Continue CTA Section
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
                child: _AnimatedScaleButton(
                  onPressed: widget.onFinished,
                  child: Text(
                    'Continue',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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
  final PageController _carouselController = PageController(viewportFraction: 0.80);
  int _focusedIndex = 0;
  Timer? _autoPlayTimer;

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
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _carouselController.hasClients) {
        final nextPage = (_carouselController.page!.round() + 1) % _challenges.length;
        _carouselController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 110),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "Think you can win an argument against history's greatest minds?",
            style: GoogleFonts.outfit(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Every negotiation is unique.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 36),

        // Dynamic Swipe-scale Carousel
        SizedBox(
          height: 350,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: _challenges.length,
            onPageChanged: (idx) {
              setState(() {
                _focusedIndex = idx;
              });
              _startTimer();
            },
            itemBuilder: (context, index) {
              final challenge = _challenges[index];
              final Color borderCol = challenge["color"];

              return AnimatedBuilder(
                animation: _carouselController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_carouselController.position.hasContentDimensions) {
                    value = _carouselController.page! - index;
                    value = (1.0 - (value.abs() * 0.12)).clamp(0.88, 1.0);
                  } else {
                    value = index == 0 ? 1.0 : 0.88;
                  }
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 6.0),
                  padding: const EdgeInsets.all(28.0),
                  decoration: BoxDecoration(
                    color: AppTheme.cardBgColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: index == _focusedIndex 
                          ? borderCol.withOpacity(0.45) 
                          : Colors.white.withOpacity(0.05),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 24,
                        spreadRadius: -4,
                        offset: const Offset(0, 12),
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
                          fontSize: 21,
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

        // Action Buttons
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
                child: _AnimatedScaleButton(
                  onPressed: widget.onFinished,
                  child: Text(
                    'Continue',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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
  int _activeStateIndex = 0;
  Timer? _stateTimer;

  final List<Map<String, dynamic>> _states = [
    {
      "mood": "Calm",
      "emoji": "🙂",
      "color": Colors.greenAccent,
      "userMsg": "I think your theory is incorrect.",
      "replyMsg": "Interesting. Show me your evidence, and let's dissect the logic together.",
    },
    {
      "mood": "Defensive",
      "emoji": "🤨",
      "color": Colors.orangeAccent,
      "userMsg": "I think your theory is incorrect.",
      "replyMsg": "My logic is sound. Perhaps you have overlooked a crucial piece of the puzzle?",
    },
    {
      "mood": "Sharp",
      "emoji": "⚡",
      "color": Colors.redAccent,
      "userMsg": "I think your theory is incorrect.",
      "replyMsg": "Incorrect? Bold claim. Make sure your facts are straight before questioning my work.",
    }
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _stateTimer?.cancel();
    _stateTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _activeStateIndex = (_activeStateIndex + 1) % _states.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateTimer?.cancel();
    super.dispose();
  }

  Widget _buildStateChip(int index, String label, Color color) {
    final isActive = _activeStateIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeStateIndex = index;
        });
        _startTimer();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? color.withOpacity(0.4) : Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: isActive ? color : Colors.white70,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeState = _states[_activeStateIndex];
    final Color stateColor = activeState["color"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 110),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Conversations that feel alive.',
            style: GoogleFonts.outfit(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "Personas aren't static scripts. They react to your tone, adjust their mood, and respond with real emotion.",
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 32),

        // High fidelity interactive simulated conversation
        Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24.0),
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: AppTheme.cardBgColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Persona Header
                Row(
                  children: [
                    // Dynamic Profile Glow Wrapper
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: stateColor.withOpacity(0.7), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: stateColor.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                        image: const DecorationImage(
                          image: CachedNetworkImageProvider(
                            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=400',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sherlock Holmes',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Consulting Detective',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Active State Tag
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: stateColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: stateColor.withOpacity(0.25)),
                      ),
                      child: Text(
                        activeState["mood"],
                        style: GoogleFonts.outfit(
                          color: stateColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 24),

                // Chat bubble section
                Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Text(
                    activeState["userMsg"],
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),

                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: TextStyle(
                    color: stateColor.withOpacity(0.8),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                  child: const Text('SHERLOCK HOLMES'),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.pureBlack,
                    border: Border.all(color: stateColor.withOpacity(0.15)),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                    child: Text(
                      activeState["replyMsg"],
                      key: ValueKey<int>(_activeStateIndex),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(child: _buildStateChip(0, "Calm", Colors.greenAccent)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStateChip(1, "Defensive", Colors.orangeAccent)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStateChip(2, "Sharp", Colors.redAccent)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const Spacer(),

        // Action Buttons
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
                child: _AnimatedScaleButton(
                  onPressed: widget.onFinished,
                  child: Text(
                    'Continue',
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
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
        const SizedBox(height: 110),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'What excites you?',
            style: GoogleFonts.outfit(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Select topics to shape your recommendations.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 36),

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

        // Action Buttons
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
                child: _AnimatedScaleButton(
                  onPressed: selectedInterests.isEmpty ? null : onFinished,
                  backgroundColor: selectedInterests.isEmpty 
                      ? AppTheme.cardBgColor.withOpacity(0.4) 
                      : AppTheme.accentColor,
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
        const SizedBox(height: 110),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Recommended for You',
            style: GoogleFonts.outfit(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            'Select a profile to start your very first live discussion.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.4),
          ),
        ),
        const SizedBox(height: 36),

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
                            await provider.completeOnboarding();
                            
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
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

        // Action Buttons
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
