import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
// # flutter build web --release

void main() {
  print(const String.fromEnvironment("API_KEY"));
  Gemini.init(
    apiKey: const String.fromEnvironment('API_KEY'),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Chat',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<MessageGemini> messages = [];
  final gemini = Gemini.instance;
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  void _sendMessage(String message) {
    setState(() {
      messages.add(
        MessageGemini(
          message: message,
          isUser: true,
        ),
      );
      _textController.clear();
      _isLoading = true;
    });

    gemini.chat([
      Content(
        parts: [Parts(text: messages.last.message)],
        role: 'user',
      ),
    ]).then(
      (value) {
        setState(() {
          messages.add(MessageGemini(
            message: value?.output ?? "I cant understand you",
            isUser: false,
          ));
          _isLoading = false;
        });
      },
    ).catchError((e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Ok"))
          ],
          title: Text(
            e.toString(),
          ),
        ),
      );
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
// Pick an image.
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image?.path == null) return;
    setState(() {
      messages.add(MessageGemini(
        image: image,
        isUser: true,
      ));
      messages.add(MessageGemini(
        message: "Thingking about image...",
        isUser: false,
      ));
    });

    Uint8List imageFile = await image!.readAsBytes();
    gemini
        .textAndImage(text: "Mô tả bức tranh này", image: imageFile)
        .onError((error, stackTrace) {
      log("Error");
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Ok"))
          ],
          title: Text(
            error.toString(),
          ),
        ),
      );
    }).then((value) {
      log("Value");
      setState(() {
        messages.add(MessageGemini(
          message: value?.content?.parts?.last.text ?? "I cant understand you",
          isUser: false,
        ));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gemini Chat'),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                          "Start Chatting with Gemini by typing a message"),
                    )
                  : ListView.builder(
                      itemCount: messages.length + 1,
                      itemBuilder: (context, index) {
                        if (index == messages.length) {
                          if (_isLoading) {
                            return Container(
                              padding: const EdgeInsets.all(8),
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Text(
                                'Typing...',
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.start,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: messages[index].isUser
                                ? Colors.deepPurple[100]
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: !messages[index].isUser
                              ? Container(
                                  margin: const EdgeInsets.only(
                                    right: 100,
                                  ),
                                  child: MarkdownBody(
                                    data: messages[index].message!,
                                  ),
                                )
                              : messages[index].message == null
                                  ? Image.network(messages[index].image!.path)
                                  : Text(
                                      messages[index].message!,
                                      style: const TextStyle(
                                          color: Colors.deepPurple),
                                      textAlign: TextAlign.end,
                                    ),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    onPressed: () {
                      _pickImage();
                    },
                  ),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Send a message',
                      ),
                      onSubmitted: (value) {
                        _sendMessage(value);
                      },
                      controller: _textController,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      _sendMessage(_textController.text);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageGemini {
  final String? message;
  final bool isUser;
  XFile? image;

  MessageGemini({
    this.message,
    required this.isUser,
    this.image,
  });
}
