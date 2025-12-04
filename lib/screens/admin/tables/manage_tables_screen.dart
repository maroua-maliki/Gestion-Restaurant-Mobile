import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/models/user_model.dart';
import 'package:restaurantapp/services/table_service.dart';
import 'package:restaurantapp/services/user_service.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

// Restaurant theme colors
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);

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
      drawer: const AdminDrawer(),
      backgroundColor: _cream,
      appBar: AppBar(
        title: Text(
          'Gestion des Tables',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _deepBrown,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: _warmOrange), // Changed menu icon color here
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_cream, Color(0xFFFFF5E6)],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _tableService.getTables(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: _warmOrange));
            }
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text("Une erreur est survenue", style: GoogleFonts.inter(color: _deepBrown)),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            final tables = snapshot.data!.docs;

            return LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 900 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: tables.length,
                  itemBuilder: (context, index) => _buildTableCard(tables[index]),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_warmOrange, Color(0xFFD4500A)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _warmOrange.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showTableDialog(),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    'Ajouter',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _gold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.table_restaurant_outlined, size: 64, color: _gold),
          ),
          const SizedBox(height: 20),
          Text(
            "Aucune table",
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _deepBrown,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Ajoutez votre première table",
            style: GoogleFonts.inter(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTableCard(DocumentSnapshot tableDoc) {
    final tableData = tableDoc.data() as Map<String, dynamic>;
    final bool isAvailable = tableData['isAvailable'] ?? true;
    final String? serverId = tableData['assignedServerId'];

    return Container(
      decoration: BoxDecoration(
        color: isAvailable ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isAvailable ? _gold.withValues(alpha: 0.4) : Colors.grey[300]!,
          width: isAvailable ? 2 : 1,
        ),
        boxShadow: isAvailable ? [
          BoxShadow(
            color: _gold.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTableDialog(table: tableDoc),
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isAvailable ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_gold, _gold.withValues(alpha: 0.7)],
                    ) : null,
                    color: isAvailable ? null : Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.table_restaurant_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  tableData['number'] ?? 'N/A',
                  style: GoogleFonts.playfairDisplay(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isAvailable ? _deepBrown : Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline_rounded, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${tableData['capacity']} places',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const Spacer(),
                _buildStatusChip(serverId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? serverId) {
    if (serverId == null || serverId.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Libre',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(serverId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) return const SizedBox.shrink();
        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _warmOrange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_rounded, size: 14, color: _warmOrange),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  userData['displayName'] ?? 'Serveur',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _warmOrange,
                  ),
                ),
              ),
            ],
          ),
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
              backgroundColor: _cream,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEditing ? Icons.edit_rounded : Icons.table_restaurant_rounded,
                      color: _gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Modifier la Table' : 'Nouvelle Table',
                      style: GoogleFonts.playfairDisplay(
                        fontWeight: FontWeight.bold,
                        color: _deepBrown,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDialogTextField(numberController, 'Numéro', Icons.tag_rounded, (v) => v!.isEmpty ? 'Requis' : null),
                      const SizedBox(height: 16),
                      _buildDialogTextField(capacityController, 'Capacité', Icons.people_outline_rounded, (v) => v!.isEmpty ? 'Requis' : null, keyboardType: TextInputType.number),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold.withValues(alpha: 0.3)),
                        ),
                        child: SwitchListTile(
                          title: Text('Disponible', style: GoogleFonts.inter(color: _deepBrown)),
                          value: isAvailable,
                          activeColor: _warmOrange,
                          onChanged: (val) => setState(() => isAvailable = val),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _gold.withValues(alpha: 0.3)),
                        ),
                        child: StreamBuilder<List<AppUser>>(
                          stream: _userService.getUsers().map((users) => users.where((u) => u.role == 'Serveur' && u.isActive).toList()),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator(color: _warmOrange)),
                              );
                            }
                            final servers = snapshot.data!;
                            // Use a Map to ensure uniqueness by UID if needed, though servers list should be unique users
                            final uniqueServers = {for (var s in servers) s.uid: s}.values.toList();

                            final serverItems = uniqueServers.map((s) => DropdownMenuItem(
                              value: s.uid,
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _warmOrange.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      s.displayName.isNotEmpty ? s.displayName[0].toUpperCase() : 'S',
                                      style: GoogleFonts.playfairDisplay(
                                        color: _warmOrange,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      s.displayName, 
                                      style: GoogleFonts.inter(color: _deepBrown),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )).toList();
                            
                            final uniqueServerIds = uniqueServers.map((s) => s.uid).toSet();
                            if (selectedServerId != null && !uniqueServerIds.contains(selectedServerId)) {
                              selectedServerId = null;
                            }
                            
                            return DropdownButtonFormField<String>(
                              value: selectedServerId,
                              hint: Text('Assigner un serveur', style: GoogleFonts.inter(color: Colors.grey[500])),
                              isExpanded: true,
                              // Reduced max height of the dropdown menu
                              menuMaxHeight: 200,
                              alignment: Alignment.centerLeft,
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              icon: Icon(Icons.arrow_drop_down_rounded, color: _warmOrange),
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.person_outline_rounded, color: _warmOrange),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              selectedItemBuilder: (BuildContext context) {
                                return [
                                  DropdownMenuItem(
                                    value: null, 
                                    child: Text('Aucun (Libre)', style: GoogleFonts.inter(color: Colors.grey[600]))
                                  ),
                                  ...uniqueServers.map((s) => DropdownMenuItem(
                                    value: s.uid,
                                    child: Text(s.displayName, style: GoogleFonts.inter(color: _deepBrown), overflow: TextOverflow.ellipsis)
                                  ))
                                ];
                              },
                              items: [
                                DropdownMenuItem(
                                  value: null, 
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: Icon(Icons.person_off_rounded, size: 14, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Aucun (Libre)', 
                                        style: GoogleFonts.inter(color: Colors.grey[600])
                                      ),
                                    ],
                                  )
                                ),
                                ...serverItems
                              ],
                              onChanged: (val) => setState(() => selectedServerId = val),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmDelete(table);
                    },
                    child: Text('Supprimer', style: GoogleFonts.inter(color: Colors.red)),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler', style: GoogleFonts.inter(color: Colors.grey[600])),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_warmOrange, Color(0xFFD4500A)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        if (formKey.currentState!.validate()) {
                          final data = {
                            'number': numberController.text,
                            'capacity': int.parse(capacityController.text),
                            'isAvailable': isAvailable,
                            'assignedServerId': selectedServerId
                          };
                          if (isEditing) {
                            await table.reference.update(data);
                          } else {
                            await _tableService.addTable(numberController.text, int.parse(capacityController.text));
                          }
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Text(
                          isEditing ? 'Enregistrer' : 'Créer',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label, IconData icon, String? Function(String?) validator, {TextInputType? keyboardType}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _gold.withValues(alpha: 0.3)),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: _deepBrown),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: _warmOrange),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: validator,
      ),
    );
  }

  void _confirmDelete(DocumentSnapshot table) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cream,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_rounded, color: Colors.red, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Confirmer la suppression',
                  style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: _deepBrown, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Text(
            "Êtes-vous sûr de vouloir supprimer la table n°${table['number']} ? Cette action est irréversible.",
            style: GoogleFonts.inter(color: Colors.grey[700]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Annuler", style: GoogleFonts.inter(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                await _tableService.deleteTable(table.id);
                if (mounted) Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text("Supprimer", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }
}
