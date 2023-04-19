// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:bruno/bruno.dart';
import 'package:chat_gpt_demo/model/message.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:chat_gpt_demo/config/config.dart';
import 'package:chat_gpt_demo/model/chatModel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigManager.init();
  return runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ChatModel()),
  ], child: const ChatApp()));
}

//enum Chat Scene

class ChatApp extends StatefulWidget {
  const ChatApp({super.key});
  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      drawer: Builder(builder: (context) {
        return Drawer(
          child: ListView(
            children: [
              ListTile(
                title: const Text('答题'),
                onTap: () {
                  // Update the state of the app
                  // Then close the drawer
                  context.read<ChatModel>().setChatScene(ChatScene.Answer);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('学情分析'),
                onTap: () {
                  // Update the state of the app
                  // ...
                  // Then close the drawer
                  context.read<ChatModel>().setChatScene(ChatScene.Learning);
                  Navigator.pop(context);
                },
              ),
            ],
            // 在这里添加抽屉中的小部件
          ),
        );
      }),
      body: const ChatScreen(),
    ));
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    Key? key,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
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
    ChatModel model = context.read<ChatModel>();
    model.addMsg(Message('user', DateTime.now(), message));
    String botMessage = '';
    final chatScene = model.chatScene;
    var tags = ["A", "B", "C", "D"];
    switch (chatScene) {
      case ChatScene.breakIce:
        break;
      case ChatScene.Answer:
        if (model.msgIndex > model.answerMsgs.length - 1) {
          botMessage = await getBotResponse(message, ctx);
          final botPrompt =
              '$botMessage,将上面这段文字给我提炼几个推荐关键字,格式要求如下: 1.xxx\n2.xxxx,\n3.xxxx';
          final recommendTags = await getBotResponse(botPrompt, ctx);
          tags = recommendTags.split('\n');
        } else {
          botMessage = model.answerMsgs[model.msgIndex];
          model.msgIndexIncrement();
          if (model.msgIndex == model.answerMsgs.length - 1) {
            tags = [];
          }
        }

        break;
      case ChatScene.Learning:
        if (model.msgIndex > model.learnMsgs.length - 1) {
          botMessage = await getBotResponse(message, ctx);
          final botPrompt =
              '$botMessage,将上面这段文字给我提炼几个推荐关键字,格式要求如下: 1.xxx\n2.xxxx,\n3.xxxx';
          final recommendTags = await getBotResponse(botPrompt, ctx);
          tags = recommendTags.split('\n');
        } else {
          botMessage = model.learnMsgs[model.msgIndex];
          model.msgIndexIncrement();
          if (model.msgIndex == model.learnMsgs.length - 1) {
            tags = [];
          }
        }
        break;
    }
    model.addMsg(Message('bot', DateTime.now(), botMessage.trim(), tags));
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
    final chatModel = Provider.of<ChatModel>(context);
    print("chatModel.chatScene: ${chatModel.chatScene}");
    return Stack(children: [
      Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
              fit: BoxFit.cover,
            ),
          )),
      Column(
        children: [
          SafeArea(
            child: SizedBox(
              height: 50,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned(
                    left: 20,
                    child: GestureDetector(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: Image.asset('assets/images/head_session.png'),
                      ),
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Center(
                    child: CircleAvatar(
                      child: Image.asset('assets/images/avatar.png'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            // 添加一个 separate line for ListView
            child: ListView.separated(
              itemCount: chatModel.messages.length,
              itemBuilder: (BuildContext context, int index) {
                // show an avatar for the user and the bot
                // Use Icons.person for the user and Icons.android for the bot
                return Column(
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            chatModel.messages[index].author == 'user'
                                ? Colors.blue
                                : Colors.green,
                        child: Icon(
                          chatModel.messages[index].author == 'user'
                              ? Icons.person
                              : Icons.android,
                          color: Colors.white,
                        ),
                      ),
                      title: BrnBubbleText(
                        text: chatModel.messages[index].content,
                      ),
                      subtitle: Text(_formatTimestamp(
                          chatModel.messages[index].timestamp)),
                    ),
                    // when message is from the bot, show the buttons
                    if (chatModel.messages[index].author == 'bot' &&
                        chatModel.messages[index].recommendTags.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Builder(builder: (context) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: BrnSelectTag(
                                tags: chatModel.messages[index].recommendTags,
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
                                      chatModel.messages[index]
                                          .recommendTags[selectedIndexes[0]],
                                      context);
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
                      onSubmitted: (String value) =>
                          _sendMessage(value, context),
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
      ),
      Positioned(
        bottom: 60,
        right: 40,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Image.asset(
            'assets/images/loading.webp',
            fit: BoxFit.cover,
          ),
        ),
      ),
    ]);
  }
}
