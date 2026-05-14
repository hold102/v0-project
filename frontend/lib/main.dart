/*
 * main.dart — App entry point
 * Sets up the Provider for state management, configures the Material theme,
 * and decides whether to show the auth screen or main scaffold based on
 * whether the user is authenticated.
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/main_scaffold.dart';
import 'package:splitease/screens/auth_screen.dart';

void main() {
  // Required for async operations before runApp (e.g., plugin init)
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // ChangeNotifierProvider makes AppProvider available to all widgets in the tree
    ChangeNotifierProvider(
      create: (_) => AppProvider()..loadData(),  // ..loadData() calls it immediately after creation
      child: const SplitEaseApp(),
    ),
  );
}

class SplitEaseApp extends StatelessWidget {
  const SplitEaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitEase',
      debugShowCheckedModeBanner: false,  // Hide the debug banner in the corner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,  // Generate a full color scheme from one seed color
          brightness: Brightness.light,
        ),
        useMaterial3: true,  // Enable Material Design 3
        // Default card styling — subtle shadow, rounded corners, no border
        cardTheme: CardThemeData(
          elevation: 0,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        // Default text field styling — rounded, filled background
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      // Consumer rebuilds when AppProvider notifies — switches between auth and main UI
      home: Consumer<AppProvider>(
        builder: (context, app, _) {
          if (app.isAuthenticated) {
            return const MainScaffold();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
