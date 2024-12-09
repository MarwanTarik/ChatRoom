class Message {
  String? userId;
  String text;
  String? messageId;
  DateTime timestamp = DateTime.now();
  String channel;

  Message(this.userId, this.messageId, this.timestamp, this.text, this.channel);
}