/*
 * main.dart — App entry point
 * Sets up the Provider for state management, configures the Material theme,
 * and decides whether to show the auth screen or main scaffold based on
 * whether the user is authenticated.
 *
 * Session restoration: on cold start (including browser reload) we call
 * restoreSession() before rendering anything. A loading indicator is shown
 * until the check completes so the user never sees a flash of the auth screen
 * when they have a valid persisted session.
 */
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease/providers/app_provider.dart';
import 'package:splitease/main_scaffold.dart';
import 'package:splitease/screens/auth_screen.dart';

void main() async {
  // Required for async operations before runApp (e.g., plugin init)
  WidgetsFlutterBinding.ensureInitialized();

  // Create the provider and restore any persisted session before rendering
  final appProvider = AppProvider();
  await appProvider.restoreSession();

  runApp(
    // ChangeNotifierProvider makes AppProvider available to all widgets in the tree
    ChangeNotifierProvider.value(
      value: appProvider,
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
        // Default card styling — no elevation, rounded corners, subtle border
        cardTheme: CardThemeData(
          elevation: 0,
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
          // Show a loading indicator until session restoration completes.
          // This prevents a flash of the auth screen for users with a valid session.
          if (!app.sessionRestored) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (app.isAuthenticated) {
            return const MainScaffold();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
