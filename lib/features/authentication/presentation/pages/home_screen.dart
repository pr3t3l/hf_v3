// hf_v3/lib/features/authentication/presentation/pages/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hf_v3/features/authentication/presentation/controllers/auth_controller.dart';
import 'package:hf_v3/l10n/app_localizations.dart';
import 'package:hf_v3/providers/auth_provider.dart';
import 'package:hf_v3/features/family_structure/presentation/pages/family_selection_screen.dart'; // Import FamilySelectionScreen
import 'package:hf_v3/features/family_structure/presentation/pages/notifications_screen.dart'; // Import NotificationsScreen

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0; // To track the selected tab in BottomNavigationBar

  // List of widgets (pages) for the BottomNavigationBar
  // We'll expand this as we add more modules
  static final List<Widget> _widgetOptions = <Widget>[
    const Center(
      child: Text('Inicio del Dashboard'),
    ), // Placeholder for Home Dashboard
    const FamilySelectionScreen(), // Family module
    const Center(
      child: Text('Diario (Próximamente)'),
    ), // Placeholder for Journal
    const Center(child: Text('Juegos (Próximamente)')), // Placeholder for Games
    const Center(
      child: Text('Perfil (Próximamente)'),
    ), // Placeholder for Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = ref.read(authControllerProvider.notifier);
    final user = ref.watch(authStateProvider).value; // Get current user
    final appLocalizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min, // To make the row take minimum space
          children: [
            Image.asset(
              'assets/images/logo_healthy_families.jpg', // Your logo path
              height: 30, // Smaller for AppBar
              width: 30,
            ),
            const SizedBox(width: 8),
            Text(appLocalizations.homeTitle),
          ],
        ),
        centerTitle: true, // Center the title and logo
        actions: [
          // Notifications Button (top right)
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          // Profile/Settings Button (placeholder for image)
          IconButton(
            icon: const Icon(
              Icons.settings,
            ), // Placeholder for profile image/settings
            onPressed: () {
              // TODO: Navigate to User Profile/Settings Screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(appLocalizations.settingsComingSoon)),
              );
            },
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
          // Logout Button (next to profile/settings)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authController.signOut();
            },
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ],
      ),
      body: _widgetOptions.elementAt(
        _selectedIndex,
      ), // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: appLocalizations.navHome, // Localized label
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.family_restroom),
            label: appLocalizations.navFamily, // Localized label
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.book),
            label: appLocalizations.navJournal, // Localized label
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.games),
            label: appLocalizations.navGames, // Localized label
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: appLocalizations.navProfile, // Localized label
          ),
        ],
        currentIndex: _selectedIndex, // Current selected item
        onTap: _onItemTapped, // Handle tap
        // Theme applied automatically via ThemeData.bottomNavigationBarTheme
      ),
    );
  }
}
