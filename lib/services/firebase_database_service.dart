import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:rizz_mobile/models/user.dart';

class FirebaseDatabaseService {
  final _db = FirebaseFirestore.instance;

  Future<User?> getUserById(String id) async {
    final docSnap = await _db
        .collection('users')
        .doc(id)
        .withConverter(
          fromFirestore: User.fromFirestore,
          toFirestore: (User user, options) => user.toFirestore(),
        )
        .get();
    return docSnap.data();
  }

  Future<Map<String, dynamic>> loginWithGoogle(String email) async {
    final querySnapshot = await _db
        .collection('users')
        .withConverter(
          fromFirestore: User.fromFirestore,
          toFirestore: (User user, options) => user.toFirestore(),
        )
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      final newUser = User(email: email, isCompleteSetup: false);
      final ref = await _db
          .collection('users')
          .withConverter(
            fromFirestore: User.fromFirestore,
            toFirestore: (User user, options) => user.toFirestore(),
          )
          .add(newUser);
      final docSnap = await ref.get();
      debugPrint('New User: ${docSnap.data()?.email}');
      await _db.collection('users').doc(docSnap.id).update({'id': docSnap.id});
      return {'user': docSnap.data()!, 'id': docSnap.id};
    }

    final existedUser = querySnapshot.docs.first;
    debugPrint('Existed User: ${existedUser.data().email}');
    return {'user': existedUser.data(), 'id': existedUser.id};
  }

  Future<void> updateUser(String id, User user) async {
    await _db.collection('users').doc(id).update(user.toFirestore());
    debugPrint('Updated User: ${user.email}');
  }
}
