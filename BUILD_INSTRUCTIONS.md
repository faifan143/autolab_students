# AutoLab Students Flutter App - Build Instructions

## Prerequisites
- Flutter SDK installed
- Network connectivity (for downloading dependencies)

## Setup Steps

1. **Install Dependencies**
   ```bash
   flutter pub get
   ```

2. **Generate JSON Serialization Code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```
   This will generate `.g.dart` files for all models in `lib/models/`.

3. **Run the App**
   ```bash
   flutter run
   ```

## Project Structure

- `lib/models/` - Data models with JSON serialization
- `lib/services/` - API services (Dio-based)
- `lib/providers/` - ChangeNotifier providers for state management
- `lib/screens/` - All UI screens
- `lib/controllers/` - GetX controllers (theme, locale)
- `lib/routes/` - Navigation routing
- `lib/localization/` - Translation files (en, ar)
- `lib/widgets/` - Reusable widgets (IP config dialog)
- `lib/constants/` - API endpoints and constants

## Features Implemented

✅ Authentication (login/register)
✅ Dynamic server IP configuration
✅ Labs management
✅ Sessions viewing
✅ Attendance with QR scanner
✅ Grades viewing
✅ Files viewing and opening
✅ Real-time chat (socket.io)
✅ Streaming viewer scaffold (ready for WebRTC)
✅ Settings (theme, language, logout)
✅ Full localization (English/Arabic)

## Notes

- The app uses **GetX** for theme and localization only
- **Provider + ChangeNotifier** for all business logic
- **Dio** with automatic token refresh and 401 handling
- Server IP can be configured via FAB on login screen
- All screens use `.tr` for translations

## Network Issues

If you encounter network errors (like the Gradle/Google Maven issue), ensure:
- Internet connectivity is available
- Firewall/proxy settings allow access to:
  - `pub.dev`
  - `dl.google.com` (for Android dependencies)
  - Your backend server IP

