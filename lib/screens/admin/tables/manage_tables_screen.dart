import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restaurantapp/models/user_model.dart';
import 'package:restaurantapp/services/table_service.dart';
import 'package:restaurantapp/services/user_service.dart';

class ManageTablesScreen extends StatefulWidget {
  const ManageTablesScreen({super.key});

  @override
  State<ManageTablesScreen> createState() => _ManageTablesScreenState();
}

class _ManageTablesScreenState extends State<ManageTablesScreen> {
  final TableService _tableService = TableService();
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Tables'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _tableService.getTables(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Une erreur est survenue."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Aucune table. Cliquez sur + pour en ajouter."));
          }

          final tables = snapshot.data!.docs;

          return LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  childAspectRatio: 1, // Des cartes carrées
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: tables.length,
                itemBuilder: (context, index) {
                  final table = tables[index];
                  return _buildTableCard(table);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTableDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  Widget _buildTableCard(DocumentSnapshot tableDoc) {
    final tableData = tableDoc.data() as Map<String, dynamic>;
    final bool isAvailable = tableData['isAvailable'] ?? true;
    final String? serverId = tableData['assignedServerId'];
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2.0,
      color: isAvailable ? Colors.white : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isAvailable ? BorderSide(color: colorScheme.primary, width: 1.5) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showTableDialog(table: tableDoc),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.table_restaurant_outlined,
                size: 44, // Réduction de la taille de l'icône
                color: isAvailable ? colorScheme.primary : Colors.grey[400],
              ),
              const SizedBox(height: 8), // Réduction de l'espacement
              Text(
                tableData['number'] ?? 'N/A',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                '${tableData['capacity'].toString()} places',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              _buildStatusChip(serverId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? serverId) {
    if (serverId == null || serverId.isEmpty) {
      return Chip(
        label: const Text('Libre'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer, fontWeight: FontWeight.bold, fontSize: 11),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 4),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(serverId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        return Chip(
          avatar: const Icon(Icons.person, size: 16),
          label: Text(userData['displayName'] ?? 'Serveur', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          backgroundColor: Colors.grey.shade200,
          side: BorderSide.none,
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      },
    );
  }

   void _showTableDialog({DocumentSnapshot? table}) {
    final isEditing = table != null;
    final tableData = isEditing ? table.data() as Map<String, dynamic> : {};

    final formKey = GlobalKey<FormState>();
    final numberController = TextEditingController(text: tableData['number'] ?? '');
    final capacityController = TextEditingController(text: tableData['capacity']?.toString() ?? '');
    bool isAvailable = tableData['isAvailable'] ?? true;
    String? selectedServerId = tableData['assignedServerId'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Modifier la Table' : 'Nouvelle Table'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: numberController,
                        decoration: const InputDecoration(labelText: 'Numéro', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: capacityController,
                        decoration: const InputDecoration(labelText: 'Capacité', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      SwitchListTile(
                        title: const Text('Disponible'),
                        value: isAvailable,
                        onChanged: (val) => setState(() => isAvailable = val),
                      ),
                      StreamBuilder<List<AppUser>>(
                          stream: _userService.getUsers().map((users) => users.where((u) => u.role == 'Serveur').toList()),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const CircularProgressIndicator();
                            final servers = snapshot.data!;
                            final serverItems = servers.toSet().map((s) => DropdownMenuItem(value: s.uid, child: Text(s.displayName))).toList();
                            final uniqueServerIds = servers.map((s) => s.uid).toSet();
                            if (selectedServerId != null && !uniqueServerIds.contains(selectedServerId)) {
                                selectedServerId = null;
                            }
                            return DropdownButtonFormField<String>(
                              value: selectedServerId,
                              hint: const Text('Assigner un serveur'),
                              isExpanded: true,
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Aucun (Libre)')),
                                ...serverItems
                              ],
                              onChanged: (val) => setState(() => selectedServerId = val),
                            );
                          }),
                    ],
                  ),
                ),
              ),
              actions: [
                if(isEditing)
                  TextButton(
                     onPressed: () {
                       Navigator.pop(context);
                       _confirmDelete(table);
                     },
                     child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
                  ),
                const Spacer(),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final data = {
                        'number': numberController.text,
                        'capacity': int.parse(capacityController.text),
                        'isAvailable': isAvailable,
                        'assignedServerId': selectedServerId,
                      };

                      if (isEditing) {
                        await table.reference.update(data);
                      } else {
                        await _firestore.collection('tables').add(data);
                      }
                      if (mounted) Navigator.pop(context);
                    }
                  },
                  child: Text(isEditing ? 'Enregistrer' : 'Créer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(DocumentSnapshot table) {
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer la table ${(table.data() as Map<String, dynamic>)['number']} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _tableService.deleteTable(table.id);
              if (mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

   FirebaseFirestore get _firestore => FirebaseFirestore.instance;
}
