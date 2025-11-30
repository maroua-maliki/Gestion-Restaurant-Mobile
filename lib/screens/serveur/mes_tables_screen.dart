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

        // Gérer l'erreur de précondition Firestore
        if (snapshot.hasError) {
          print(snapshot.error); // Garder pour le débogage
          String errorMessage = "Une erreur inattendue est survenue.";
          if (snapshot.error is FirebaseException) {
            final e = snapshot.error as FirebaseException;
            if (e.code == 'failed-precondition') {
              errorMessage = "La base de données nécessite un index. Veuillez cliquer sur le lien dans la console de débogage pour le créer.";
            }
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(errorMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.red)),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.table_restaurant_outlined, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                const Text("Aucune table ne vous est assignée.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "Vérifiez que le rôle 'Serveur' est bien assigné à l'utilisateur avec l'ID: ${currentUser!.uid}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            )
          );
        }

        final tables = snapshot.data!.docs;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
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
    final bool isOccupied = false; 

    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          print("Table sélectionnée: ${tableData['number']}");
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant,
              size: 48,
              color: isOccupied ? Colors.red.shade700 : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              tableData['number'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text('${tableData['capacity']} places', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
