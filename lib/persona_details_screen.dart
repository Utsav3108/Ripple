import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'Model/model.dart';
import 'Provider/chat_provider.dart';

class PersonaDetailsScreen extends StatefulWidget {
  final Persona persona;
  final int? currentSessionId;

  const PersonaDetailsScreen({
    super.key,
    required this.persona,
    this.currentSessionId,
  });

  @override
  State<PersonaDetailsScreen> createState() => _PersonaDetailsScreenState();
}

class _PersonaDetailsScreenState extends State<PersonaDetailsScreen> {
  PersonaDetails? _details;
  final List<PersonaChatSession> _chats = [];
  
  bool _isLoadingDetails = true;
  bool _isLoadingChats = true;
  bool _isLoadMoreLoading = false;
  int _currentChatsPage = 1;
  bool _hasMoreChats = false;
  String? _errorMessage;

  bool _isDescExpanded = false;
  bool _isExpertiseExpanded = false;
  bool _isLikesExpanded = false;
  bool _isDislikesExpanded = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchDetailsAndChats();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetailsAndChats() async {
    setState(() {
      _isLoadingDetails = true;
      _isLoadingChats = true;
      _errorMessage = null;
      _chats.clear();
      _currentChatsPage = 1;
    });

    final provider = context.read<ChatProvider>();

    // Fetch Details
    try {
      final details = await provider.fetchPersonaDetails(widget.persona.id);
      setState(() {
        _details = details;
        _isLoadingDetails = false;
      });
    } catch (e) {
      print("Error fetching details: $e");
      setState(() {
        _isLoadingDetails = false;
        _errorMessage = e.toString().contains("404") 
            ? "Persona profile not found." 
            : "Failed to load persona details.";
      });
    }

    // Fetch Chats (Page 1)
    try {
      final chatsData = await provider.fetchPersonaChats(widget.persona.id, page: 1, limit: 100);
      setState(() {
        _chats.addAll(chatsData.chats);
        _hasMoreChats = chatsData.hasMore;
        _isLoadingChats = false;
      });
    } catch (e) {
      print("Error fetching chats: $e");
      setState(() {
        _isLoadingChats = false;
      });
    }
  }

