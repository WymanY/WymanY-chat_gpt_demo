// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:chat_gpt_demo/pages/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_gpt_demo/config/config.dart';
import 'package:chat_gpt_demo/model/chat_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigManager.init();
  return runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => ChatModel()),
  ], child: const ChatApp()));
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});
  @override
  Widget build(BuildContext context) {
    final scene = context.read<ChatModel>().chatScene;
    print(scene);
    return MaterialApp(
        home: Scaffold(
      drawer: Builder(builder: (context) {
        return Drawer(
          child: ListView(
            children: [
              ListTile(
                title: const Text('答题'),
                onTap: () {
                  context.read<ChatModel>().setChatScene(ChatScene.answer);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Text('学情分析'),
                onTap: () {
                  context.read<ChatModel>().setChatScene(ChatScene.learning);
                  Navigator.pop(context);
                },
              ),
            ],
            // 在这里添加抽屉中的小部件
          ),
        );
      }),
      body: ChatScreen(),
    ));
  }
}
