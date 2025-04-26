import 'dart:io';
import 'dart:typed_data';

import 'package:naturafit/services/user_provider.dart';
import 'package:naturafit/utilities/firebase_my_dictionary.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in anonymously
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  // Store user role in Firestore
  Future<void> storeUserData({
    required String userId,
    required String role,
    required String username,
  }) async {
    // Save user data to the 'users' collection
    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      fbRandomName: username,
      'role': role,
      'isLoggedIn': true,
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'lastLogout': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Save user settings to the 'settings' collection
    await _firestore.collection('settings').doc(userId).set({
      'colorMode': 'light',
      'language': 'english',
    }, SetOptions(merge: true));
  }

  // Save user ID to keychain
  /*
  Future<void> saveUserIdLocally(String userId) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("CoachTrackUserId", userId);
    } else {
      await FlutterKeychain.put(key: "CoachTrackUserId", value: userId);
    }
  }
  */

  // Get user ID from keychain
  /*
  Future<String?> getUserIdLocally() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString("CoachTrackUserId");
    } else {
      return await FlutterKeychain.get(key: "CoachTrackUserId");
    }
  }
  */

  // Delete user ID from keychain (useful for logout)
  /*
  Future<void> deleteUserIdLocally() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("CoachTrackUserId");
    } else {
      await FlutterKeychain.remove(key: "CoachTrackUserId");
    }
  }
  */

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data();
    }
    return null;
  }

  Future<void> logoutUser(String userId) async {
    try {
      // Update user status in Firestore
      await _firestore.collection('users').doc(userId).update({
        'isLoggedIn': false,
        'lastLogout': FieldValue.serverTimestamp(),
      });

      // Sign out from Firebase Auth
      await _auth.signOut();

      // Clear local storage
      //await deleteUserIdLocally(); // Using our platform-aware method instead of direct FlutterKeychain call
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }

  Future<void> storeInitialUserData({
    required String userId,
    required String role,
    required String username,
    required String trainerClientId,
    required bool hasClientProfile,
    required String timeFormat,
    required String dateFormat,
    required String language,
  }) async {

    
    await _firestore.collection('users').doc(userId).set({
      'userId': userId,
      'trainerClientId': trainerClientId,
      'hasClientProfile': hasClientProfile,
      fbFullName: username,
      fbRandomName: username,
      'role': role,
      'isLoggedIn': false, // Will be set to true after completing onboarding
      'createdAt': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'onboardingCompleted': false,
      'onboardingStep': 1,
      'timeFormat': timeFormat,
      'dateFormat': dateFormat,
      'language': language,
    }, SetOptions(merge: true));
  }

  Future<void> updateUser(
      Map<String, dynamic> data, BuildContext context) async {
      final userProvider = context.read<UserProvider>();
      final userId = userProvider.userData?['userId'];
      final linkedTrainerId = userProvider.userData?['linkedTrainerId'];
      final trainerClientId = userProvider.userData?['trainerClientId'];
      final role = userProvider.userData?['role'];
      if (userId == null) throw Exception('No user logged in');
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (role == 'client' && linkedTrainerId != null && linkedTrainerId.toString().isNotEmpty) {
        await _firestore.collection('users').doc(linkedTrainerId).update({
          ...data,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      if (role == 'trainer' && trainerClientId != null && trainerClientId.toString().isNotEmpty) {
        await _firestore.collection('users').doc(trainerClientId).update({
          ...data,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      
    } catch (e) {
      throw Exception('Failed to update trainer data: $e');
    }
  }

  

  Future<String> uploadProfileImage(File imageFile) async {
    // Create compressed file
    final dir = await getTemporaryDirectory();
    final targetPath =
        path.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    final compressedFile = await FlutterImageCompress.compressAndGetFile(
      imageFile.path,
      targetPath,
      quality: 70,
      minWidth: 500,
      minHeight: 500,
    );

    if (compressedFile == null) throw Exception('Failed to compress image');

    // Convert XFile to File
    final compressedImageFile = File(compressedFile.path);

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef =
        storageRef.child('profile_images/${path.basename(targetPath)}');

    await imageRef.putFile(compressedImageFile);
    return await imageRef.getDownloadURL();
  }

  Future<String> uploadProfileImageBytes(Uint8List imageBytes) async {
    final String fileName = 'profile_images/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final storageRef = FirebaseStorage.instance.ref().child(fileName);
    
    // Upload the image bytes directly
    await storageRef.putData(
      imageBytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'picked-file-path': fileName}
      ),
    );

    // Get and return the download URL
    return await storageRef.getDownloadURL();
  }

  Future<String> createTrainerClientProfile(String trainerId) async {
    try {
      // Generate a new unique ID for the trainer's client profile
      final trainerClientId =
          FirebaseFirestore.instance.collection('users').doc().id;

      // Create a new document for trainer's client profile
      await _firestore.collection('users').doc(trainerClientId).set({
        'userId': trainerClientId,
        'role': 'client',
        'linkedTrainerId': trainerId,
        'isTrainerClientProfile': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'onboardingCompleted': false,
      });

      return trainerClientId;
    } catch (e) {
      debugPrint('Error creating trainer client profile: $e');
      rethrow;
    }
  }

  Future<void> updateTrainerProfile(
      String trainerId, String trainerClientId) async {
    await _firestore.collection('users').doc(trainerId).update({
      'trainerClientId': trainerClientId,
      'hasClientProfile': true,
    });
  }

  Future<void> updateConnectionsData({
    required String userId,
    required String role,
    String? fullName,
    String? username,
    String? profileImageURL,
  }) async {
    try {
      debugPrint('Updating connections for user $userId with role $role');
      // Add 's' to role as per collection naming convention
      final collectionRole = '${role}';

      // Get all connections for this user
      final connectionsSnapshot = await _firestore
          .collection('connections')
          .doc(collectionRole)
          .collection(userId)
          .get();

      // Prepare batch write
      final batch = _firestore.batch();

      // Update each connection document
      for (var connection in connectionsSnapshot.docs) {
        final connectedUserId = connection.id;
        final connectedUserRole = connection.data()['role'];

        // Add 's' to connected user's role
        //final connectedCollectionRole = '${connectedUserRole}';
        //debugPrint('Connected user role: $connectedUserRole, Collection role: $connectedCollectionRole');

        // First check if the document exists
        final connectionDoc = await _firestore
            .collection('connections')
            .doc(connectedUserRole)
            .collection(connectedUserId)
            .doc(userId)
            .get();

        if (!connectionDoc.exists) {
          debugPrint('Connection document not found for user $connectedUserId');
          continue; // Skip this iteration if document doesn't exist
        }

        // Reference to the connection document in the connected user's collection
        final connectionRef = _firestore
            .collection('connections')
            .doc(connectedUserRole)
            .collection(connectedUserId)
            .doc(userId);

        final updateDataFullName = connectedUserRole == 'client'
            ? 'professionalFullName'
            : 'clientFullName';
        final updateDataProfileImageUrl = connectedUserRole == 'client'
            ? 'professionalProfileImageUrl'
            : 'clientProfileImageUrl';

        // Prepare update data
        Map<String, dynamic> updateData = {};
        if (fullName != null) {
          updateData[updateDataFullName] =
              fullName.isNotEmpty ? fullName : username;
        }
        if (profileImageURL != null) {
          updateData[updateDataProfileImageUrl] = profileImageURL;
        }

        // Only update if there are changes and document exists
        if (updateData.isNotEmpty) {
          batch.update(connectionRef, updateData);
        }
      }

      // Only commit if there are operations in the batch
      if (connectionsSnapshot.docs.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error updating connections: $e');
      throw Exception('Failed to update connections data: $e');
    }
  }

  Future<void> createDocument(String collection, Map<String, dynamic> data) async {
    await _firestore.collection(collection).add(data);
  }

  Future<void> storeUserAuthData({
    required String userId,
    required String email,
    required DateTime createdAt,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'userId': userId,
        'authEmail': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isEmailVerified': false,
        'authProvider': 'email',
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error storing user auth data: $e');
      rethrow;
    }
  }

  Future<void> updateUserData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        ...data,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }

  String? getCurrentUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> deleteUserAccount(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');
      
      // Get user's email
      final email = user.email;
      if (email == null) throw Exception('No email associated with account');
      
      // Reauthenticate user before deletion
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Update user data in Firestore to mark as deleted
      await _firestore.collection('users').doc(user.uid).update({
        'accountStatus': 'deleted',
        'deletedAt': FieldValue.serverTimestamp(),
        'isActive': false,
      });
      
      // Delete the Firebase Auth user
      await user.delete();
      
    } catch (e) {
      debugPrint('Error deleting user account: $e');
      rethrow;
    }
  }
}
