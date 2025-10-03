import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _storage = FirebaseStorage.instance;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  Future<String?> requestPushToken() async {
    await _firebaseMessaging.requestPermission();

    final token = await _firebaseMessaging.getToken();
    debugPrint('The device token: [$token]');

    return token;
  }

  Future<String?> uploadFile(File file, String fileName) async {
    try {
      final storageRef = _storage.ref();
      final fileRef = storageRef.child(fileName);
      await fileRef.putFile(file);
      final url = await fileRef.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }
}
