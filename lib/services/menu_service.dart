import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // --- Catégories ---
  Stream<QuerySnapshot> getCategories() {
    return _firestore.collection('categories').orderBy('name').snapshots();
  }
  Future<void> addCategory(Map<String, dynamic> data) {
    return _firestore.collection('categories').add(data);
  }
  Future<void> updateCategory(String id, Map<String, dynamic> data) {
    return _firestore.collection('categories').doc(id).update(data);
  }
  Future<void> deleteCategory(String id) {
    return _firestore.collection('categories').doc(id).delete();
  }

  // --- Plats (Menu Items) ---
  Stream<QuerySnapshot> getMenuItems(String? categoryId) {
    // Si un categoryId est fourni, on filtre. Sinon, on récupère tout.
    if (categoryId == null || categoryId.isEmpty) {
      return _firestore.collection('menuItems').snapshots();
    } else {
      return _firestore.collection('menuItems').where('categoryId', isEqualTo: categoryId).snapshots();
    }
  }

  // ... (le reste du service reste identique) ...
  Future<String> uploadImage(File image, String menuItemName) async {
    final String fileName = '${menuItemName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final Reference ref = _storage.ref().child('menu_images/$fileName');
    final UploadTask uploadTask = ref.putFile(image);
    final TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
  Future<void> addMenuItem(Map<String, dynamic> data) {
    return _firestore.collection('menuItems').add(data);
  }
  Future<void> updateMenuItem(String id, Map<String, dynamic> data) {
    return _firestore.collection('menuItems').doc(id).update(data);
  }
  Future<void> deleteMenuItem(String id) {
    return _firestore.collection('menuItems').doc(id).delete();
  }
  Future<File?> pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) return File(pickedFile.path);
    return null;
  }
}
