import 'dart:convert';

import 'package:bruno/bruno.dart';
import 'package:chat_gpt_demo/r.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/config.dart';
import '../model/chat_model.dart';
import '../model/message.dart';

class ChatScreen extends StatelessWidget {
  final _controller = TextEditingController();

  ChatScreen({super.key});

  get http => null;
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
    } else if (response.statusCode == 429 && context.mounted) {
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
    ChatModel model = ctx.read<ChatModel>();
    model.addMsg(Message('user', DateTime.now(), message));
    String botMessage = '';
    final chatScene = model.chatScene;
    var tags = ["A", "B", "C", "D"];
    switch (chatScene) {
      case ChatScene.breakIce:
        break;
      case ChatScene.answer:
        if (model.msgIndex > model.answerMsgs.length - 1) {
          if (!ctx.mounted) return;
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
      case ChatScene.learning:
        if (model.msgIndex > model.learnMsgs.length - 1 && ctx.mounted) {
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
    return Stack(children: [
      Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(R.assetsImgBg),
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
                        child: Image.asset(R.assetsImgHeadSession),
                      ),
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                  Center(
                    child: CircleAvatar(
                      child: Image.asset(R.assetsImgAvatar),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            // 添加一个 separate line for ListView
            child: Consumer<ChatModel>(builder: (context, chatModel, child) {
              return ListView.separated(
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
              );
            }),
          ),
          const Divider(),
          Builder(builder: (context) {
            return SafeArea(
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
            );
          }),
        ],
      ),
      Positioned(
        bottom: 60,
        right: 40,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Image.asset(
            R.assetsImgLoading,
            fit: BoxFit.cover,
          ),
        ),
      ),
    ]);
  }
}
