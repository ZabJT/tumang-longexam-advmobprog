# 🔥 Add Your Real Users Right Now!

## 🎯 **The Problem:**

Your users (`test@example.com` and `zabdiel@example.com`) exist in Firebase Authentication but NOT in Firestore Database. The chat app looks for users in Firestore, so it can't find them.

## ✅ **Quick Solution - Add Users to Firestore:**

### **Step 1: Go to Firebase Console**

1. Visit [https://console.firebase.google.com/](https://console.firebase.google.com/)
2. Select your project: `advmobprog-firebase-4ad86`

### **Step 2: Enable Firestore (If Not Already Enabled)**

1. Click "Firestore Database" in the left sidebar
2. If you see "Create database", click it
3. Choose "Start in test mode"
4. Select a location (choose closest to you)
5. Click "Done"

### **Step 3: Add Your Real Users**

1. Click "Data" tab in Firestore Database
2. Click "Start collection"
3. Collection ID: `Users` (exactly like this, case-sensitive)
4. Click "Next"

### **Step 4: Add First User (test@example.com)**

1. Document ID: Auto-generate
2. Add these fields:
   - **Field name:** `firstName`, **Type:** string, **Value:** `test`
   - **Field name:** `email`, **Type:** string, **Value:** `test@example.com`
   - **Field name:** `uid`, **Type:** string, **Value:** `lxRbUvnMO0QyLWdau8MEcXy` (from your Auth screenshot)
   - **Field name:** `createdAt`, **Type:** timestamp, **Value:** (click "Set" to use current time)
3. Click "Save"

### **Step 5: Add Second User (zabdiel@example.com)**

1. Click "Add document" (or the + button)
2. Document ID: Auto-generate
3. Add these fields:
   - **Field name:** `firstName`, **Type:** string, **Value:** `zabdiel`
   - **Field name:** `email`, **Type:** string, **Value:** `zabdiel@example.com`
   - **Field name:** `uid`, **Type:** string, **Value:** `sGW6swOfRsXrBFPqZAhK4G` (from your Auth screenshot)
   - **Field name:** `createdAt`, **Type:** timestamp, **Value:** (click "Set" to use current time)
4. Click "Save"

### **Step 6: Set Security Rules**

1. Click "Rules" tab in Firestore Database
2. Replace the rules with:

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

3. Click "Publish"

### **Step 7: Switch App to Use Real Data**

Once you've added the users to Firestore, change this file:

**File:** `tumang_longexam_mobile/lib/screens/chat_list_screen.dart`

**Find this line:**

```dart
Stream<List<Map<String, dynamic>>> _getUsersStreamWithFallback() {
  // Since Firebase is having connection issues, use mock data immediately
  // This ensures users are always shown
  print('Using mock data due to Firebase connection issues');
  return _chatService.getMockUsersStream();
}
```

**Replace with:**

```dart
Stream<List<Map<String, dynamic>>> _getUsersStreamWithFallback() {
  // Try Firebase first to get real users, fall back to mock data if it fails
  print('Attempting to get real users from Firebase...');
  return _chatService.getUsersStream().handleError((error) {
    print('Firebase failed, using mock data: $error');
    return _chatService.getMockUsersStream();
  });
}
```

## 🎯 **Expected Result:**

### **Before (Current):**

- Shows: John Doe, Jane Smith, Bob Johnson, Alice Brown (mock users)

### **After (Real Users):**

- Shows: test@example.com, zabdiel@example.com (your real users)
- Current user is filtered out (you won't see yourself)

## 🔍 **Troubleshooting:**

### **If you still see mock users:**

1. **Check Firestore has data** - Go to Data tab and verify you see 2 documents in Users collection
2. **Check security rules** - Make sure they allow read access
3. **Restart the app** - Hot reload might not pick up the changes
4. **Check console logs** - Look for "Attempting to get real users from Firebase..."

### **If you see "No users found":**

1. **Verify collection name** is exactly `Users` (case-sensitive)
2. **Check field names** are exactly `firstName`, `email`, `uid`, `createdAt`
3. **Make sure Firestore is enabled** in your Firebase project

## 🚀 **Why This Will Work:**

- Your users are already authenticated in Firebase Auth
- Adding them to Firestore makes them visible to the chat app
- The app will automatically filter out the current user
- You'll see the other user in your chat list

Follow these steps and you'll see your real users instead of the mock data! 🎉
