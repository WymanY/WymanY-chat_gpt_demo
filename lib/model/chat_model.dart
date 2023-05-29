import 'package:flutter/material.dart';

import 'message.dart';

enum ChatScene { answer, learning, breakIce }

class ChatModel extends ChangeNotifier {
  int msgIndex = 0;
  List<Message> messages = [
    Message('Bot', DateTime.now(), "你好，我是你的 AI 助手，有什么想要咨询的吗？")
  ];
  addMsg(Message msg) {
    messages.add(msg);
    notifyListeners();
  }

  void msgIndexIncrement() {
    msgIndex++;
    notifyListeners();
  }
}
