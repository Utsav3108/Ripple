import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'chat_list_screen.dart';
import 'login_screen.dart';
import 'Provider/chat_provider.dart';
import 'Theme/app_theme.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<ChatProvider>(
        builder: (context, provider, child) {
          return provider.isAuthenticated
              ? const ChatListScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
