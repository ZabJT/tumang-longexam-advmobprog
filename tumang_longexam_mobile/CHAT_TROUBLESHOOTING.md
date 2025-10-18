# Chat Functionality Troubleshooting Guide

## Issue: Chat List Stuck in Loading State

### Possible Causes and Solutions:

### 1. **Firebase Connection Issues**

**Symptoms:** Loading spinner never stops, no error messages
**Solutions:**

- Check your internet connection
- Verify Firebase project is properly configured
- Ensure `google-services.json` is in the correct location (`android/app/`)
- Check Firebase console for any service outages

### 2. **No Users in Firestore Database**

**Symptoms:** Loading completes but shows "No users found"
**Solutions:**

- The app will automatically add test users if the Users collection is empty
- Check Firebase Console > Firestore Database > Users collection
- Manually add users with the following structure:
  ```json
  {
    "firstName": "User Name",
    "email": "user@example.com",
    "uid": "unique_user_id"
  }
  ```

### 3. **Firebase Authentication Issues**

**Symptoms:** Error messages about authentication
**Solutions:**

- Ensure user is logged in through your app's authentication system
- Check if Firebase Auth is properly initialized
- Verify user data is saved in SharedPreferences

### 4. **Firestore Security Rules**

**Symptoms:** Permission denied errors
**Solutions:**

- Check Firestore security rules in Firebase Console
- For development, you can use these permissive rules:
  ```javascript
  rules_version = '2';
  service cloud.firestore {
    match /databases/{database}/documents {
      match /{document=**} {
        allow read, write: if true;
      }
    }
  }
  ```

### 5. **Network/Firewall Issues**

**Symptoms:** Connection timeouts, network errors
**Solutions:**

- Check if your network allows Firebase connections
- Try on different network (mobile data vs WiFi)
- Check corporate firewall settings if applicable

## Debug Steps:

1. **Check Console Logs:**

   - Look for Firebase initialization messages
   - Check for any error messages in the console
   - Verify "Firebase connection test successful" message

2. **Test Firebase Connection:**

   - The app automatically tests Firebase connection on chat screen load
   - Check console for "Testing Firebase connection..." messages

3. **Verify User Data:**

   - Ensure current user has email and uid in SharedPreferences
   - Check if user is properly authenticated

4. **Check Firestore Data:**
   - Go to Firebase Console > Firestore Database
   - Look for "Users" collection
   - Verify data structure matches expected format

## Quick Fixes:

### Add Test Users Manually:

If the automatic test user creation doesn't work, you can manually add users in Firebase Console:

1. Go to Firebase Console
2. Navigate to Firestore Database
3. Create a collection called "Users"
4. Add documents with these fields:
   - `firstName` (string)
   - `email` (string)
   - `uid` (string)

### Reset Firebase Connection:

1. Clear app data/cache
2. Restart the app
3. Login again
4. Navigate to Chat tab

## Expected Behavior:

1. **First Load:** May take a few seconds to connect to Firebase
2. **Empty Database:** Will show "No users found" with helpful message
3. **With Users:** Will display list of users (excluding current user)
4. **Search:** Should filter users in real-time
5. **Chat:** Tap user to open chat detail screen

## Contact Support:

If issues persist, check:

- Firebase project configuration
- Network connectivity
- App permissions
- Firebase service status
