# FCM Notification Implementation - AutoLab Students App

## ✅ Implementation Complete

All FCM notification handling features have been successfully implemented.

---

## 1. FCM Token Registration

### Implementation
- **Endpoint Added:** `POST /students/fcm-token` in `ApiEndpoints`
- **Service Method:** `FirebaseNotificationsService.registerFCMToken(String token)`
- **Auto-Registration:** 
  - After successful login (`AuthProvider.login()`)
  - After successful registration (`AuthProvider.register()`)
  - On token refresh (automatic via `onTokenRefresh` listener)

### Code Location
- `lib/constants/api_endpoints.dart` (line 42)
- `lib/services/firebase_notifications_service.dart` (lines 217-228)
- `lib/providers/auth_provider.dart` (lines 113-121, 139-147)

### How It Works
1. User logs in or registers
2. FCM token is obtained via `FirebaseMessaging.getToken()`
3. Token is automatically sent to backend via `POST /students/fcm-token`
4. Token is updated whenever Firebase refreshes it

---

## 2. Notification Types & Handling

### Supported Notification Types

#### ✅ `LAB_ENROLLMENT`
- **Navigation:** Labs screen (`AppRoutes.labs`)
- **Action:** Shows success SnackBar message
- **Payload Expected:**
  ```json
  {
    "type": "LAB_ENROLLMENT",
    "labId": "optional-lab-id"
  }
  ```

#### ✅ `SESSION_STARTED`
- **Navigation:** Sessions screen (`AppRoutes.sessions`) with `labId` argument
- **Action:** Shows notification SnackBar
- **Payload Expected:**
  ```json
  {
    "type": "SESSION_STARTED",
    "labId": "lab-id-here",
    "sessionId": "optional-session-id"
  }
  ```

#### ✅ `SESSION_ENDED`
- **Navigation:** Sessions screen (`AppRoutes.sessions`) with `labId` argument
- **Action:** Shows notification SnackBar
- **Payload Expected:**
  ```json
  {
    "type": "SESSION_ENDED",
    "labId": "lab-id-here"
  }
  ```

#### ✅ `NEW_CHAT_MESSAGE` (NEW)
- **Navigation:** Chat screen (`AppRoutes.chat`) with `labId` argument
- **Action:** Shows message preview SnackBar with sender name and content
- **Payload Expected:**
  ```json
  {
    "type": "NEW_CHAT_MESSAGE",
    "labId": "lab-id-here",
    "senderName": "Teacher Name",
    "message": "Message content"
  }
  ```

---

## 3. Notification Handling States

### ✅ Foreground (App Open)
- **Handler:** `_handleForegroundMessage()`
- **Behavior:**
  - Shows local notification via `flutter_local_notifications`
  - Immediately navigates to appropriate screen
  - Displays SnackBar with relevant message

### ✅ Background (App Minimized)
- **Handler:** `_handleNotificationTap()` via `FirebaseMessaging.onMessageOpenedApp`
- **Behavior:**
  - User taps notification
  - App opens and navigates to appropriate screen
  - Shows SnackBar with relevant message

### ✅ Terminated (App Closed)
- **Handler:** `_firebaseMessagingBackgroundHandler()` (top-level function)
- **Behavior:**
  - Shows local notification
  - When user taps notification, app opens and navigates
  - Handles navigation via `_onNotificationTapped()`

---

## 4. Local Notifications

### Implementation
- Uses `flutter_local_notifications` package
- Android notification channel: `autolab_students_channel`
- High importance and priority for all notifications
- Payload includes notification data for navigation

### Code Location
- `lib/services/firebase_notifications_service.dart` (lines 98-126)

---

## 5. Navigation Logic

### Implementation Details
- Uses `AppRoutes.navigatorKey` for programmatic navigation
- Handles navigation based on `type` field in notification `data`
- Supports navigation arguments (e.g., `labId` for sessions/chat)
- Falls back to home screen for unknown notification types

### Code Location
- `lib/services/firebase_notifications_service.dart` (lines 147-216)

---

## 6. Translations Added

