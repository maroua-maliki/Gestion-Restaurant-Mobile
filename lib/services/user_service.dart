import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restaurantapp/models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Récupère un flux de TOUS les utilisateurs
  Stream<List<AppUser>> getUsers() {
    return _firestore
        .collection('users')
        // Le filtre .where() est retiré pour éviter les problèmes d'index
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return AppUser.fromFirestore(doc.data(), doc.id);
      }).toList();
    });
  }

  Future<String?> _callFunction(String name, Map<String, dynamic> data) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return "Session expirée. Veuillez vous reconnecter.";
    try {
      await currentUser.getIdToken(true);
      final callable = _functions.httpsCallable(name);
      await callable.call(data);
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? "Une erreur de communication est survenue.";
    } catch (e) {
      return 'Une erreur locale inattendue est survenue.';
    }
  }

  Future<String?> createUser(String email, String password, String displayName, String role) {
    return _callFunction('createUser', {'email': email, 'password': password, 'displayName': displayName, 'role': role});
  }

  Future<String?> updateUser(String uid, String email, String displayName, String role) {
    return _callFunction('updateUser', {'uid': uid, 'email': email, 'displayName': displayName, 'role': role});
  }

  Future<String?> deleteUser(String uid) {
    return _callFunction('deleteUser', {'uid': uid});
  }
  
  Future<String?> toggleUserStatus(String uid, bool newStatus) {
    return _callFunction('toggleUserStatus', {'uid': uid, 'isActive': newStatus});
  }
}
