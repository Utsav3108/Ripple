import 'package:flutter/material.dart';
import 'Model/model.dart';
import 'chat_screen.dart';

class ChallengeSelectionScreen extends StatelessWidget {
  final Persona persona;

  const ChallengeSelectionScreen({super.key, required this.persona});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    // Mock challenges for this persona
    final List<String> challenges = [
      'Discuss deal of \$30Bn with ${persona.name}',
      'Discuss about the Golf',
      'Plan the upcoming international summit',
      'Casual conversation about history',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Challenge', style: theme.appBarTheme.titleTextStyle),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      persona: persona,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: accentColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        challenges[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
