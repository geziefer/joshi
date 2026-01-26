# Space Runner (Flutter Web + Flame) – Starter

Enthält:

- Parallax-Background (3 Layer, seamless)
- Raumschiff links fixiert, Bewegung **nur hoch/runter** via Pfeiltasten
- Erste Asteroiden-Spawns (noch **ohne** Kollision/Schießen)

## Start (Web)

```bash
flutter pub get
flutter run -d chrome
```

## Steuerung

- Pfeil **hoch / runter**

## Hinweise

- Im Web braucht Keyboard-Input Fokus. Das Projekt setzt den Fokus automatisch (Focus/FocusNode).
- Wenn dein Schiff zu groß/klein wirkt: in `lib/space_game.dart` `shipSize` anpassen (z.B. 96..128).
