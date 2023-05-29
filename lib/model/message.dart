/// write a [Message] class that has author, timestamp, and content, nullable recommendTags fields
class Message {
  final String author;
  final DateTime timestamp;
  final String content;

  Message(
    this.author,
    this.timestamp,
    this.content,
  );

  Message.fromBotMsg(String content, [List<String> recommendTags = const []])
      : this('bot', DateTime.now(), content);
}
