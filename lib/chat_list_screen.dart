import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Provider/chat_provider.dart';
import 'chat_screen.dart';
import 'search_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchChattedPresidents();
    });
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          final filteredChats = provider.chats.where((persona) {
            return persona.name.toLowerCase().contains(_searchQuery) ||
                persona.desc.toLowerCase().contains(_searchQuery);
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search chats...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              // Chat List
              Expanded(
                child: provider.isLoading && provider.chats.isEmpty
                    ? Center(child: CircularProgressIndicator(color: accentColor))
                    : RefreshIndicator(
                        onRefresh: () => provider.fetchChattedPresidents(),
                        color: accentColor,
                        backgroundColor: cardColor,
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: filteredChats.length,
                          itemBuilder: (context, index) {
                            final persona = filteredChats[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                height: 92,
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: InkWell(
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatScreen(persona: persona),
                                        ),
                                      );
                                      if (mounted) {
                                        context.read<ChatProvider>().fetchChattedPresidents();
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        children: [
                                          Stack(
                                            children: [
                                              CircleAvatar(
                                                radius: 28,
                                                backgroundColor: const Color(0xFF2A2A2A),
                                                backgroundImage: persona.imageUrl != null
                                                    ? NetworkImage(persona.imageUrl!)
                                                    : null,
                                                child: persona.imageUrl == null
                                                    ? Text(
                                                        persona.name[0],
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 20,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              Positioned(
                                                right: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 14,
                                                  height: 14,
                                                  decoration: BoxDecoration(
                                                    color: accentColor,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: cardColor,
                                                      width: 2,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  persona.name,
                                                  style: theme.textTheme.titleLarge?.copyWith(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  persona.desc,
                                                  style: theme.textTheme.bodyMedium,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
          if (mounted) {
            context.read<ChatProvider>().fetchChattedPresidents();
          }
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}
