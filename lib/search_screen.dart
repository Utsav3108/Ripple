import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'Provider/chat_provider.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';
  final int _pageSize = 10;
  bool _isLoadMoreLoading = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    
    // Fetch initial personas when screen is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().searchPersonas('', limit: _pageSize, offset: 0);
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
      context.read<ChatProvider>().searchPersonas(_query, limit: _pageSize, offset: 0);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadMoreLoading || !_hasMore) return;

    final provider = context.read<ChatProvider>();
    final currentOffset = provider.searchResults.length;

    setState(() {
      _isLoadMoreLoading = true;
    });

    try {
      final prevLength = provider.searchResults.length;
      await provider.searchPersonas(_query, limit: _pageSize, offset: currentOffset, loadMore: true);
      final newLength = provider.searchResults.length;

      if (newLength - prevLength < _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      print("Error loading more personas: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadMoreLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.read<ChatProvider>().clearSearchResults();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search for personas...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
                  prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, child) {
                final results = provider.searchResults;

                if (provider.isSearching && results.isEmpty) {
                  return Center(child: CircularProgressIndicator(color: accentColor));
                }

                if (results.isEmpty && _searchController.text.isNotEmpty) {
                  return const Center(
                    child: Text('No personas found', style: TextStyle(color: Colors.white54)),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    final persona = results[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () async {
                          // Await the chat screen so we stay in the search screen's context
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(persona: persona),
                            ),
                          );
                          // Once the user goes back from the ChatScreen, pop the SearchScreen
                          // to return to the ChatListScreen which is awaiting this pop.
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: cardColor,
                                backgroundImage: persona.imageUrl != null && persona.imageUrl!.isNotEmpty
                                    ? CachedNetworkImageProvider(persona.imageUrl!)
                                    : null,
                                onBackgroundImageError: persona.imageUrl != null && persona.imageUrl!.isNotEmpty
                                    ? (exception, stackTrace) {
                                        print("Exception caught while fetching image for ${persona.name}: $exception");
                                      }
                                    : null,
                                child: persona.imageUrl == null || persona.imageUrl!.isEmpty
                                    ? Text(persona.name[0])
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      persona.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      persona.desc,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
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
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
