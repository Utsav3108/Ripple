import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_list_screen.dart';
import 'Provider/chat_provider.dart';
import 'Theme/app_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ripple',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const ChatListScreen(),
    );
  }
}
