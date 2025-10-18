import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/chat_service.dart';
import '../constants.dart';
import '../widgets/custom_text.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();
  String? _currentUserEmail;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserEmail();
  }

  Future<void> _loadCurrentUserEmail() async {
    // Try Firebase Auth first, fallback to SharedPreferences
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser?.email != null) {
      setState(() {
        _currentUserEmail = firebaseUser!.email;
      });
    } else {
      // Fallback to SharedPreferences
      final userData = await userService.value.getUserData();
      setState(() {
        _currentUserEmail = userData['email']?.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomText(
          text: 'Chat',
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(8.sp),
            child: TextField(
              controller: _searchChatController,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchText.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchChatController.clear();
                          setState(() {
                            _searchText = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),
          SizedBox(height: 10.h),
          // Users Stream
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _chatService.getUsersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48.sp, color: Colors.red),
                      SizedBox(height: 16.h),
                      CustomText(
                        text: 'Error loading users',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 8.h),
                      CustomText(
                        text: 'Please check your internet connection',
                        fontSize: 12.sp,
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 48.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      CustomText(
                        text: 'No users found',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 8.h),
                      CustomText(
                        text: 'No other users are registered yet',
                        fontSize: 12.sp,
                      ),
                    ],
                  ),
                );
              }

              List<Map<String, dynamic>> users = snapshot.data!;

              // Filter out current user
              users = users.where((user) {
                final userEmail = user['email']?.toString() ?? '';
                return userEmail != _currentUserEmail;
              }).toList();

              // Filter by search text
              if (_searchText.isNotEmpty) {
                users = users.where((user) {
                  final name =
                      user['firstName']?.toString().toLowerCase() ?? '';
                  final email = user['email']?.toString().toLowerCase() ?? '';
                  final searchTextLower = _searchText.toLowerCase();
                  return name.contains(searchTextLower) ||
                      email.contains(searchTextLower);
                }).toList();
              }

              if (users.isEmpty) {
                return Container(
                  height: ScreenUtil().screenHeight * 0.6,
                  padding: EdgeInsets.all(16.sp),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off_outlined,
                        size: 48.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      CustomText(
                        text: 'No matching users found',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      SizedBox(height: 8.h),
                      CustomText(
                        text: 'Try adjusting your search or check back later.',
                        fontSize: 12.sp,
                      ),
                    ],
                  ),
                );
              }

              return Expanded(
                child: ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return GestureDetector(
                      onTap: () async {
                        // Get the correct Firebase Auth UID for the tapped user
                        final tappedUserEmail = user['email']?.toString();
                        String? tappedUserUid;

                        if (tappedUserEmail != null) {
                          tappedUserUid = await _chatService.getUidByEmail(
                            tappedUserEmail,
                          );
                        }

                        // Create updated user data with correct UID
                        final updatedUser = Map<String, dynamic>.from(user);
                        if (tappedUserUid != null) {
                          updatedUser['uid'] = tappedUserUid;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatDetailScreen(
                              currentUserEmail: _currentUserEmail!,
                              tappedUser: updatedUser,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 4.h),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: CustomText(
                              text:
                                  (user['firstName']?.toString().isNotEmpty ==
                                      true)
                                  ? user['firstName']
                                        .toString()
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : '?',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          title: CustomText(
                            text: user['firstName']?.toString() ?? 'Unknown',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          subtitle: CustomText(
                            text: user['email']?.toString() ?? 'No email',
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
