import 'package:flutter/material.dart';
import 'package:restaurantapp/screens/serveur/mes_tables_screen.dart';

class ServeurScreen extends StatelessWidget {
  const ServeurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      padding: const EdgeInsets.all(16.0),
      crossAxisCount: 2,
      crossAxisSpacing: 16.0,
      mainAxisSpacing: 16.0,
      children: [
        _buildDashboardCard(
          context,
          icon: Icons.room_service, 
          label: 'Prendre une commande',
          onTap: () { /* TODO: Navigate to order screen */ }
        ),
        _buildDashboardCard(
          context, 
          icon: Icons.table_restaurant,
          label: 'Mes Tables',
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MesTablesScreen()))
        ),
      ],
    );
  }

  Widget _buildDashboardCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16.0),
            Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
