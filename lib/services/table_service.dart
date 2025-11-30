import 'package:cloud_firestore/cloud_firestore.dart';

class TableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Récupère un flux de toutes les tables
  Stream<QuerySnapshot> getTables() {
    return _firestore.collection('tables').orderBy('number').snapshots();
  }

  // Ajoute une nouvelle table
  Future<void> addTable(String tableNumber, int capacity) {
    return _firestore.collection('tables').add({
      'number': tableNumber,
      'capacity': capacity,
      'assignedServerId': null, // Non assignée par défaut
    });
  }

  // Assigne un serveur à une table
  Future<void> assignServerToTable(String tableId, String? serverId) {
    return _firestore.collection('tables').doc(tableId).update({
      'assignedServerId': serverId,
    });
  }

  // Supprime une table
  Future<void> deleteTable(String tableId) {
    return _firestore.collection('tables').doc(tableId).delete();
  }

  // Récupère les tables assignées à un serveur spécifique
  Stream<QuerySnapshot> getTablesForServer(String serverId) {
    return _firestore
        .collection('tables')
        .where('assignedServerId', isEqualTo: serverId)
        .orderBy('number')
        .snapshots();
  }
}
