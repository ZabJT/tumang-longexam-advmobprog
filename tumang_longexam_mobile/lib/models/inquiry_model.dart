class Inquiry {
  final String inquiryId;
  final String itemId;
  final String itemName;
  final String itemPhotoUrl;
  final String userId;
  final String userName;
  final String message; // User's inquiry message
  final String adminReply; // Admin's reply message
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? repliedAt;
  final bool isRead;
  final bool isReadByAdmin;

  Inquiry({
    this.inquiryId = '',
    required this.itemId,
    required this.itemName,
    required this.itemPhotoUrl,
    required this.userId,
    required this.userName,
    required this.message,
    this.adminReply = '',
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
    this.repliedAt,
    this.isRead = false,
    this.isReadByAdmin = false,
  });

  factory Inquiry.fromJson(Map<String, dynamic> json) {
    return Inquiry(
      inquiryId: json['_id']?.toString() ?? '',
      itemId: json['itemId']?.toString() ?? '',
      itemName: json['itemName']?.toString() ?? '',
      itemPhotoUrl: json['itemPhotoUrl']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      userName: json['userName']?.toString() ?? '',
      message:
          json['userMessage']?.toString() ?? json['message']?.toString() ?? '',
      adminReply: json['adminReply']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      repliedAt: json['repliedAt'] != null
          ? DateTime.tryParse(json['repliedAt'].toString())
          : null,
      isRead: json['isRead'] == true,
      isReadByAdmin: json['isReadByAdmin'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemPhotoUrl': itemPhotoUrl,
      'userId': userId,
      'userName': userName,
      'userMessage': message,
      'adminReply': adminReply,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'repliedAt': repliedAt?.toIso8601String(),
      'isRead': isRead,
      'isReadByAdmin': isReadByAdmin,
    };
  }

  Inquiry copyWith({
    String? inquiryId,
    String? itemId,
    String? itemName,
    String? itemPhotoUrl,
    String? userId,
    String? userName,
    String? message,
    String? adminReply,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? repliedAt,
    bool? isRead,
    bool? isReadByAdmin,
  }) {
    return Inquiry(
      inquiryId: inquiryId ?? this.inquiryId,
      itemId: itemId ?? this.itemId,
      itemName: itemName ?? this.itemName,
      itemPhotoUrl: itemPhotoUrl ?? this.itemPhotoUrl,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      message: message ?? this.message,
      adminReply: adminReply ?? this.adminReply,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      repliedAt: repliedAt ?? this.repliedAt,
      isRead: isRead ?? this.isRead,
      isReadByAdmin: isReadByAdmin ?? this.isReadByAdmin,
    );
  }
}
