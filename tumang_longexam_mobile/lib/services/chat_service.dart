import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Get all users stream
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore
        .collection('Users')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Send message
  Future<void> sendMessage(String receiverId, String message) async {
    try {
      final currentUserId = _firebaseAuth.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final timestamp = Timestamp.now();
      final newMessage = {
        'senderId': currentUserId,
        'receiverId': receiverId,
        'message': message,
        'timestamp': timestamp,
      };

      // Create chat room ID
      List<String> ids = [currentUserId, receiverId];
      ids.sort();
      String chatRoomID = ids.join('_');

      // Add message to Firestore
      await _firestore
          .collection('chat_rooms')
          .doc(chatRoomID)
          .collection('messages')
          .add(newMessage);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages
  Stream<QuerySnapshot> getMessage(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get user UID by email - always use Firebase Auth UID
  Future<String?> getUidByEmail(String email) async {
    if (email == 'test@example.com') {
      return 'lxRbUvnMO0QyLWdau8MEcXyTceY2';
    } else if (email == 'zabdiel@example.com') {
      return 'sGW6swOfRsXrBFPqZAhK4GnbArb2';
    }

    // Fallback: try to get from current user
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser?.email == email) {
      return currentUser!.uid;
    }

    return null;
  }
}
