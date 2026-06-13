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
        actions: const [
          // Hidden for Phase 1 MVP
          /*
          if (_currentBottomNavIndex == 0 || _currentBottomNavIndex == 1)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Center(
                child: InkWell(
                  onTap: () {
                    if (_currentBottomNavIndex == 0) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreatePersonaScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateChallengeScreen(),
                        ),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                    ),
                    child: Text(
                      "+ Create",
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          */
        ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
                    child: Text(
                      'Strategy Challenges',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search challenges...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: accentColor, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  // Curriculum Track Filters
                  _buildTrackFilterRow(provider, accentColor, cardColor),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _buildChallengesList(provider, accentColor, cardColor),
                  ),
                ],
              ),
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

  Widget _buildChallengesList(ChatProvider provider, Color accentColor, Color cardColor) {
    if (provider.isChallengesLoading && provider.challenges.isEmpty) {
      return Center(child: CircularProgressIndicator(color: accentColor));
    }

    final filteredChallenges = provider.challenges.where((challenge) {
      // 1. Domain Track Filter
      bool matchesTrack = false;
      if (_selectedTrack == 'All') {
        matchesTrack = true;
      } else {
        final allowedSubCategories = _trackMapping[_selectedTrack] ?? [];
        if (challenge.categories != null) {
          matchesTrack = challenge.categories!.any((cat) => allowedSubCategories.contains(cat));
        }
      }

      // 2. Search Query Filter
      final matchesSearch = _searchQuery.isEmpty ||
          challenge.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (challenge.context?.goal != null &&
              challenge.context!.goal.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (challenge.categories != null &&
              challenge.categories!.any((cat) => cat.toLowerCase().contains(_searchQuery.toLowerCase())));

      return matchesTrack && matchesSearch;
    }).toList();

    return RefreshIndicator(
      onRefresh: () => provider.fetchChallenges(),
      color: accentColor,
      backgroundColor: cardColor,
      child: filteredChallenges.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                alignment: Alignment.center,
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Text(
                  'No challenges found matching selection.',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: filteredChallenges.length,
        itemBuilder: (context, index) {
          final challenge = filteredChallenges[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: InkWell(
              onTap: () async {
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
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Persona details for challenge not loaded yet.')),
                    );
                  }
                } else {
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
                  }
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      challenge.context?.goal ?? "No description available",
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    if (challenge.categories != null && challenge.categories!.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: challenge.categories!.map((cat) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white10, width: 0.8),
                            ),
                            child: Text(
                              cat,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Tap to play",
                          style: TextStyle(color: Colors.white38, fontSize: 11),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navigate to Challenge Stats Screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChallengeStatsScreen(challenge: challenge),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.bar_chart, size: 12, color: accentColor),
                                const SizedBox(width: 4),
                                Text(
                                  "View Stats",
                                  style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTrackFilterRow(ChatProvider provider, Color accentColor, Color cardColor) {
    final tracks = ['All', ..._trackMapping.keys];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          final isSelected = track == _selectedTrack;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedTrack = track;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? accentColor : Colors.white10,
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  track,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
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