### English (`lib/localization/en.dart`)
- `lab_enrollment_notification`: "You have been successfully enrolled in the lab"
- `session_started`: "Session Started"
- `session_started_notification`: "A lab session has started"
- `session_ended`: "Session Ended"
- `session_ended_notification`: "A lab session has ended"
- `new_message`: "New Message"

### Arabic (`lib/localization/ar.dart`)
- `lab_enrollment_notification`: "تم تسجيلك بنجاح في المعمل"
- `session_started`: "بدأت الجلسة"
- `session_started_notification`: "بدأت جلسة معمل"
- `session_ended`: "انتهت الجلسة"
- `session_ended_notification`: "انتهت جلسة معمل"
- `new_message`: "رسالة جديدة"

---

## 7. Backend Integration Requirements

### FCM Token Registration Endpoint
**Endpoint:** `POST /students/fcm-token`

**Request:**
```json
{
  "fcmToken": "firebase-fcm-token-string"
}
```

**Headers:**
```
Authorization: Bearer {accessToken}
Content-Type: application/json
```

**Response:**
- `200 OK` or `201 Created` on success
- Store token linked to student ID in database
- Update token if student already has one registered

### Notification Payload Format

Backend should send FCM notifications with this structure:

```json
{
  "notification": {
    "title": "Session Started",
    "body": "Lab session has begun"
  },
  "data": {
    "type": "SESSION_STARTED",
    "labId": "lab-123",
    "sessionId": "session-456"
  }
}
```

**Required `data.type` values:**
- `LAB_ENROLLMENT`
- `SESSION_STARTED`
- `SESSION_ENDED`
- `NEW_CHAT_MESSAGE`

**Optional `data` fields:**
- `labId` - Required for `SESSION_STARTED`, `SESSION_ENDED`, `NEW_CHAT_MESSAGE`
- `sessionId` - Optional for `SESSION_STARTED`
- `senderName` - Required for `NEW_CHAT_MESSAGE`
- `message` - Required for `NEW_CHAT_MESSAGE`

---

## 8. Testing Checklist

### FCM Token Registration
- [ ] Login → Verify token sent to backend
- [ ] Register → Verify token sent to backend
- [ ] Token refresh → Verify updated token sent to backend
- [ ] Check backend logs for token registration

### Notification Handling
- [ ] `LAB_ENROLLMENT` → Navigate to Labs, show success message
- [ ] `SESSION_STARTED` → Navigate to Sessions, show notification
- [ ] `SESSION_ENDED` → Navigate to Sessions, show notification
- [ ] `NEW_CHAT_MESSAGE` → Navigate to Chat, show message preview

### App States
- [ ] Foreground notification → Shows notification + navigates
- [ ] Background notification → Tap opens app + navigates
- [ ] Terminated notification → Tap opens app + navigates

### Edge Cases
- [ ] Missing `labId` → Falls back gracefully
- [ ] Unknown notification type → Navigates to home
- [ ] Invalid payload → Handles error gracefully
- [ ] Network failure during token registration → App continues normally

---

## 9. Files Modified

1. **`lib/constants/api_endpoints.dart`**
   - Added `fcmToken` endpoint constant

2. **`lib/services/firebase_notifications_service.dart`**
   - Implemented `registerFCMToken()` method
   - Enhanced `_handleNotificationNavigation()` with all notification types
   - Added `NEW_CHAT_MESSAGE` handling
   - Improved foreground message handling
   - Enhanced background message handler

3. **`lib/providers/auth_provider.dart`**
   - Added FCM token registration after login
   - Added FCM token registration after register

4. **`lib/localization/en.dart`**
   - Added notification message translations

5. **`lib/localization/ar.dart`**
   - Added notification message translations (Arabic)

---

## 10. Summary

### ✅ Completed Features
- FCM token registration (automatic after login/register)
- Token refresh handling
- All 4 notification types handled (`LAB_ENROLLMENT`, `SESSION_STARTED`, `SESSION_ENDED`, `NEW_CHAT_MESSAGE`)
- Foreground, background, and terminated state handling
- Local notifications display
- Navigation with proper arguments
- Success/notification messages via SnackBar
- Bilingual support (English & Arabic)

### 🎯 Ready for Production
All FCM notification features are fully implemented and ready for testing with your backend.

---

**Status:** ✅ **COMPLETE - Ready for Backend Integration & Testing**