  Future<void> _loadMoreChats() async {
    if (_isLoadMoreLoading || !_hasMoreChats) return;

    setState(() {
      _isLoadMoreLoading = true;
    });

    final provider = context.read<ChatProvider>();
    final nextPage = _currentChatsPage + 1;

    try {
      final chatsData = await provider.fetchPersonaChats(widget.persona.id, page: nextPage, limit: 100);
      setState(() {
        _chats.addAll(chatsData.chats);
        _currentChatsPage = nextPage;
        _hasMoreChats = chatsData.hasMore;
        _isLoadMoreLoading = false;
      });
    } catch (e) {
      print("Error loading more chats: $e");
      setState(() {
        _isLoadMoreLoading = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMoreChats();
    }
  }

  void _startOrContinueChat(PersonaChatSession? recentSession) {
    if (recentSession != null) {
      // Pop and return the recent session ID to return to the active chat in ChatScreen
      Navigator.pop(context, recentSession.personaSessionId);
    } else {
      // Pop to return to the current active chat screen
      Navigator.pop(context);
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final compareDate = DateTime(dt.year, dt.month, dt.day);

    if (compareDate == today) {
      return "Today at ${DateFormat('jm').format(dt)}";
    } else if (compareDate == yesterday) {
      return "Yesterday at ${DateFormat('jm').format(dt)}";
    } else {
      return DateFormat('MMM d, yyyy').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    
    // Safely look up the recent session using a loop to avoid type check errors during initial load
    PersonaChatSession? recentSession;
    for (final s in _chats) {
      if (s.status == "recent") {
        recentSession = s;
        break;
      }
    }

    // Filter out previous chats (excluding the recent one)
    final previousChats = _chats.where((s) => s.status != "recent").toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Details",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: const [], // Hidden actions
      ),
      body: _isLoadingDetails && _chats.isEmpty
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hero Section
                      _buildHeroSection(theme, accentColor, recentSession),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(color: Colors.white12, height: 1),
                      ),
                      
                      // About Section
                      _buildAboutSection(theme),
                      
                      // Expertise Section
                      if (_details?.expertise != null && _details!.expertise!.isNotEmpty)
                        _buildExpertiseSection(theme),
                      
                      // Likes & Dislikes Section
                      if (_details?.likesDislikes != null && 
                          (_details!.likesDislikes!.likes.isNotEmpty || _details!.likesDislikes!.dislikes.isNotEmpty))
                        _buildLikesDislikesSection(theme),
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Divider(color: Colors.white12, height: 1),
                      ),

                      // Conversations Section (Includes Recent conversation card and pop navigation)
                      _buildConversationsSection(theme, accentColor, recentSession, previousChats),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeroSection(ThemeData theme, Color accentColor, PersonaChatSession? recentSession) {
    final name = _details?.name ?? widget.persona.name;
    final category = _details?.category ?? widget.persona.desc;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: CircleAvatar(
              radius: 64,
              backgroundColor: theme.colorScheme.surface,
              backgroundImage: widget.persona.imageUrl != null && widget.persona.imageUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.persona.imageUrl!)
                  : null,
              child: widget.persona.imageUrl == null || widget.persona.imageUrl!.isEmpty
                  ? Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.outfit(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              name,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2), width: 1),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Primary CTA Button
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => _startOrContinueChat(recentSession),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  recentSession != null ? "Continue Chat" : "Start Chat",
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(ThemeData theme) {
    final descText = _details?.desc ?? widget.persona.desc;
    
    // Check if description is long enough to warrant Read More
    final showReadMoreButton = descText.length > 150;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            descText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: _isDescExpanded ? null : 3,
            overflow: _isDescExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (showReadMoreButton) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescExpanded = !_isDescExpanded;
                });
              },
              child: Text(
                _isDescExpanded ? "Read Less" : "Read More",
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpertiseSection(ThemeData theme) {
    final expertiseList = _details?.expertise ?? [];
    if (expertiseList.isEmpty) return const SizedBox.shrink();

    final showMore = !_isExpertiseExpanded && expertiseList.length > 3;
    final displayedList = showMore ? expertiseList.take(3).toList() : expertiseList;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Expertise",
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...displayedList.map((exp) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    exp,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }),
              if (showMore)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExpertiseExpanded = true;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                    ),
                    child: Text(
                      "+ ${expertiseList.length - 3} other",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLikesDislikesSection(ThemeData theme) {
    final likes = _details?.likesDislikes?.likes ?? [];
    final dislikes = _details?.likesDislikes?.dislikes ?? [];

    final showMoreLikes = !_isLikesExpanded && likes.length > 3;
    final displayedLikes = showMoreLikes ? likes.take(3).toList() : likes;

    final showMoreDislikes = !_isDislikesExpanded && dislikes.length > 3;
    final displayedDislikes = showMoreDislikes ? dislikes.take(3).toList() : dislikes;

    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (likes.isNotEmpty) ...[
            Text(
              "❤️ Likes",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...displayedLikes.map((like) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.withOpacity(0.2)),
                    ),
                    child: Text(
                      like,
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
                if (showMoreLikes)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLikesExpanded = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        "+ ${likes.length - 3} other",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          if (dislikes.isNotEmpty) ...[
            Text(
              "🚫 Dislikes",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...displayedDislikes.map((dislike) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Text(
                      dislike,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
                if (showMoreDislikes)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isDislikesExpanded = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
                      ),
                      child: Text(
                        "+ ${dislikes.length - 3} other",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationsSection(
    ThemeData theme,
    Color accentColor,
    PersonaChatSession? recentSession,
    List<PersonaChatSession> previousChats,
  ) {
    if (_isLoadingChats && _chats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (_chats.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.chat_bubble_outline, color: Colors.white30, size: 48),
              const SizedBox(height: 16),
              Text(
                "No conversations yet",
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Start your first conversation with ${_details?.name ?? widget.persona.name}.",
                style: const TextStyle(color: Colors.white38, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final cardColor = theme.colorScheme.surface;
    
    // Sort currently loaded chats in memory by personaSessionId to assign creation indices
    final sortedChats = List<PersonaChatSession>.from(_chats);
    sortedChats.sort((a, b) => a.personaSessionId.compareTo(b.personaSessionId));
    final Map<int, int> creationIndices = {};
    for (int i = 0; i < sortedChats.length; i++) {
      creationIndices[sortedChats[i].personaSessionId] = i + 1;
    }

    // Resolve currently loaded session ID to check if it matches the recent active session
    final activeSessionId = widget.currentSessionId ?? context.read<ChatProvider>().getActiveSessionId(widget.persona.id);
    final showRecentSection = recentSession != null && recentSession.personaSessionId != activeSessionId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Conversation Card (formerly Last Conversation, visible only when current session != recent)
          if (showRecentSection) ...[
            Text(
              "Recent",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _startOrContinueChat(recentSession),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.forum_outlined, color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Conversation #${creationIndices[recentSession!.personaSessionId] ?? recentSession.personaSessionId}",
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDateTime(recentSession.lastUpdatedAt),
                            style: const TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: theme.colorScheme.primary, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
          ],

          // Previous Conversations List
          if (previousChats.isNotEmpty) ...[
            Text(
              "Previous Conversations",
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: previousChats.length,
              separatorBuilder: (context, idx) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final session = previousChats[index];
                final isSessionBlocked = session.status == "blocked";
                
                final sessionIndex = creationIndices[session.personaSessionId] ?? session.personaSessionId;
                final title = "Conversation #$sessionIndex";

                return InkWell(
                  onTap: () {
                    // Pop details screen and return selected past session ID to ChatScreen
                    Navigator.pop(context, session.personaSessionId);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSessionBlocked ? cardColor.withOpacity(0.5) : cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSessionBlocked 
                                ? Colors.red.withOpacity(0.08) 
                                : Colors.white.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSessionBlocked ? Icons.lock_outline : Icons.chat_bubble_outline,
                            color: isSessionBlocked ? Colors.redAccent : Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Updated ${_formatDateTime(session.lastUpdatedAt)}",
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        
                        // Status Badge
                        if (isSessionBlocked)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 10, color: Colors.redAccent),
                                SizedBox(width: 4),
                                Text(
                                  "Blocked",
                                  style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fiber_manual_record, size: 8, color: Colors.blueAccent),
                                SizedBox(width: 4),
                                Text(
                                  "Active",
                                  style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
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
          ],
          
          if (_isLoadMoreLoading)
            Padding(
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
            ),
        ],
      ),
    );
  }
}
