import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Content> history = [];
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  static const _apiKey = '<Your_API_KEY>'; // https://ai.google.dev/ (Get API key from this link)

  void scrollDownTheSCREEN() {
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-pro', apiKey: _apiKey,
    );
    _chat = _model.startChat();
  }

  Future<void> sendChatMessage(String message, int historyIndex) async {
    setState(() {
      _loading = true;
      _textController.clear();
      _textFieldFocus.unfocus();
      scrollDownTheSCREEN();
    });

    List<Part> parts = [];

    try {
      var response = _chat.sendMessageStream(
        Content.text(message),
      );
      await for(var item in response){
        var text = item.text;
        if (text == null) {
          showError('No response from API.');
          return;
        } else {
          setState(() {
            _loading = false;
            parts.add(TextPart(text));
            if((history.length - 1) == historyIndex){
              history.removeAt(historyIndex);
            }
            history.insert(historyIndex, Content('model', parts));

          });
        }
      }


    } catch (e, t) {
      print(e);
      print(t);
      showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ChatBot", style: TextStyle(fontSize: 25, color: Colors.white)),
        backgroundColor: Colors.deepPurple[500],
      ),
      backgroundColor: Colors.deepPurple[100],
      body: Stack(
        children: [
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
            itemCount: history.reversed.length,
            controller: _scrollController,
            reverse: true,
            itemBuilder: (context, index) {
              var content = history.reversed.toList()[index];
              var text = content.parts
                  .whereType<TextPart>()
                  .map<String>((e) => e.text)
                  .join('');
              return Align(
                alignment: content.role == 'user' ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 5),
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: content.role == 'user' ? Colors.deepPurple[500] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: content.role == 'user' ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) {
              return SizedBox(height: 15);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 55,
                      child: TextField(
                        cursorColor: Colors.deepPurple,
                        controller: _textController,
                        autofocus: true,
                        focusNode: _textFieldFocus,
                        decoration: InputDecoration(
                          hintText: 'Ask me anything Knowledge is limited to [March - 22]...',
                          hintStyle: TextStyle(color: Colors.grey),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  InkWell(
                    onTap: () {
                      setState(() {
                        history.add(Content('user', [TextPart(_textController.text)]));
                      });
                      sendChatMessage(_textController.text, history.length);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.deepPurple[500],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(offset: Offset(1, 1), blurRadius: 3, spreadRadius: 3, color: Colors.black.withOpacity(0.05)),
                        ],
                      ),
                      child: _loading
                          ? Padding(
                        padding: EdgeInsets.all(15.0),
                        child: CircularProgressIndicator.adaptive(backgroundColor: Colors.white),
                      )
                          : Icon(Icons.send_rounded, color: Colors.white,),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class MessageTile extends StatelessWidget {
  final bool sendByMe;
  final String message;

  const MessageTile({Key? key, required this.sendByMe, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(message),
      trailing: sendByMe ? Icon(Icons.done) : null,
    );
  }
}

