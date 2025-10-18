# Firebase Setup Guide for Real Chat Functionality

## Current Status

The app is now configured to use **real Firebase data** instead of mock data. However, you need to set up Firebase properly to see real users and messages.

## Step 1: Enable Firestore Database

1. **Go to Firebase Console:**

   - Visit [https://console.firebase.google.com/](https://console.firebase.google.com/)
   - Select your project: `advmobprog-firebase-4ad86`

2. **Enable Firestore:**
   - In the left sidebar, click on "Firestore Database"
   - Click "Create database"
   - Choose "Start in test mode" (for development)
   - Select a location (choose the closest to your users)
   - Click "Done"

## Step 2: Set Up Security Rules

1. **Go to Firestore Rules:**
   - In Firestore Database, click on the "Rules" tab
   - Replace the default rules with these permissive rules for development:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow read/write access to all documents for development
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

2. **Click "Publish"** to save the rules

## Step 3: Add Real Users to Firestore

1. **Go to Firestore Database:**

   - Click on "Data" tab
   - Click "Start collection"
   - Collection ID: `Users`
   - Click "Next"

2. **Add User Documents:**

   - Document ID: `user1` (or auto-generate)
   - Add these fields:
     - `firstName` (string): "John"
     - `email` (string): "john@example.com"
     - `uid` (string): "firebase_auth_uid_here"
   - Click "Save"

3. **Add More Users:**
   - Repeat for other users (Jane, Bob, Alice, etc.)
   - Make sure each user has a unique `uid` field

## Step 4: Test the Connection

1. **Run the app** and navigate to the Chat tab
2. **Check the console logs** for these messages:

   - "Attempting to connect to Firestore for users..."
   - "Firestore snapshot received: X users"
   - "User data: {...}"

3. **Expected Behavior:**
   - If Firebase works: You'll see real users from Firestore
   - If Firebase fails: You'll see mock users as fallback

## Step 5: Enable Real Messaging

Once Firestore is working:

1. **Users will appear** in the chat list from your Firestore database
2. **Tap any user** to open chat detail screen
3. **Type a message** and send it
4. **Messages will be stored** in Firestore under `chat_rooms/{chatRoomId}/messages`

## Step 6: Add Authentication (Optional)

For production, you should add Firebase Authentication:

1. **Enable Authentication:**

   - In Firebase Console, go to "Authentication"
   - Click "Get started"
   - Go to "Sign-in method" tab
   - Enable "Email/Password"

2. **Update Security Rules:**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /Users/{userId} {
      allow read, write: if request.auth != null;
    }
    match /chat_rooms/{chatRoomId} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Troubleshooting

### If you still see mock data:

1. Check Firebase Console for any error messages
2. Verify Firestore is enabled and has data
3. Check the app console logs for connection errors
4. Ensure your internet connection is working

### If you see "No users found":

1. Add some users to the `Users` collection in Firestore
2. Make sure each user document has `firstName`, `email`, and `uid` fields

### If messages don't send:

1. Check Firestore security rules
2. Verify the `chat_rooms` collection is being created
3. Check console logs for error messages

## Expected Database Structure

```
Firestore Database:
├── Users/
│   ├── user1/
│   │   ├── firstName: "John"
│   │   ├── email: "john@example.com"
│   │   └── uid: "firebase_auth_uid"
│   └── user2/
│       ├── firstName: "Jane"
│       ├── email: "jane@example.com"
│       └── uid: "firebase_auth_uid"
└── chat_rooms/
    └── {chatRoomId}/
        └── messages/
            ├── message1/
            │   ├── senderId: "user1"
            │   ├── receiverId: "user2"
            │   ├── message: "Hello!"
            │   └── timestamp: Timestamp
            └── message2/
                ├── senderId: "user2"
                ├── receiverId: "user1"
                ├── message: "Hi there!"
                └── timestamp: Timestamp
```

## Next Steps

1. **Set up Firestore** following the steps above
2. **Add real users** to the database
3. **Test the chat functionality** with real data
4. **Share the app** with other users to test messaging
5. **Monitor the console logs** to ensure everything is working

The app will automatically switch from mock data to real Firebase data once the connection is established!
