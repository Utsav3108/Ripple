import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Provider/chat_provider.dart';
import 'chat_screen.dart';
import 'persona_selection_screen.dart';
import 'challenge_stats_screen.dart';
import 'search_screen.dart';
import 'create_persona_screen.dart';
import 'create_challenge_screen.dart';
import 'Model/model.dart';
import 'category_challenges_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int _currentBottomNavIndex = 0;
  String _selectedTrack = 'All';
  String _searchQuery = '';
  
  bool _profileInitialized = false;
  final TextEditingController _roleController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  final Map<String, List<String>> _trackMapping = {
    'Business & Career': ['Finance', 'Negotiation', 'Business Strategy', 'Entrepreneurship'],
    'Social & Rapport': ['Dating', 'Social Skills', 'Confidence', 'Emotional Intelligence', 'Conflict Resolution', 'Empathy'],
    'Persuasion & Rhetoric': ['Persuasion', 'Critical Thinking', 'Public Speaking', 'Courtroom Drama'],
    'Leadership & Science': ['Leadership', 'Science', 'Politics'],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      provider.fetchChattedPersonas();
      provider.fetchChallenges();
      provider.fetchActiveSessions();
      provider.fetchAllPersonas();
      provider.fetchUserProfile();
    });
  }

  void _onBottomNavTapped(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
    final provider = context.read<ChatProvider>();
    if (index == 0) {
      provider.fetchChattedPersonas();
    } else if (index == 1) {
      provider.fetchChallenges();
      provider.fetchActiveSessions();
    } else if (index == 2) {
      provider.fetchUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ripple'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          return IndexedStack(
            index: _currentBottomNavIndex,
            children: [
              // Tab 0: Personas Tab
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: RichText(
                      text: TextSpan(
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                        children: [
                          const TextSpan(text: 'Hello, '),
                          TextSpan(
                            text: '${provider.userName}!',
                            style: TextStyle(
                              color: accentColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: Text('Chat with Personas', style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    child: _buildCharactersGrid(provider, accentColor, cardColor),
                  ),
                ],
              ),
              // Tab 1: Challenges Tab
              _buildChallengesList(provider, accentColor, cardColor),
              // Tab 2: Profile Tab
              _buildProfileView(provider, accentColor, cardColor),
            ],
          );
        },
      ),
      floatingActionButton: _currentBottomNavIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
                );
                if (mounted) {
                  context.read<ChatProvider>().fetchChattedPersonas();
                }
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        onTap: _onBottomNavTapped,
        backgroundColor: Colors.black,
        selectedItemColor: accentColor,
        unselectedItemColor: Colors.white38,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            activeIcon: Icon(Icons.forum),
            label: 'Personas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCharactersGrid(ChatProvider provider, Color accentColor, Color cardColor) {
    if (provider.isLoading && provider.chats.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }
    return RefreshIndicator(
      onRefresh: () => provider.fetchChattedPersonas(),
      color: accentColor,
      backgroundColor: cardColor,
      child: provider.chats.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Text(
                  'No personas chatted with yet.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            )
          : GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: provider.chats.length,
              itemBuilder: (context, index) {
                final persona = provider.chats[index];
                return InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(persona: persona),
                      ),
                    );
                    if (mounted) {
                      provider.fetchChattedPersonas();
                    }
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: Container(
                              width: double.infinity,
                              color: cardColor,
                              child: persona.imageUrl != null
                                  ? Image.network(persona.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholder(persona.name[0]))
                                  : _buildPlaceholder(persona.name[0]),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(persona.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(persona.desc, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
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
  }

  final List<CategoryItem> _categoriesList = [
    CategoryItem('Business & Career', ['Finance', 'Business Strategy', 'Startup', 'Business'], Icons.business_center, [Colors.blue.shade900, Colors.black]),
    CategoryItem('Social & Rapport', ['Social Skills', 'Confidence', 'Emotional Intelligence', 'Conflict Resolution', 'Empathy', 'Social'], Icons.people, [Colors.purple.shade900, Colors.black]),
    CategoryItem('Dating', ['Dating'], Icons.favorite, [Colors.red.shade900, Colors.black]),
    CategoryItem('Leadership', ['Leadership'], Icons.star, [Colors.amber.shade900, Colors.black]),
    CategoryItem('Negotiation', ['Negotiation'], Icons.handshake, [Colors.teal.shade900, Colors.black]),
    CategoryItem('Politics', ['Politics', 'Science'], Icons.gavel, [Colors.indigo.shade900, Colors.black]),
    CategoryItem('Courtroom', ['Courtroom Drama', 'Courtroom', 'Critical Thinking'], Icons.balance, [Colors.amber.shade700, Colors.black87]),
    CategoryItem('Entrepreneurship', ['Entrepreneurship', 'Public Speaking', 'Persuasion', 'Startup'], Icons.lightbulb, [Colors.deepOrange.shade900, Colors.black]),
  ];

  List<Challenge> getTrendingChallenges(ChatProvider provider) {
    return provider.challenges.where((c) => c.difficulty == 'intermediate' || c.difficulty == 'advance').toList();
  }

  List<Challenge> getRecommendedChallenges(ChatProvider provider) {
    return provider.challenges.where((c) => c.difficulty == 'beginner' || c.difficulty == 'intermediate').toList();
  }

  List<Challenge> getRecentlyAddedChallenges(ChatProvider provider) {
    return provider.challenges.reversed.toList();
  }

  String getChallengeCTA(ChatProvider provider, Challenge challenge) {
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

  Challenge? getChallengeForSession(ChatProvider provider, ChallengeSession session) {
    try {
      return provider.challenges.firstWhere((c) => c.id == session.challengeId);
    } catch (_) {
      return null;
    }
  }

  Challenge? getDailyChallenge(ChatProvider provider) {
    if (provider.challenges.isEmpty) return null;
    try {
      return provider.challenges.firstWhere((c) => c.id == 'courtroom_self_defense');
    } catch (_) {
      return provider.challenges.first;
    }
  }

  Widget _buildContinuePlayingSection(BuildContext context, ChatProvider provider, Color accentColor, Color cardColor) {
    if (provider.activeSessions.isEmpty) return const SizedBox.shrink();

    final isSingle = provider.activeSessions.length == 1;

    Widget buildCard(ChallengeSession session, {double? width}) {
      final challenge = getChallengeForSession(provider, session);
      if (challenge == null) return const SizedBox.shrink();

      final attemptCount = provider.challengeAttemptCounts[challenge.id] ?? 0;
      
      if (!provider.challengeAttemptCounts.containsKey(challenge.id)) {
        provider.fetchAttemptCountForChallenge(challenge.id);
      }

      return Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white10),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 55,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentColor.withOpacity(0.25), Colors.black],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Text(
                challenge.title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      challenge.subtitle ?? challenge.context?.goal ?? "Resume your active strategy scenario.",
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Attempt #${attemptCount + 1}",
                          style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
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
                      ],
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton(
                        onPressed: () => _onChallengeTap(context, provider, challenge),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Resume Challenge',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isSingle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Continue Playing',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: SizedBox(
              height: 210,
              width: double.infinity,
              child: buildCard(provider.activeSessions.first),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Continue Playing',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.activeSessions.length,
            itemBuilder: (context, index) {
              return buildCard(provider.activeSessions[index], width: 280);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyChallenge(BuildContext context, ChatProvider provider, Color accentColor, Color cardColor) {
    final challenge = getDailyChallenge(provider);
    if (challenge == null) return const SizedBox.shrink();
    
    final ctaText = getChallengeCTA(provider, challenge);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: accentColor.withOpacity(0.12), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: accentColor),
                      const SizedBox(width: 4),
                      Text(
                        "DAILY CHALLENGE",
                        style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      "+150 XP",
                      style: TextStyle(color: Colors.amber.shade300, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              challenge.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              challenge.shortDescription ?? challenge.context?.goal ?? "A high-stakes daily conversation test to level up your social intelligence.",
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _onChallengeTap(context, provider, challenge),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ctaText == 'Resume' ? accentColor : Colors.white.withOpacity(0.06),
                  foregroundColor: ctaText == 'Resume' ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: ctaText == 'Resume' ? Colors.transparent : Colors.white24),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  ctaText,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarousel(ChatProvider provider, List<Challenge> challenges, Color accentColor, Color cardColor, {bool isTrending = false}) {
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          final ctaText = getChallengeCTA(provider, challenge);
          
          if (!provider.challengeAttemptCounts.containsKey(challenge.id)) {
            provider.fetchAttemptCountForChallenge(challenge.id);
          }

          return Container(
            width: 220,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _onChallengeTap(context, provider, challenge),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isTrending)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department, size: 10, color: Colors.redAccent),
                                const SizedBox(width: 2),
                                Text(
                                  "🔥 #${index + 1} Trending",
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else if (challenge.categories != null && challenge.categories!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              challenge.categories!.first,
                              style: TextStyle(color: accentColor, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        Text(
                          (challenge.difficulty ?? 'medium').toUpperCase(),
                          style: TextStyle(
                            color: challenge.difficulty == 'advance'
                                ? Colors.redAccent
                                : challenge.difficulty == 'intermediate'
                                    ? Colors.orangeAccent
                                    : accentColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            challenge.subtitle ?? challenge.context?.goal ?? "Master this conversation",
                            style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.3),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: () => _onChallengeTap(context, provider, challenge),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ctaText == 'Resume' ? accentColor : Colors.white.withOpacity(0.06),
                          foregroundColor: ctaText == 'Resume' ? Colors.black : Colors.white70,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: ctaText == 'Resume' ? Colors.transparent : Colors.white12),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          ctaText,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid(Color cardColor, Color accentColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemCount: _categoriesList.length,
      itemBuilder: (context, index) {
        final item = _categoriesList[index];
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: item.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white10),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryChallengesScreen(
                      categoryName: item.name,
                      keywords: item.keywords,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(item.icon, color: accentColor, size: 24),
                    Text(
                      item.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildChallengesList(ChatProvider provider, Color accentColor, Color cardColor) {
    if (provider.isChallengesLoading && provider.challenges.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    if (provider.challenges.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await provider.fetchChallenges();
          await provider.fetchActiveSessions();
        },
        color: accentColor,
        backgroundColor: cardColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            alignment: Alignment.center,
            height: MediaQuery.of(context).size.height * 0.5,
            child: const Text(
              'No challenges found. Pull to refresh.',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ),
        ),
      );
    }

    final trending = getTrendingChallenges(provider);
    final recommended = getRecommendedChallenges(provider);
    final recentlyAdded = getRecentlyAddedChallenges(provider);

    return RefreshIndicator(
      onRefresh: () async {
        await provider.fetchChallenges();
        await provider.fetchActiveSessions();
      },
      color: accentColor,
      backgroundColor: cardColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 1. Continue Playing (Highest Priority)
            if (provider.activeSessions.isNotEmpty) ...[
              _buildContinuePlayingSection(context, provider, accentColor, cardColor),
              const SizedBox(height: 16),
            ],

            // 2. Daily Challenge
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Daily Challenge',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildDailyChallenge(context, provider, accentColor, cardColor),
            const SizedBox(height: 16),

            // 3. Trending Challenges
            if (trending.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Trending Challenges',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildCarousel(provider, trending, accentColor, cardColor, isTrending: true),
              const SizedBox(height: 16),
            ],

            // 4. Recommended For You
            if (recommended.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Recommended For You',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildCarousel(provider, recommended, accentColor, cardColor),
              const SizedBox(height: 16),
            ],

            // 5. Recently Added
            if (recentlyAdded.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Recently Added',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              _buildCarousel(provider, recentlyAdded, accentColor, cardColor),
              const SizedBox(height: 16),
            ],

            // 6. Categories
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Browse Categories',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            _buildCategoryGrid(cardColor, accentColor),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileView(ChatProvider provider, Color accentColor, Color cardColor) {
    if (!_profileInitialized && !provider.isProfileLoading && provider.userEmail.isNotEmpty) {
      _roleController.text = provider.userRole;
      _bioController.text = provider.userBio;
      _profileInitialized = true;
    }

    if (provider.isProfileLoading && !_profileInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // Settings defaults
    final settings = provider.userSettings ?? {};

    final hasChanges = _roleController.text != provider.userRole || _bioController.text != provider.userBio;

    return RefreshIndicator(
      onRefresh: () => provider.fetchUserProfile(),
      color: accentColor,
      backgroundColor: cardColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Basic Profile Card
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accentColor, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: Colors.white10,
                        backgroundImage: provider.userImageUrl.isNotEmpty
                            ? NetworkImage(provider.userImageUrl)
                            : null,
                        child: provider.userImageUrl.isEmpty
                            ? Text(provider.userName.isNotEmpty ? provider.userName[0].toUpperCase() : 'U', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white))
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.userName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.userEmail.isNotEmpty ? provider.userEmail : 'No email associated',
                      style: const TextStyle(fontSize: 13, color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Active Strategy Rank',
                        style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Stats Summary Row
            Row(
              children: [
                Expanded(child: _buildSummaryItem('Challenges Attempted', '${provider.totalChallengesAttempted}', cardColor, accentColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryItem('Success Rate', '${provider.successRatePercentage.toStringAsFixed(0)}%', cardColor, accentColor)),
                const SizedBox(width: 12),
                Expanded(child: _buildSummaryItem('Persona Chatted', '${provider.totalPracticeSessions}', cardColor, accentColor)),
              ],
            ),
            const SizedBox(height: 24),

            // 3. Role & Background Context
            const Text(
              'ROLE & BACKGROUND CONTEXT',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Your Role (e.g. Product Manager)', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _roleController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Add your professional or personal role...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Short Biography / Context', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _bioController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Share a brief bio or background context to personalize non-challenge chats...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      filled: true,
                      fillColor: Colors.black38,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                  if (hasChanges) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await provider.updateUserProfile(
                              role: _roleController.text.trim(),
                              bio: _bioController.text.trim(),
                              settings: settings,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Context updated successfully!'), backgroundColor: Colors.green),
                            );
                            setState(() {});
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Context Changes', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 5. Attempt Log
            const Text(
              'RECENT CHALLENGE ATTEMPTS',
              style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 10),
            provider.profileAttemptsLog.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.history, color: Colors.white30, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'No challenges attempted yet.',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: provider.profileAttemptsLog.length,
                    itemBuilder: (context, index) {
                      final item = provider.profileAttemptsLog[index];
                      final dateString = "${item.createdAt.day}/${item.createdAt.month}/${item.createdAt.year}";
                      final badgeColor = item.won ? accentColor : Colors.redAccent;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.won ? Icons.emoji_events : Icons.cancel,
                                  color: badgeColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.challengeTitle,
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Opponent: ${item.personaName} • $dateString",
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  item.won ? 'WON' : 'FAILED',
                                  style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.read<ChatProvider>().logout();
                },
                icon: const Icon(Icons.logout, color: Colors.redAccent, size: 18),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color cardColor, Color accentColor) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String char) {
    return Center(child: Text(char, style: const TextStyle(fontSize: 40, color: Colors.white)));
  }
}

class CategoryItem {
  final String name;
  final List<String> keywords;
  final IconData icon;
  final List<Color> gradientColors;

  CategoryItem(this.name, this.keywords, this.icon, this.gradientColors);
}
