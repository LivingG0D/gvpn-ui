# Power Route UI

Flutter ui for a gaming VPN network optimizer dashboard, complete with animated controls, fake telemetry, and a server picker.

## Features
- Dark themed dashboard inspired by the provided mockups
- Interactive power button with connection simulation and progress feedback
- Animated ping/loss/jitter cards that update with fake telemetry when connected
- Modal server selector with four preset locations and load indicators
- Rich connection and feature highlight cards that react to state

## Getting Started
1. Ensure Flutter (3.35+) is installed: `flutter --version`
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run on the desired device/emulator:
   ```bash
   flutter run
   ```

## Testing
```
flutter analyze
flutter test
```

## License
This project is distributed under the [Apache License 2.0](LICENSE). Feel free to adapt it for your own VPN/optimizer UI experiments. 
