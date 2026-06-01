import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Model/model.dart';
import 'Provider/chat_provider.dart';
import 'chat_screen.dart';

class ChallengeStatsScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeStatsScreen({super.key, required this.challenge});

  @override
  State<ChallengeStatsScreen> createState() => _ChallengeStatsScreenState();
}

class _ChallengeStatsScreenState extends State<ChallengeStatsScreen> {
  List<ChallengeAttempt> _attempts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() {
      _isLoading = true;
    });

    final provider = context.read<ChatProvider>();
    final attempts = await provider.fetchChallengeAttempts(widget.challenge.id);

    if (mounted) {
      setState(() {
        _attempts = attempts;
        _isLoading = false;
      });
    }
  }

  // Helper to format time_taken_seconds into "Xm Ys"
  String _formatTime(int seconds) {
    if (seconds <= 0) return "--";
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return "${minutes}m ${remainingSeconds}s";
    }
    return "${remainingSeconds}s";
  }

  // Helper to format DateTime to "MMM dd, yyyy"
  String _formatDate(DateTime date) {
    final months = [
      "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
      "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final accentColor = theme.colorScheme.primary;

    // Calculate statistics
    final totalAttempts = _attempts.length;
    final totalWins = _attempts.where((a) => a.won).length;
    final totalLosses = totalAttempts - totalWins;
    final winRate = totalAttempts > 0 ? (totalWins / totalAttempts) * 100 : 0.0;

    // Best Time: minimum time of successful attempts
    int bestTimeSeconds = -1;
    final successfulAttempts = _attempts.where((a) => a.won).toList();
    if (successfulAttempts.isNotEmpty) {
      bestTimeSeconds = successfulAttempts
          .map((a) => a.timeTakenSeconds)
          .reduce((a, b) => a < b ? a : b);
    }

    // Latest Date
    String latestDate = "--";
    if (_attempts.isNotEmpty) {
      // attempts are sorted or we find the maximum date
      final newest = _attempts.reduce((a, b) => a.createdAt.isAfter(b.createdAt) ? a : b);
      latestDate = _formatDate(newest.createdAt);
    }

    // Sort attempts in reverse chronological order (newest first)
    final sortedAttempts = List<ChallengeAttempt>.from(_attempts)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenge Stats'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : CustomScrollView(
              slivers: [
                // Header details Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: accentColor.withOpacity(0.3)),
                                ),
                                child: Text(
                                  widget.challenge.difficulty?.toUpperCase() ?? 'BEGINNER',
                                  style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.challenge.title,
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.challenge.context?.goal ?? "Challenge stats and historical performance tracking.",
                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                if (totalAttempts == 0)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.analytics_outlined, size: 54, color: Colors.white24),
                              const SizedBox(height: 16),
                              const Text(
                                "No attempts yet.",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Start this challenge to see your statistics and history.",
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  // Summary stats grid section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "PERFORMANCE SUMMARY",
                            style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 12),
                          // Premium Summary Grid
                          GridView(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.5,
                            ),
                            children: [
                              _buildSummaryCard("Win Rate", "${winRate.toStringAsFixed(1)}%", accentColor, cardColor),
                              _buildSummaryCard("Total Attempts", "$totalAttempts", Colors.white, cardColor),
                              _buildSummaryCard("Wins / Losses", "$totalWins / $totalLosses", accentColor, cardColor),
                              _buildSummaryCard("Best Time", _formatTime(bestTimeSeconds), const Color(0xFFE6F58A), cardColor),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Latest attempt details
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Latest Active Attempt",
                                  style: TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                                Text(
                                  latestDate,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // History attempt list section
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 16.0, top: 32.0, bottom: 12.0),
                      child: Text(
                        "ATTEMPT HISTORY",
                        style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final attempt = sortedAttempts[index];
                          
                          // Look up persona
                          final provider = context.read<ChatProvider>();
                          final persona = provider.getPersonaById(attempt.personaId);
                          final personaName = persona?.name ?? "Persona #${attempt.personaId}";

                           final resolvedPersona = persona ?? Persona(
                            id: attempt.personaId,
                            name: personaName,
                            desc: 'Diplomatic strategic candidate',
                          );

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: InkWell(
                              onTap: () {
                                final sessionId = attempt.challengeSessionId ?? (int.tryParse(attempt.id) ?? 0);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      persona: resolvedPersona,
                                      challenge: widget.challenge,
                                      attemptSessionId: sessionId,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: Row(
                                  children: [
                                    // Result icon
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: attempt.won 
                                            ? accentColor.withOpacity(0.1) 
                                            : const Color(0xFFFF6B6B).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        attempt.won ? Icons.emoji_events : Icons.cancel,
                                        color: attempt.won ? accentColor : const Color(0xFFFF6B6B),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Attempt text details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Attempt #${attempt.attemptNumber}",
                                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Persona: $personaName",
                                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "Time taken: ${_formatTime(attempt.timeTakenSeconds)}",
                                            style: const TextStyle(color: Colors.white54, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Date
                                    Text(
                                      _formatDate(attempt.createdAt),
                                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                        childCount: sortedAttempts.length,
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color textColor, Color cardColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
