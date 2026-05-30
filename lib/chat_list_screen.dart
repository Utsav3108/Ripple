import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Provider/chat_provider.dart';
import 'chat_screen.dart';
import 'persona_selection_screen.dart';
import 'challenge_stats_screen.dart';
import 'search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String _firstName = 'Utsav';
  int _currentBottomNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ChatProvider>();
      provider.fetchChattedPersonas();
      provider.fetchChallenges();
      provider.fetchAllPersonas();
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
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
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
                            text: '$_firstName!',
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
                  Expanded(
                    child: _buildChallengesList(provider, accentColor, cardColor),
                  ),
                ],
              ),
              // Tab 2: Profile Tab
              _buildProfileView(accentColor, cardColor),
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
      child: GridView.builder(
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
                        color: const Color(0xFF2A2A2A),
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
    return RefreshIndicator(
      onRefresh: () => provider.fetchChallenges(),
      color: accentColor,
      backgroundColor: cardColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.challenges.length,
        itemBuilder: (context, index) {
          final challenge = provider.challenges[index];
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
                height: 140,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    // Image Section (35%)
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: double.infinity,
                        child: challenge.imageUrl != null
                            ? Image.network(challenge.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF2A2A2A), child: const Icon(Icons.landscape, color: Colors.white24)))
                            : Container(color: const Color(0xFF2A2A2A), child: const Icon(Icons.landscape, color: Colors.white24)),
                      ),
                    ),
                    // Text Section
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              challenge.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              challenge.context?.goal ?? "No description available",
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileView(Color accentColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          // User Avatar Card
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentColor, width: 2),
            ),
            child: const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFF2A2A2A),
              child: Text(
                'U',
                style: TextStyle(fontSize: 48, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _firstName,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Text(
            'Premium Member',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 32),
          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('Chats Started', '8', cardColor, accentColor),
              _buildStatCard('Success Rate', '75%', cardColor, accentColor),
            ],
          ),
          const SizedBox(height: 24),
          // Premium Info Panel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.stars, color: accentColor),
                    const SizedBox(width: 8),
                    const Text(
                      'Ripple Premium Active',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Access to unlimited dynamic personas, higher token generation, and advanced strategy challenges.',
                  style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color cardColor, Color accentColor) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: accentColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white54),
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
