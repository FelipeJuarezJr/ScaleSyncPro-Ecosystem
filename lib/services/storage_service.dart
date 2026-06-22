import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// StorageService uses ScaleSyncPro Firebase for all file storage operations
/// Gets user ID from ReptiGram Firebase Auth (default app)
/// Stores all files in ScaleSyncPro Firebase Storage
class StorageService {
  // Use default FirebaseStorage instance
  FirebaseStorage get _storage => FirebaseStorage.instance;
  
  // Get user ID from default Auth instance
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  /// Upload a file to user's storage folder
  /// [path] is the relative path from the user's folder (e.g., 'reptiles/image.jpg')
  /// Returns the download URL
  Future<String> uploadFile({
    required String path,
    required Uint8List data,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child('users/$_userId/$path');
      final uploadTask = ref.putData(
        data,
        SettableMetadata(contentType: contentType),
      );
      
      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload an animal asset to the isolated, immutable path:
  /// users/{userId}/animals/{animalId}/assets/{assetId}
  Future<String> uploadAnimalAsset({
    required String userId,
    required String animalId,
    required String assetId,
    required Uint8List data,
    String? contentType,
  }) async {
    try {
      final ref = _storage.ref().child('users/$userId/animals/$animalId/assets/$assetId');
      final uploadTask = ref.putData(
        data,
        SettableMetadata(
          contentType: contentType,
          cacheControl: 'public, max-age=31536000', // Enforce high caching header
        ),
      );
      await uploadTask;
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload animal asset: $e');
    }
  }

  /// Delete a file from user's storage
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child('users/$_userId/$path');
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get download URL for a file
  Future<String> getDownloadURL(String path) async {
    try {
      final ref = _storage.ref().child('users/$_userId/$path');
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }
}
