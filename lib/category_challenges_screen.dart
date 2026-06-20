import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Provider/chat_provider.dart';
import 'Model/model.dart';
import 'chat_screen.dart';
import 'persona_selection_screen.dart';
import 'challenge_stats_screen.dart';

class CategoryChallengesScreen extends StatefulWidget {
  final String categoryName;
  final List<String> keywords;

  const CategoryChallengesScreen({
    super.key,
    required this.categoryName,
    required this.keywords,
  });

  @override
  State<CategoryChallengesScreen> createState() => _CategoryChallengesScreenState();
}

class _CategoryChallengesScreenState extends State<CategoryChallengesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      provider.fetchActiveSessions();
      provider.fetchChallenges();
    });
  }

  String _getChallengeCTA(ChatProvider provider, Challenge challenge) {
    final isActive = provider.activeSessions.any((s) => s.challengeId == challenge.id);
    if (isActive) return 'Resume';
    
    final attemptCount = provider.challengeAttemptCounts[challenge.id] ?? 0;
    if (attemptCount > 0) return 'Play Again';
    
    return 'Start Challenge';
  }

  void _onChallengeTap(BuildContext context, ChatProvider provider, Challenge challenge) async {
    // 1. Check if there is an active session for this challenge to resume it directly
    ChallengeSession? activeSession;
    try {
      activeSession = provider.activeSessions.firstWhere((s) => s.challengeId == challenge.id);
    } catch (_) {
      activeSession = null;
    }

    if (activeSession != null) {
      var persona = provider.getPersonaById(activeSession.personaId);
      if (persona == null) {
        // Try fetching all personas to make sure they are loaded
        await provider.fetchAllPersonas();
        persona = provider.getPersonaById(activeSession.personaId);
      }
      
      // Fallback: construct a Persona object dynamically if it's still null (e.g. not loaded/custom)
      if (persona == null) {
        persona = Persona(
          id: activeSession.personaId,
          name: 'Opponent',
          desc: 'Active Challenge Scenario',
        );
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            persona: persona!,
            challenge: challenge,
          ),
        ),
      );
      if (mounted) {
        provider.fetchChattedPersonas();
        provider.fetchActiveSessions();
      }
      return;
    }

    // 2. No active session, check if challenge has a pre-determined persona
    if (challenge.selectedPersonaId != null) {
      final persona = provider.getPersonaById(challenge.selectedPersonaId!);
      if (persona != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              persona: persona,
              challenge: challenge,
            ),
          ),
        );
        if (mounted) {
          provider.fetchChattedPersonas();
          provider.fetchActiveSessions();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Persona details for challenge not loaded yet.')),
        );
      }
    } else {
      // 3. Otherwise, select a persona for the new attempt
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PersonaSelectionScreen(
            challenge: challenge,
          ),
        ),
      );
      if (mounted) {
        provider.fetchChattedPersonas();
        provider.fetchActiveSessions();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          final matchedChallenges = provider.challenges.where((c) {
            if (c.categories == null) return false;
            return c.categories!.any((cat) => widget.keywords.contains(cat) || cat == widget.categoryName);
          }).toList();

          if (provider.isChallengesLoading && matchedChallenges.isEmpty) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }

          if (matchedChallenges.isEmpty) {
            return const Center(
              child: Text(
                'No challenges found in this category.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await provider.fetchChallenges();
              await provider.fetchActiveSessions();
            },
            color: accentColor,
            backgroundColor: cardColor,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: matchedChallenges.length,
              itemBuilder: (context, index) {
                final challenge = matchedChallenges[index];
                final ctaText = _getChallengeCTA(provider, challenge);
                
                // Fetch attempts count asynchronously in background
                if (!provider.challengeAttemptCounts.containsKey(challenge.id)) {
                  provider.fetchAttemptCountForChallenge(challenge.id);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header/Image if available, else standard accent background banner
                        Container(
                          height: 100,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentColor.withOpacity(0.3), Colors.black],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  challenge.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChallengeStatsScreen(challenge: challenge),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Icon(Icons.bar_chart, size: 14, color: accentColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                challenge.subtitle ?? challenge.context?.goal ?? "Master this conversational simulation.",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  // Difficulty Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.white10),
                                    ),
                                    child: Text(
                                      (challenge.difficulty ?? 'medium').toUpperCase(),
                                      style: TextStyle(
                                        color: challenge.difficulty == 'advance'
                                            ? Colors.redAccent
                                            : challenge.difficulty == 'intermediate'
                                                ? Colors.orangeAccent
                                                : accentColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Category Badge
                                  if (challenge.categories != null && challenge.categories!.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: accentColor.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: accentColor.withOpacity(0.15)),
                                      ),
                                      child: Text(
                                        challenge.categories!.first,
                                        style: TextStyle(
                                          color: accentColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: () => _onChallengeTap(context, provider, challenge),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ctaText == 'Resume' ? accentColor : Colors.white.withOpacity(0.1),
                                    foregroundColor: ctaText == 'Resume' ? Colors.black : Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(
                                        color: ctaText == 'Resume' ? Colors.transparent : Colors.white24,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    ctaText,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
