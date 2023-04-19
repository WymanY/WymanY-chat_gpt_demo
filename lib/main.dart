import 'package:bruno/bruno.dart';
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
        home: Scaffold(
      appBar: AppBar(
        title: const Text('知学伴'),
        leading: Builder(builder: (context) {
          return IconButton(
            icon: const Icon(Icons.chat_bubble), // 替换为Settings图标
            onPressed: () {
              // do something
              Scaffold.of(context).openDrawer();
            },
          );
        }),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('知学伴角色'),
            ),
            ListTile(
              title: const Text('心灵导师'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('考研规划师'),
              onTap: () {
                // Update the state of the app
                // ...
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
          // 在这里添加抽屉中的小部件
        ),
      ),
      body: const ChatScreen(),
    ));
  }
}

// write a [Message] class that has author, timestamp, and content, nullable recommendTags fields
class Message {
  final String author;
  final DateTime timestamp;
  final String content;
  final List<String> recommendTags;

  Message(this.author, this.timestamp, this.content,
      [this.recommendTags = const []]);
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  final List<Message> _messages = [];
  @override
  void initState() {
    super.initState();
    _messages.add(Message(
        'bot', DateTime.now(), '您好,我是你的学习伴侣,接下来我会跟你简单的沟通几个问题,感谢你的配合.', []));
  }

  Future<String> getBotResponse(String message, BuildContext context) async {
    final apiToken = ConfigManager.instance.apiToken;
    debugPrint('apiToken: $apiToken');

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
          {'role': 'assistant', 'content': message}
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
    final recommendPrompt = "根据下面这段话给出三个推荐关键词: $botMessage";
    // ignore: use_build_context_synchronously
    final String recommondMessage = await getBotResponse(recommendPrompt, ctx);
    print(recommondMessage);

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
              var tags2 = [
                '如何考研',
                '如何做英语专项练习',
                '还有三个月怎么考研',
                '我的现在成绩怎么样',
                '我要考研了,好担心，应该咋做啊',
              ];
              return Column(
                children: [
                  ListTile(
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
                    subtitle:
                        Text(_formatTimestamp(_messages[index].timestamp)),
                  ),
                  // when message is from the bot, show the buttons
                  if (_messages[index].author == 'bot')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Builder(builder: (context) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: BrnSelectTag(
                              tags: tags2,
                              isSingleSelect: true,
                              fixWidthMode: false,
                              spacing: 8.0,
                              themeData:
                                  //hex color 9c88ff
                                  BrnTagConfig(
                                      tagBackgroundColor:
                                          const Color(0xFF9c88ff),
                                      tagTextStyle: BrnTextStyle(
                                          color: const Color(0xFFFFF100),
                                          fontSize: 14.0,
                                          fontWeight: FontWeight.w500),
                                      tagRadius: 8.0),
                              onSelect: (selectedIndexes) {
                                _sendMessage(
                                    tags2[selectedIndexes[0]], context);
                              }),
                        );
                      }),
                    )
                ],
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
