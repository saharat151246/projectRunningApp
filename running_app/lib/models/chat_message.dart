class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// แปลงเป็นรูปแบบที่ backend ต้องการสำหรับส่ง history: {role, text}
  Map<String, dynamic> toHistoryJson() => {
        'role': isUser ? 'user' : 'assistant',
        'text': text,
      };
}
