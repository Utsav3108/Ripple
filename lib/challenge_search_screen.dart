import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Provider/chat_provider.dart';
import 'Model/model.dart';
import 'chat_screen.dart';
import 'persona_selection_screen.dart';
import 'challenge_stats_screen.dart';

class ChallengeSearchScreen extends StatefulWidget {
  const ChallengeSearchScreen({super.key});

  @override
  State<ChallengeSearchScreen> createState() => _ChallengeSearchScreenState();
}

class _ChallengeSearchScreenState extends State<ChallengeSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  final int _pageSize = 20;
  bool _isLoadMoreLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    
    // Clear search results initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().clearChallengeSearchResults();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final newQuery = _searchController.text.trim();
    if (newQuery != _query) {
      _query = newQuery;
      _hasMore = true;
      _isLoadMoreLoading = false;
      context.read<ChatProvider>().searchChallenges(_query, limit: _pageSize, offset: 0);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadMoreLoading || !_hasMore || _query.isEmpty) return;
    
    final provider = context.read<ChatProvider>();
    final currentOffset = provider.challengeSearchResults.length;

    setState(() {
      _isLoadMoreLoading = true;
    });

    try {
      final prevLength = provider.challengeSearchResults.length;
      await provider.searchChallenges(_query, limit: _pageSize, offset: currentOffset, loadMore: true);
      final newLength = provider.challengeSearchResults.length;
      
      if (newLength - prevLength < _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      print("Error loading more challenges: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadMoreLoading = false;
        });
      }
    }
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
        await provider.fetchAllPersonas();
        persona = provider.getPersonaById(activeSession.personaId);
      }
      
      if (persona == null) {
        persona = Persona(
          id: activeSession.personaId,
          name: 'Opponent',
          desc: 'Active Challenge Scenario',
        );
      }

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              persona: persona!,
              challenge: challenge,
            ),
          ),
        );
      }
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
        if (context.mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                persona: persona,
                challenge: challenge,
              ),
            ),
          );
        }
        if (mounted) {
          provider.fetchChattedPersonas();
          provider.fetchActiveSessions();
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Persona details for challenge not loaded yet.')),
          );
        }
      }
    } else {
      // 3. Otherwise, select a persona for the new attempt
      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PersonaSelectionScreen(
              challenge: challenge,
            ),
          ),
        );
      }
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
        title: const Text(
          'Search Challenges',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          final results = provider.challengeSearchResults;

          return Column(
            children: [
              // Search Input Container
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by title, category, difficulty...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3)),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white54, size: 20),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),

              // Search results list
              Expanded(
                child: _query.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search, size: 64, color: accentColor.withOpacity(0.6)),
                            const SizedBox(height: 16),
                            const Text(
                              'Type to search challenges...',
                              style: TextStyle(color: Colors.white54, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : provider.isSearching && results.isEmpty
                        ? Center(child: CircularProgressIndicator(color: accentColor))
                        : results.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.search_off, size: 54, color: Colors.white24),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No matching challenges found',
                                      style: TextStyle(color: Colors.white54, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                controller: _scrollController,
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: results.length + (_isLoadMoreLoading ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (index == results.length) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                                      child: Center(
                                        child: SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: accentColor,
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  final challenge = results[index];
                                  final ctaText = _getChallengeCTA(provider, challenge);

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
                                          // Banner Header
                                          Container(
                                            height: 90,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [accentColor.withOpacity(0.25), Colors.black],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            alignment: Alignment.centerLeft,
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: Text(
                                              challenge.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                                                  height: 44,
                                                  child: ElevatedButton(
                                                    onPressed: () => _onChallengeTap(context, provider, challenge),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: ctaText == 'Resume' ? accentColor : Colors.white.withOpacity(0.1),
                                                      foregroundColor: ctaText == 'Resume' ? Colors.black : Colors.white,
                                                      elevation: 0,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(12),
                                                        side: BorderSide(
                                                          color: ctaText == 'Resume' ? Colors.transparent : Colors.white24,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      ctaText,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
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
              ),
            ],
          );
        },
      ),
    );
  }
}
