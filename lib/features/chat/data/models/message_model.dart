class MessageModel {
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final bool isSeen;
  final List<String>? options; // 선택 가능한 옵션들 (예: 피부 타입)

  MessageModel({
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.isSeen = false,
    this.options,
  });

  MessageModel copyWith({
    bool? isSeen,
    List<String>? options,
  }) {
    return MessageModel(
      senderId: senderId,
      text: text,
      timestamp: timestamp,
      isMe: isMe,
      isSeen: isSeen ?? this.isSeen,
      options: options ?? this.options,
    );
  }
}