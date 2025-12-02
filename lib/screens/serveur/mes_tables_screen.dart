import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/services/table_service.dart';
import 'package:restaurantapp/widgets/serveur_drawer.dart';

class MesTablesScreen extends StatefulWidget {
  const MesTablesScreen({super.key});

  @override
  State<MesTablesScreen> createState() => _MesTablesScreenState();
}

class _MesTablesScreenState extends State<MesTablesScreen> {
  final TableService _tableService = TableService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Tables'),
      ),
      drawer: const ServeurDrawer(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (currentUser == null) {
      return const Center(child: Text("Utilisateur non connecté."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _tableService.getTablesForServer(currentUser!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          // Affichage de l'erreur pour le débogage
          return Center(child: Text("Une erreur est survenue: ${snapshot.error}"));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Aucune table ne vous est assignée."));
        }

        final tables = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            // Ajustement du ratio pour éviter l'overflow
            childAspectRatio: 1.0,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
          ),
          itemCount: tables.length,
          itemBuilder: (context, index) {
            final table = tables[index];
            return _buildTableCard(table);
          },
        );
      },
    );
  }

  Widget _buildTableCard(DocumentSnapshot tableDoc) {
    final tableData = tableDoc.data() as Map<String, dynamic>;
    final bool isAvailable = tableData['isAvailable'] ?? true;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isAvailable ? colorScheme.primary : Colors.grey.shade300, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.table_restaurant,
              size: 40,
              color: isAvailable ? colorScheme.primary : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              tableData['number'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text('${tableData['capacity']} places', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const Spacer(),
            // Intégration du Switch pour changer directement le statut
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isAvailable ? 'Disponible' : 'Occupée',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (newValue) {
                    tableDoc.reference.update({'isAvailable': newValue});
                  },
                  activeColor: colorScheme.primary,
                  inactiveThumbColor: Colors.red.shade700,
                  inactiveTrackColor: Colors.red.shade100,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
