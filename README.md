# ⚡ SwiftShare

Fast cross-platform file sharing — Android ↔ Android, Android ↔ Windows.

## Transfer Modes

| Mode | Speed | Range | Notes |
|------|-------|-------|-------|
| WiFi LAN | ~40 MB/s | Same network | Recommended |
| Nearby / WiFi Direct | ~10 MB/s | ~100m | No router needed |
| Bluetooth | ~3 MB/s | ~10m | Fallback |
| USB / wired LAN | ~100 MB/s | Direct | Same as WiFi LAN over USB tethering |

## How to Use (WiFi)

1. Open app on both devices (or PC)
2. On **Receiver**: tap "Receive" → "Start Receiving" → note the IP shown
3. On **Sender**: tap "Send" → enter receiver's IP → pick files → Send

> USB mode: enable USB tethering on Android → use the USB IP shown on the receiver screen

## Build Locally

```bash
flutter pub get
flutter build apk --release          # Android
flutter build windows --release      # Windows
```

## Build via GitHub Actions

Push to `main` → Actions tab → download artifacts.

To create a release:
```bash
git tag v1.0.0
git push origin v1.0.0
```

## Project Structure

```
lib/
  main.dart
  router.dart
  models/
    transfer_item.dart
  screens/
    home_screen.dart
    send_screen.dart
    receive_screen.dart
    transfers_screen.dart
    settings_screen.dart
  services/
    wifi_transfer_service.dart   # HTTP server/client + parallel chunks
    nearby_service.dart          # WiFi Direct + BLE
    transfer_provider.dart       # Riverpod state
  widgets/
    transfer_card.dart
.github/workflows/build.yml      # CI/CD
```

## Windows Firewall

Allow port `54321` inbound:
```powershell
netsh advfirewall firewall add rule name="SwiftShare" dir=in action=allow protocol=TCP localport=54321
```
