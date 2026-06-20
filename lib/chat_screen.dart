import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'Model/model.dart';
import 'Model/narration_parser.dart';
import 'Provider/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final Persona persona;
  final Challenge? challenge;
  final int? attemptSessionId;

  const ChatScreen({
    super.key,
    required this.persona,
    this.challenge,
    this.attemptSessionId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSettingUpChallenge = false;
  ChatProvider? _chatProvider;

  // Narration state variables
  String _displayedStorylineText = "";
  bool _isNarrating = false;
  String _rawStoryline = "";

  late Challenge? _activeChallenge;
  late Persona _activePersona;
  bool _skipNarrationForReplay = false;
  bool _showChallengeSelectionOverlay = false;
  bool _showPersonaSelectionOverlay = false;
  bool _isChallengeCompletedOverlayShown = false;
  Challenge? _selectedNextChallenge;

  // Timer state variables
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _hasTimer = false;
  int _lastMessagesLength = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeChallenge = widget.challenge;
    _activePersona = widget.persona;
    _chatProvider = context.read<ChatProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _chatProvider = context.read<ChatProvider>();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    if (_activeChallenge != null && widget.attemptSessionId == null) {
      _chatProvider?.pauseChallengeSession();
    }
    _messageController.dispose();
    _scrollController.dispose();
    // Safely clear challenge session and socket callbacks on screen disposal
    if (_chatProvider != null) {
      final provider = _chatProvider!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.clearChallengeSession();
      });
      _chatProvider!.onChallengeCompletedEvent = null;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_activeChallenge == null || widget.attemptSessionId != null) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _stopTimer();
      _chatProvider?.pauseChallengeSession();
    } else if (state == AppLifecycleState.resumed) {
      _resumeSessionAndTimer();
    }
  }

  Future<void> _resumeSessionAndTimer() async {
    if (_chatProvider == null || _activeChallenge == null) return;
    try {
      await _chatProvider!.setupChallenge(
        challengeId: _activeChallenge!.id,
        personaId: _activePersona.id,
        attemptSessionId: widget.attemptSessionId,
      );
      _startTimer();
    } catch (e) {
      print("Error resuming timer: $e");
    }
  }

  void _startTimer() {
    _stopTimer();
    final durationMinutes = _chatProvider?.currentChallengeDuration ?? 0;
    if (durationMinutes <= 0) return;

    final elapsedSeconds = _chatProvider?.currentChallengeElapsedSeconds ?? 0;
    _remainingSeconds = (durationMinutes * 60) - elapsedSeconds;
    
    if (_remainingSeconds <= 0) {
      _handleTimeout();
      return;
    }

    _hasTimer = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          _handleTimeout();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _hasTimer = false;
  }

  void _handleTimeout() {
    _handleCompletion('lost_timeout');
  }

  String get _formattedRemainingTime {
    if (_remainingSeconds <= 0) return '00:00:00';
    final duration = Duration(seconds: _remainingSeconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _initializeChat() async {
    if (!mounted) return;

    _isChallengeCompletedOverlayShown = false;

    final isHistoryMode = widget.attemptSessionId != null;
    print("DEBUG: ChatScreen Initializing...");
    print("DEBUG: isHistoryMode = $isHistoryMode");
    print("DEBUG: attemptSessionId = ${widget.attemptSessionId}");
    print("DEBUG: challengeId = ${_activeChallenge?.id}");
    print("DEBUG: personaId = ${_activePersona.id}");

    final provider = _chatProvider!;

    // Register completion listener for socket events only if NOT a historical attempt review
    if (widget.attemptSessionId == null) {
      provider.onChallengeCompletedEvent = (data) async {
        print('ChatScreen received challenge_completed socket event: $data');
        final status = data['challenge_status'] as String? ?? 'lost_blocked';
        final reason = data['result_reason'] as String? ?? data['reason'] as String? ?? '';
        
        int attemptCount = 1;
        if (_activeChallenge != null) {
          final attempts = await provider.fetchChallengeAttempts(_activeChallenge!.id);
          attemptCount = attempts.isNotEmpty ? attempts.length : 1;
        }

        if (mounted) {
          _showChallengeCompletedOverlay(status, reason, attemptCount);
        }
      };
    } else {
      provider.onChallengeCompletedEvent = null;
    }

    if (_activeChallenge != null) {
      setState(() {
        _isSettingUpChallenge = true;
        _displayedStorylineText = "";
        _isNarrating = false;
        _rawStoryline = "";
      });
      try {
        print("Setup Challenge API Called");
        await provider.setupChallenge(
          challengeId: _activeChallenge!.id,
          personaId: _activePersona.id,
          attemptSessionId: widget.attemptSessionId,
        );

        if (widget.attemptSessionId == null) {
          _startTimer();
        }
        
        // Retrieve storyline and trigger narration animation
        final intro = provider.currentChallengeIntro;
        if (intro != null && intro['storyline'] != null) {
          _rawStoryline = intro['storyline'] as String;
          
          // Check if conversation history is NOT empty (meaning challenge is resumed) or if it's a replay
          if (provider.messages.isNotEmpty || _skipNarrationForReplay) {
            setState(() {
              _isNarrating = false;
              _displayedStorylineText = NarrationParser.getCleanText(_rawStoryline);
            });
            _skipNarrationForReplay = false;
          } else {
            // Fresh challenge, progressive word-by-word animation with pauses
            _startNarrationAnimation(_rawStoryline);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to setup challenge: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSettingUpChallenge = false;
          });
        }
      }
    } else {
      provider.clearChallengeSession();
      await provider.fetchMessages(_activePersona.id);
    }
  }

  Future<void> _startNarrationAnimation(String raw) async {
    if (!mounted) return;
    setState(() {
      _isNarrating = true;
      _displayedStorylineText = "";
    });

    final items = NarrationParser.parse(raw);
    
    for (final item in items) {
      if (!mounted || !_isNarrating) break;

      if (item is NarrationText) {
        final words = item.text.split(RegExp(r'\s+'));
        for (final word in words) {
          if (!mounted || !_isNarrating) break;
          setState(() {
            if (_displayedStorylineText.isEmpty) {
              _displayedStorylineText = word;
            } else {
              _displayedStorylineText += " $word";
            }
          });
          await Future.delayed(const Duration(milliseconds: 150)); // Cinematic word delay
        }
      } else if (item is NarrationCommand) {
        if (item.name == 'pause') {
          final seconds = double.tryParse(item.argument ?? '1.0') ?? 1.0;
          await Future.delayed(Duration(milliseconds: (seconds * 1000).toInt()));
        }
      }
    }

    if (mounted) {
      setState(() {
        _isNarrating = false;
        // Make sure it displays the clean full text once narration completes normally
        if (_displayedStorylineText.isEmpty && raw.isNotEmpty) {
          _displayedStorylineText = NarrationParser.getCleanText(raw);
        }
      });
    }
  }

  void _skipNarration() {
    if (!_isNarrating) return;
    setState(() {
      _isNarrating = false;
      _displayedStorylineText = NarrationParser.getCleanText(_rawStoryline);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleCompletion(String status) async {
    final chatProvider = context.read<ChatProvider>();
    
    // Determine custom reason for simulation
    String reason = 'Goal achieved successfully!';
    if (status == 'lost_timeout') reason = 'You ran out of time before completing the challenge.';
    if (status == 'lost_rejected') reason = 'The president flatly rejected your contract terms.';
    if (status == 'lost_blocked') reason = 'The president was offended by your messages and walked out.';
    if (status == 'lost_rule_violation') reason = 'You violated diplomatic protocols during negotiations.';
    if (status == 'abandoned') reason = 'Diplomatic talk called off.';

    await chatProvider.completeChallenge(status, reason: reason);
    
    int attemptCount = 1;
    if (_activeChallenge != null) {
      final attempts = await chatProvider.fetchChallengeAttempts(_activeChallenge!.id);
      attemptCount = attempts.isNotEmpty ? attempts.length : 1;
    }

    if (mounted) {
      _showChallengeCompletedOverlay(status, reason, attemptCount);
    }
  }

  void _showChallengeCompletedOverlay(String status, String reason, int attemptCount) {
    if (_isChallengeCompletedOverlayShown) return;
    _isChallengeCompletedOverlayShown = true;

    _stopTimer();
    // Hide keyboard when challenge completes
    FocusManager.instance.primaryFocus?.unfocus();

    final isWin = status.startsWith('won') || status == 'won_objective_completed';
    final theme = Theme.of(context);
    
    final title = isWin ? '🏆 Challenge Completed' : '❌ Challenge Failed';
    final titleColor = isWin ? theme.colorScheme.primary : theme.colorScheme.error;
    final icon = isWin ? Icons.emoji_events : Icons.cancel;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (dialogContext, anim1, anim2) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent dismissing with back button
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: titleColor.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: titleColor.withOpacity(0.08),
                      blurRadius: 24,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: titleColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: titleColor.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(icon, size: 54, color: titleColor),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      reason,
                      style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Attempts: $attemptCount",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    if (isWin) ...[
                      // Exit Challenge Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, 'exit'); // Close dialog with exit result
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: titleColor,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Exit Challenge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 12),
                      // Next Challenge Button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, 'next'); // Close dialog with next result
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30, width: 1.5),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Next Challenge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ] else ...[
                      // Try Again Button
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, 'retry'); // Close dialog with retry result
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: titleColor,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      const SizedBox(height: 12),
                      // Exit Challenge Button
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext, 'exit'); // Close dialog with exit result
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white30, width: 1.5),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Exit Challenge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((result) {
      _isChallengeCompletedOverlayShown = false;
      if (!mounted) return;
      if (result == 'exit') {
        Navigator.pop(context); // Pop chat screen
      } else if (result == 'retry') {
        setState(() {
          _skipNarrationForReplay = true;
        });
        _initializeChat();
      } else if (result == 'next') {
        setState(() {
          _showChallengeSelectionOverlay = true;
        });
        final chatProvider = _chatProvider!;
        chatProvider.fetchChallenges();
        chatProvider.fetchAllPersonas();
      }
    });
  }

  Widget _buildStorylineCard(ThemeData theme, Map<String, dynamic> intro) {
    final cta = intro['call_to_action'] as String? ?? '';
    final endGoal = intro['end_goal'] as String? ?? '';

    return Center(
      child: GestureDetector(
        onTap: _skipNarration,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.05),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ],
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isNarrating ? Icons.record_voice_over : Icons.auto_stories, 
                color: theme.colorScheme.primary, 
                size: 28
              ),
              const SizedBox(height: 12),
              
              if (endGoal.isNotEmpty) ...[
                Text(
                  "END GOAL",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  endGoal,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white10, height: 1),
                ),
              ],

              Text(
                "CHALLENGE STORYLINE",
                style: TextStyle(
                  color: theme.colorScheme.primary.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _displayedStorylineText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              if (_isNarrating) ...[
                const SizedBox(height: 12),
                Text(
                  "• • • (tap to skip narration)",
                  style: TextStyle(
                    color: theme.colorScheme.primary.withOpacity(0.6),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (cta.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Colors.white24, height: 1),
                ),
                Text(
                  "FIRST MOVE",
                  style: TextStyle(
                    color: theme.colorScheme.primary.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  cta,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    final isChallengeMode = _activeChallenge != null;
    final provider = context.watch<ChatProvider>();

    return WillPopScope(
      onWillPop: () async {
        _stopTimer();
        if (_activeChallenge != null && widget.attemptSessionId == null) {
          // Show a quick loading dialog so the user knows it's saving progress
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(child: CircularProgressIndicator()),
          );
          await _chatProvider?.pauseChallengeSession();
          if (context.mounted) {
            Navigator.pop(context); // Pop dialog
          }
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.surface,
              backgroundImage: _activePersona.imageUrl != null && _activePersona.imageUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(_activePersona.imageUrl!)
                  : null,
              onBackgroundImageError: _activePersona.imageUrl != null && _activePersona.imageUrl!.isNotEmpty
                  ? (exception, stackTrace) {
                      print("Exception caught while fetching image for ${_activePersona.name}: $exception");
                    }
                  : null,
              child: _activePersona.imageUrl == null || _activePersona.imageUrl!.isEmpty
                  ? Text(_activePersona.name[0], style: const TextStyle(fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _activePersona.name,
                    style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isChallengeMode)
                    Text(
                      widget.attemptSessionId != null 
                          ? 'Challenge History (Read Only)'
                          : 'Strategy Challenge Active',
                      style: TextStyle(
                        color: widget.attemptSessionId != null ? Colors.white38 : accentColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isChallengeMode && !_isSettingUpChallenge && widget.attemptSessionId == null && _hasTimer)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(
                  _formattedRemainingTime,
                  style: TextStyle(
                    color: _remainingSeconds < 60 ? Colors.redAccent : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Courier',
                  ),
                ),
              ),
            ),

        ],
      ),
      body: Stack(
        children: [
          // Main Chat view
          _isSettingUpChallenge
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: accentColor),
                      const SizedBox(height: 16),
                      const Text('Setting up challenge, please wait...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: Consumer<ChatProvider>(
                        builder: (context, provider, child) {
                          if (provider.isMessagesLoading && provider.messages.isEmpty) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          final messagesCount = provider.messages.length;
                          if (messagesCount != _lastMessagesLength) {
                            _lastMessagesLength = messagesCount;
                            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                          }

                          final hasIntro = provider.currentChallengeIntro != null;
                          final itemCount = provider.messages.length + (hasIntro ? 1 : 0);

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              if (hasIntro && index == 0) {
                                return _buildStorylineCard(theme, provider.currentChallengeIntro!);
                              }

                              final messageIndex = hasIntro ? index - 1 : index;
                              final message = provider.messages[messageIndex];
                              final isMe = message.isUser;

                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? accentColor : theme.colorScheme.surface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 0),
                                      bottomRight: Radius.circular(isMe ? 0 : 16),
                                    ),
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        message.text,
                                        style: TextStyle(
                                          color: isMe ? Colors.black : Colors.white,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        message.timeStampString,
                                        style: TextStyle(
                                          color: isMe ? Colors.black54 : Colors.white54,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    if (widget.attemptSessionId != null)
                      _buildReadOnlyResultBanner(theme, context.watch<ChatProvider>().currentChallengeStatus)
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.black,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  minLines: 1,
                                  maxLines: 3,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Type a message...',
                                    hintStyle: TextStyle(color: Colors.white54),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                if (_messageController.text.isNotEmpty) {
                                  context.read<ChatProvider>().sendMessage(
                                        _activePersona.id,
                                        _messageController.text,
                                      );
                                  _messageController.clear();
                                }
                              },
                              icon: Icon(Icons.send, color: accentColor),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

          // Next Challenge Overlay
          if (_showChallengeSelectionOverlay)
            _buildChallengeSelectionOverlay(context, provider),

          // Persona Selection Overlay
          if (_showPersonaSelectionOverlay)
            _buildPersonaSelectionOverlay(context, provider),
        ],
      ),
    ),
  );
}

  Widget _buildReadOnlyResultBanner(ThemeData theme, String? status) {
    final cleanStatus = status?.toLowerCase() ?? 'abandoned';
    final isWin = cleanStatus.startsWith('won') || cleanStatus == 'won_objective_completed';
    
    final cardColor = theme.colorScheme.surface;
    
    // Result icon, title, description mappings
    IconData icon;
    Color statusColor;
    String title;
    String description;

    if (isWin) {
      icon = Icons.emoji_events;
      statusColor = theme.colorScheme.primary; // Premium Lime color
      title = "🏆 Challenge Won";
      description = cleanStatus == 'won_objective_completed' 
          ? "Persona agreed to the objective." 
          : "Goal achieved successfully!";
    } else if (cleanStatus == 'abandoned') {
      icon = Icons.flag;
      statusColor = Colors.white54;
      title = "🏳 Challenge Abandoned";
      description = "Strategic session was called off.";
    } else {
      icon = Icons.cancel;
      statusColor = theme.colorScheme.error; // Coral/Red color
      title = "❌ Challenge Failed";
      
      if (cleanStatus == 'lost_timeout') {
        description = "Time limit exceeded during talks.";
      } else if (cleanStatus == 'lost_rejected') {
        description = "Persona rejected the request.";
      } else if (cleanStatus == 'lost_blocked') {
        description = "Persona became offended and blocked you.";
      } else if (cleanStatus == 'lost_rule_violation') {
        description = "Rules or protocols were violated.";
      } else {
        description = "Challenge target was not reached.";
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(
          top: BorderSide(color: statusColor.withOpacity(0.3), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
              ),
              child: Icon(icon, size: 28, color: statusColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String? difficulty) {
    switch (difficulty?.toLowerCase()) {
      case 'easy':
        return const Color(0xFF8CE99A); // Soft green
      case 'medium':
        return const Color(0xFFFFD43B); // Soft yellow
      case 'hard':
        return const Color(0xFFFF8787); // Soft red
      default:
        return Colors.white54;
    }
  }

  Widget _buildChallengeSelectionOverlay(BuildContext context, ChatProvider provider) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    
    // Filter out the current active challenge
    final nextChallenges = provider.challenges
        .where((c) => c.id != _activeChallenge?.id)
        .toList();

    return Container(
      color: theme.scaffoldBackgroundColor.withOpacity(0.98), // Sleek, premium dark color with 98% opacity
      child: SafeArea(
        child: Column(
          children: [
            // AppBar replacement
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Next Challenge',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _showChallengeSelectionOverlay = false;
                      });
                      Navigator.pop(context); // Redirect to challenge dashboard
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),
            
            // List of challenges
            Expanded(
              child: provider.isChallengesLoading
                  ? Center(
                      child: CircularProgressIndicator(color: accentColor),
                    )
                  : nextChallenges.isEmpty
                      ? const Center(
                          child: Text(
                            'No other challenges available.',
                            style: TextStyle(color: Colors.white54, fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: nextChallenges.length,
                      itemBuilder: (context, index) {
                        final challenge = nextChallenges[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: InkWell(
                            onTap: () => _handleNextChallengeSelected(challenge),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: accentColor.withOpacity(0.08),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: accentColor.withOpacity(0.2)),
                                        ),
                                        child: Icon(Icons.emoji_events_outlined, color: accentColor, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              challenge.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            if (challenge.difficulty != null) ...[
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: _getDifficultyColor(challenge.difficulty).withOpacity(0.12),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: _getDifficultyColor(challenge.difficulty).withOpacity(0.3)),
                                                ),
                                                child: Text(
                                                  challenge.difficulty!.toUpperCase(),
                                                  style: TextStyle(
                                                    color: _getDifficultyColor(challenge.difficulty),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                                    ],
                                  ),
                                  if (challenge.shortDescription != null && challenge.shortDescription!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      challenge.shortDescription!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNextChallengeSelected(Challenge challenge) {
    if (challenge.selectedPersonaId != null) {
      final targetPersona = _chatProvider?.getPersonaById(challenge.selectedPersonaId!);
      if (targetPersona != null) {
        setState(() {
          _activeChallenge = challenge;
          _activePersona = targetPersona;
          _showChallengeSelectionOverlay = false;
          _showPersonaSelectionOverlay = false;
          _skipNarrationForReplay = false;
        });
        _initializeChat();
        return;
      }
    }

    setState(() {
      _selectedNextChallenge = challenge;
      _showChallengeSelectionOverlay = false;
      _showPersonaSelectionOverlay = true;
    });
  }

  Widget _buildPersonaSelectionOverlay(BuildContext context, ChatProvider provider) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final accentColor = theme.colorScheme.primary;
    final challenge = _selectedNextChallenge;

    if (challenge == null) return const SizedBox.shrink();

    final suggestedIds = challenge.suggestedPersonas ?? [];
    
    final sortedPersonas = List<Persona>.from(provider.allPersonas);
    sortedPersonas.sort((a, b) {
      final aSuggested = suggestedIds.contains(a.id);
      final bSuggested = suggestedIds.contains(b.id);
      if (aSuggested && !bSuggested) return -1;
      if (!aSuggested && bSuggested) return 1;
      return 0;
    });

    return Container(
      color: theme.scaffoldBackgroundColor.withOpacity(0.98),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _showPersonaSelectionOverlay = false;
                        _showChallengeSelectionOverlay = true;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Select a Persona',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () {
                      setState(() {
                        _showPersonaSelectionOverlay = false;
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (challenge.context?.goal != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        challenge.context!.goal,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'AVAILABLE CANDIDATES',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            Expanded(
              child: provider.isLoading && provider.allPersonas.isEmpty
                  ? Center(
                      child: CircularProgressIndicator(color: accentColor),
                    )
                  : GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: sortedPersonas.length,
                itemBuilder: (context, index) {
                  final persona = sortedPersonas[index];
                  final isSuggested = suggestedIds.contains(persona.id);
                  return _buildPersonaCardItem(persona, cardColor, accentColor, isSuggested);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonaCardItem(Persona persona, Color cardColor, Color accentColor, bool isRecommended) {
    final recommendedBadgeColor = accentColor;
    return InkWell(
      onTap: () => _handlePersonaSelectedForNextChallenge(persona),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRecommended ? recommendedBadgeColor : Colors.white10,
            width: isRecommended ? 2.0 : 1,
          ),
          boxShadow: [
            if (isRecommended)
              BoxShadow(
                color: recommendedBadgeColor.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: cardColor,
                      child: persona.imageUrl != null && persona.imageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: persona.imageUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => _buildPlaceholderItem(persona.name[0]),
                            )
                          : _buildPlaceholderItem(persona.name[0]),
                    ),
                    if (isRecommended)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: recommendedBadgeColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star, size: 10, color: Colors.black),
                              SizedBox(width: 4),
                              Text(
                                'SUGGESTED',
                                style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      persona.desc,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderItem(String char) {
    return Center(child: Text(char, style: const TextStyle(fontSize: 32, color: Colors.white)));
  }

  void _handlePersonaSelectedForNextChallenge(Persona persona) {
    setState(() {
      _activeChallenge = _selectedNextChallenge;
      _activePersona = persona;
      _showChallengeSelectionOverlay = false;
      _showPersonaSelectionOverlay = false;
      _skipNarrationForReplay = false;
    });
    _initializeChat();
  }
}
