import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final _firebaseMessaging = FirebaseMessaging.instance;

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
}
