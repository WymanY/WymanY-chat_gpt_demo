import 'package:chat_gpt_demo/config/config.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigManager.init();
  return runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chat Bot',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('知学伴'),
        ),
        body: const ChatScreen(),
      ),
    );
  }
}

// write a [Message] class that has author, timestamp, and content fields
class Message {
  final String author;
  final DateTime timestamp;
  final String content;

  Message(this.author, this.timestamp, this.content);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  final List<Message> _messages = [];

  Future<String> getBotResponse(String message, BuildContext context) async {
    final apiToken = ConfigManager.instance.apiToken;
    debugPrint('apiToken: ${apiToken}');

    var url = Uri.parse('https://api.openai.com/v1/chat/completions');
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json;charset=UTF-8',
        "Accept": "application/json; charset=utf-8",
        'Authorization': 'Bearer $apiToken',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {'role': 'user', 'content': message}
        ],
      }),
    );
    if (response.statusCode == 200) {
      // var data = jsonDecode(response.body);
      var data = jsonDecode(utf8.decode(response.bodyBytes));
      var botMessage = data['choices'][0]['message']['content'];
      return botMessage;
    } else if (response.statusCode == 429 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Too many requests, please try again later.'),
            duration: Duration(seconds: 2)),
      );
      return '';
    } else {
      throw Exception('Failed to get bot response.');
    }
  }

  void _sendMessage(String message, BuildContext ctx) async {
    if (message.isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(Message('user', DateTime.now(), message));
    });

    String botMessage = await getBotResponse(message, ctx);

    setState(() {
      _messages.add(Message('bot', DateTime.now(), botMessage.trim()));
    });
  }

  // convert the timestamp to a human readable format, eg."2 minutes ago"
  String _formatTimestamp(DateTime timestamp) {
    var now = DateTime.now();
    var difference = now.difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          // 添加一个 separate line for ListView
          child: ListView.separated(
            itemCount: _messages.length,
            itemBuilder: (BuildContext context, int index) {
              // show an avatar for the user and the bot
              // Use Icons.person for the user and Icons.android for the bot
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: _messages[index].author == 'user'
                      ? Colors.blue
                      : Colors.green,
                  child: Icon(
                    _messages[index].author == 'user'
                        ? Icons.person
                        : Icons.android,
                    color: Colors.white,
                  ),
                ),
                title: SelectableText(_messages[index].content),
                subtitle: Text(_formatTimestamp(_messages[index].timestamp)),
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return Divider(
                // when index odd is green color, even is blue color
                color: index % 2 == 0 ? Colors.blue : Colors.green,
                thickness: 1.0, // 分隔线的厚度
                height: 1.0, // 分隔线的高度
              );
            },
          ),
        ),
        const Divider(),
        SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: TextField(
                    minLines: 1,
                    maxLines: 5,
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '请输入您的疑问?',
                    ),
                    onSubmitted: (String value) => _sendMessage(value, context),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _sendMessage(_controller.text, context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
