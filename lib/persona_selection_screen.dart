import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Model/model.dart';
import 'Provider/chat_provider.dart';
import 'chat_screen.dart';

class PersonaSelectionScreen extends StatefulWidget {
  final Challenge challenge;

  const PersonaSelectionScreen({super.key, required this.challenge});

  @override
  State<PersonaSelectionScreen> createState() => _PersonaSelectionScreenState();
}

class _PersonaSelectionScreenState extends State<PersonaSelectionScreen> {
  bool _isLoading = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchAllPersonas();
    });
  }

  void _selectPersona(Persona persona) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            persona: persona,
            challenge: widget.challenge,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.colorScheme.surface;
    final accentColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Persona'),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.allPersonas.isEmpty) {
            return Center(child: CircularProgressIndicator(color: accentColor));
          }

          if (_localError != null) {
            return _buildErrorState(_localError!);
          }

          final suggestedIds = widget.challenge.suggestedPersonas ?? [];
          
          // Sort all personas so suggested ones appear at the top
          final sortedPersonas = List<Persona>.from(provider.allPersonas);
          sortedPersonas.sort((a, b) {
            final aSuggested = suggestedIds.contains(a.id);
            final bSuggested = suggestedIds.contains(b.id);
            if (aSuggested && !bSuggested) return -1;
            if (!aSuggested && bSuggested) return 1;
            return 0;
          });

          return Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Challenge context card summary
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.challenge.title,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.challenge.context?.goal ?? "Choose a persona to negotiate with.",
                              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Candidates Grid Title
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'AVAILABLE CANDIDATES',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),

                  // Candidates Grid
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final persona = sortedPersonas[index];
                          final isSuggested = suggestedIds.contains(persona.id);
                          return _buildPersonaCard(persona, cardColor, accentColor, isRecommended: isSuggested);
                        },
                        childCount: sortedPersonas.length,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 32),
                  ),
                ],
              ),

              // Full screen loading indicator
              if (_isLoading)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: accentColor),
                        const SizedBox(height: 16),
                        const Text(
                          'Starting diplomatic session...',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please wait while establishing secure link.',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPersonaCard(Persona persona, Color cardColor, Color accentColor, {required bool isRecommended}) {
    final recommendedBadgeColor = accentColor; // Premium Lime color
    return InkWell(
      onTap: () => _selectPersona(persona),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isRecommended ? recommendedBadgeColor : Colors.white10,
            width: isRecommended ? 2.0 : 1,
          ),
          boxShadow: [
            if (isRecommended)
              BoxShadow(
                color: recommendedBadgeColor.withOpacity(0.08),
                blurRadius: 12,
                spreadRadius: 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      color: cardColor,
                      child: persona.imageUrl != null
                          ? Image.network(persona.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildPlaceholder(persona.name[0]))
                          : _buildPlaceholder(persona.name[0]),
                    ),
                    if (isRecommended)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: recommendedBadgeColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 10, color: Colors.black),
                              SizedBox(width: 4),
                              Text(
                                'SUGGESTED',
                                style: TextStyle(color: Colors.black, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      persona.name,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      persona.desc,
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 2,
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
  }

  Widget _buildErrorState(String message) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 54, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            const Text(
              'Connection Lost',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _localError = null;
                });
                context.read<ChatProvider>().fetchAllPersonas();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(180, 48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String char) {
    return Center(child: Text(char, style: const TextStyle(fontSize: 32, color: Colors.white)));
  }
}
