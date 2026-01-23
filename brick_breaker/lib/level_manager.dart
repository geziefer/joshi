import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';

class LevelManager {
  static final _database = FirebaseDatabase.instance.ref();

  static Future<void> uploadLevelsToFirebase() async {
    final jsonString = await rootBundle.loadString('assets/levels.json');
    final data = json.decode(jsonString);
    await _database.child('levels').set(data);
  }

  static Future<Map<String, dynamic>> loadLevelsFromFirebase() async {
    final snapshot = await _database.child('levels').get();
    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    throw Exception('Keine Levels in Firebase gefunden');
  }
}
