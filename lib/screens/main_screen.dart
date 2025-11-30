import 'package:flutter/material.dart';
import 'package:restaurantapp/screens/admin/admin_screen.dart';
import 'package:restaurantapp/screens/chef/chef_screen.dart';
import 'package:restaurantapp/screens/profile/profile_screen.dart';
import 'package:restaurantapp/screens/serveur/serveur_screen.dart';
import 'package:restaurantapp/screens/settings/settings_screen.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';
import 'package:restaurantapp/widgets/chef_drawer.dart';
import 'package:restaurantapp/widgets/serveur_drawer.dart';

class MainScreen extends StatefulWidget {
  final String userRole;
  const MainScreen({super.key, required this.userRole});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Le titre de l'AppBar changera en fonction de la page
  final List<String> _titles = ['Accueil', 'Profil', 'Paramètres'];

  // Le contenu de la page changera
  List<Widget> _buildPages() {
    return [
      _getHomeScreen(),
      const ProfileScreen(), // Profile et Settings n'ont pas besoin de leur propre Scaffold
      const SettingsScreen(),
    ];
  }

  // La barre latérale changera en fonction du rôle
  Widget? _getDrawer() {
    switch (widget.userRole) {
      case 'Admin':
        return const AdminDrawer();
      case 'Chef':
        return const ChefDrawer();
      case 'Serveur':
        return const ServeurDrawer();
      default:
        return null;
    }
  }

  // L'écran d'accueil changera en fonction du rôle
  Widget _getHomeScreen() {
    switch (widget.userRole) {
      case 'Admin':
        return const AdminScreen();
      case 'Chef':
        return const ChefScreen();
      case 'Serveur':
        return const ServeurScreen();
      default:
        return const Center(child: Text('Rôle non reconnu.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return Scaffold(
      // Un seul AppBar, dont le titre change
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      // Une seule barre latérale, qui dépend du rôle
      drawer: _getDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}
