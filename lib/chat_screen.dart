import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Model/model.dart';
import 'Model/narration_parser.dart';
import 'Provider/chat_provider.dart';

class ChatScreen extends StatefulWidget {
  final Persona persona;
  final Challenge? challenge;

  const ChatScreen({
    super.key,
    required this.persona,
    this.challenge,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSettingUpChallenge = false;

  // Narration state variables
  String _displayedStorylineText = "";
  bool _isNarrating = false;
  String _rawStoryline = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    final chatProvider = context.read<ChatProvider>();

    // Register completion listener for socket events
    chatProvider.onChallengeCompletedEvent = (data) {
      print('ChatScreen received challenge_completed socket event: $data');
      final status = data['challenge_status'] as String? ?? 'lost_blocked';
      final reason = data['reason'] as String? ?? '';
      if (mounted) {
        _showChallengeCompletedOverlay(status, reason);
      }
    };

    if (widget.challenge != null) {
      setState(() {
        _isSettingUpChallenge = true;
        _displayedStorylineText = "";
        _isNarrating = false;
        _rawStoryline = "";
      });
      try {
        await chatProvider.setupChallenge(
          challengeId: widget.challenge!.id,
          personaId: widget.persona.id,
        );
        
        // Retrieve storyline and trigger narration animation
        final intro = chatProvider.currentChallengeIntro;
        if (intro != null && intro['storyline'] != null) {
          _rawStoryline = intro['storyline'] as String;
          
          // Check if conversation history is NOT empty (meaning challenge is resumed)
          if (chatProvider.messages.isNotEmpty) {
            setState(() {
              _isNarrating = false;
              _displayedStorylineText = NarrationParser.getCleanText(_rawStoryline);
            });
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
      chatProvider.clearChallengeSession();
      await chatProvider.fetchMessages(widget.persona.id);
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

  void _showCompletionDialog() {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    final statuses = [
      {'value': 'won', 'label': 'Challenge Won'},
      {'value': 'won_objective_completed', 'label': 'Objective Completed'},
      {'value': 'lost_timeout', 'label': 'Failed: Timeout'},
      {'value': 'lost_rejected', 'label': 'Failed: Persona Rejected'},
      {'value': 'lost_blocked', 'label': 'Failed: Persona Blocked'},
      {'value': 'lost_rule_violation', 'label': 'Failed: Rule Violation'},
      {'value': 'abandoned', 'label': 'Abandon Challenge'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Simulate Challenge Completion',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose a status below to complete this session and see the premium result overlay.',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: statuses.length,
                  itemBuilder: (context, index) {
                    final status = statuses[index];
                    final isLose = status['value']!.startsWith('lost');
                    final isWin = status['value']!.startsWith('won');
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      title: Text(
                        status['label']!,
                        style: TextStyle(
                          color: isWin 
                              ? accentColor 
                              : isLose 
                                  ? const Color(0xFFFF6B6B) 
                                  : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white30),
                      onTap: () async {
                        Navigator.pop(context); // Close bottom sheet
                        _handleCompletion(status['value']!);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCompletion(String status) async {
    final chatProvider = context.read<ChatProvider>();
    
    // Determine custom reason for simulation
    String reason = 'Goal achieved successfully!';
    if (status == 'lost_timeout') reason = 'You exceeded the time limit to persuade the president.';
    if (status == 'lost_rejected') reason = 'The president flatly rejected your contract terms.';
    if (status == 'lost_blocked') reason = 'The president was offended by your messages and walked out.';
    if (status == 'lost_rule_violation') reason = 'You violated diplomatic protocols during negotiations.';
    if (status == 'abandoned') reason = 'Diplomatic talk called off.';

    await chatProvider.completeChallenge(status, reason: reason);
    
    if (mounted) {
      _showChallengeCompletedOverlay(status, reason);
    }
  }

  void _showChallengeCompletedOverlay(String status, String reason) {
    final isWin = status.startsWith('won');
    final isAbandon = status == 'abandoned';
    
    IconData statusIcon = Icons.emoji_events;
    Color iconColor = const Color(0xFFE6F58A); // Lime accent
    String title = 'CHALLENGE COMPLETED';

    if (isWin) {
      statusIcon = status == 'won_objective_completed' ? Icons.check_circle : Icons.emoji_events;
      iconColor = const Color(0xFFE6F58A);
      title = status == 'won_objective_completed' ? '🎉 Challenge Completed' : '🎉 Challenge Won';
    } else if (isAbandon) {
      statusIcon = Icons.flag;
      iconColor = Colors.white54;
      title = 'CHALLENGE ABANDONED';
    } else {
      statusIcon = status == 'lost_timeout' ? Icons.timer_outlined : Icons.cancel;
      iconColor = const Color(0xFFFF6B6B);
      
      if (status == 'lost_timeout') title = '❌ Challenge Failed (Timeout)';
      if (status == 'lost_rejected') title = '❌ Challenge Failed (Rejected)';
      if (status == 'lost_blocked') title = '❌ Challenge Failed (Blocked)';
      if (status == 'lost_rule_violation') title = '❌ Challenge Failed (Violation)';
    }

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
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: iconColor.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.08),
                      blurRadius: 24,
                      spreadRadius: 4,
                    )
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Large Premium Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.05),
                        shape: BoxShape.circle,
                        border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
                      ),
                      child: Icon(statusIcon, size: 54, color: iconColor),
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
                    const SizedBox(height: 12),
                    Text(
                      reason,
                      style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // OK Button (pops dialog + pops chat screen)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext); // Close dialog
                        Navigator.pop(context); // Pop chat screen
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStorylineCard(ThemeData theme, Map<String, dynamic> intro) {
    final cta = intro['call_to_action'] as String? ?? '';

    return Center(
      child: GestureDetector(
        onTap: _skipNarration,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
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
              Text(
                "CHALLENGE STORYLINE",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _displayedStorylineText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
                  "OBJECTIVE",
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

    final isChallengeMode = widget.challenge != null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.persona.imageUrl != null
                  ? NetworkImage(widget.persona.imageUrl!)
                  : null,
              child: widget.persona.imageUrl == null
                  ? Text(widget.persona.name[0], style: const TextStyle(fontSize: 14))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.persona.name,
                    style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isChallengeMode)
                    Text(
                      'Strategy Challenge Active',
                      style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (isChallengeMode && !_isSettingUpChallenge)
            IconButton(
              icon: Icon(Icons.flag_outlined, color: accentColor),
              tooltip: 'Complete/Simulate Challenge',
              onPressed: _showCompletionDialog,
            ),
        ],
      ),
      body: _isSettingUpChallenge
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: accentColor),
                  const SizedBox(height: 16),
                  const Text('Setting up diplomatic challenge...', style: TextStyle(color: Colors.white70, fontSize: 14)),
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

                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

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
                                color: isMe ? accentColor : const Color(0xFF1A1A1A),
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
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.black,
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _messageController,
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
                                  widget.persona.id,
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
    );
  }
}
