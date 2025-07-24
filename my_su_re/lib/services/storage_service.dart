import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProductImage(File image) async {
    final ref = _storage
        .ref()
        .child('product_images')
        .child('${DateTime.now().toIso8601String()}');
    await ref.putFile(image);
    return await ref.getDownloadURL();
  }
}