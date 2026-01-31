import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDu91gsy60LFajTQOIOcYAvaVjLJGJWmik",
      authDomain: "brick-breaker-32771.firebaseapp.com",
      databaseURL: "https://brick-breaker-32771-default-rtdb.europe-west1.firebasedatabase.app",
      projectId: "brick-breaker-32771",
      storageBucket: "brick-breaker-32771.firebasestorage.app",
      messagingSenderId: "223791541084",
      appId: "1:223791541084:web:b7ff83daf05e4cf4a62f99",
    ),
  );
  
  final db = FirebaseDatabase.instance.ref();
  final snapshot = await db.child('brick_breaker_highscores').get();
  
  print('Exists: ${snapshot.exists}');
  print('Value: ${snapshot.value}');
}
