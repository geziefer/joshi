# Firebase Test-Anleitung

## 1. Einfacher Start-Test
```bash
flutter run
```
- App sollte ohne Fehler starten
- Keine Firebase-Fehlermeldungen in der Konsole

## 2. Firebase Connection Test
Füge temporär in main.dart nach Firebase.initializeApp() ein:
```dart
print('✅ Firebase erfolgreich initialisiert');
print('Project ID: ${Firebase.app().options.projectId}');
```

## 3. Realtime Database Test
Erstelle eine Test-Datei:
```dart
// lib/firebase_test.dart
import 'package:firebase_database/firebase_database.dart';

Future<void> testFirebaseConnection() async {
  try {
    final ref = FirebaseDatabase.instance.ref('test');
    await ref.set({'timestamp': DateTime.now().toString()});
    print('✅ Firebase Write erfolgreich');
    
    final snapshot = await ref.get();
    print('✅ Firebase Read erfolgreich: ${snapshot.value}');
  } catch (e) {
    print('❌ Firebase Fehler: $e');
  }
}
```

## 4. In der Firebase Console prüfen
1. Gehe zu: https://console.firebase.google.com
2. Wähle dein Projekt "brick-breaker-32771"
3. Realtime Database → Daten
4. Prüfe ob Einträge erscheinen

## 5. Highscore-Integration testen
- Spiele das Spiel
- Erreiche Game Over
- Prüfe ob Highscore gespeichert wird
- Schaue in Firebase Console ob Daten ankommen
