import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/helperfunctions/sharedpref_helper.dart';
import 'package:flutter_firebase/services/database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';

class ChatScreen extends StatefulWidget {
  final String chatWithUsername, name;
  ChatScreen(this.chatWithUsername, this.name);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String chatRoomId, messageId = "";
  Stream messageStream, chatRoomsStream;
  File _storedImage;
  String myName, myProfilePic, myUserName, myEmail;
  TextEditingController messageTextEditingController = TextEditingController();

  getChatRoomIdByUsernames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      // codeunitat gives ascii value
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  getMyInfoFromSharedPrefernce() async {
    myName = await SharePreferenceHelper().getDisplayName();
    myProfilePic = await SharePreferenceHelper().getUserProfileUrl();
    myUserName = await SharePreferenceHelper().getUserName();
    myEmail = await SharePreferenceHelper().getUserEmail();

    chatRoomId = getChatRoomIdByUsernames(widget.chatWithUsername, myUserName);
  }

  getAndSetMessage() async {
    messageStream = await DatabaseMethods().getChatRoomMessages(chatRoomId);
    setState(() {});
  }

  
  Widget chatMessageTile(String type, String message, bool sendByMe) {
    return type == "text"
        ? Row(
            mainAxisAlignment:
                sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft:
                        sendByMe ? Radius.circular(24) : Radius.circular(0),
                    topRight: Radius.circular(24),
                    bottomRight:
                        sendByMe ? Radius.circular(0) : Radius.circular(24),
                  ),
                  color: Colors.blue,
                ),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: EdgeInsets.all(16),
                child: Text(
                  message,
                  style:
                      TextStyle(color: sendByMe ? Colors.white : Colors.blue),
                ),
              ),
            ],
          )
        : Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: MediaQuery.of(context).size.width / 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
                bottomLeft: sendByMe ? Radius.circular(10) : Radius.circular(0),
                bottomRight:
                    sendByMe ? Radius.circular(0) : Radius.circular(10),
              ),
            ),
            height: MediaQuery.of(context).size.height / 2.5,
            alignment: Alignment.centerRight,
            child: message == null
                ? CircularProgressIndicator()
                : ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.network(
                      message,
                      height: MediaQuery.of(context).size.height / 2.5,
                      width: 250,
                      fit: BoxFit.fill,
                    ),
                  ),
          );
  }

  Widget chatMessages() {
    return StreamBuilder(
      stream: messageStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                padding: EdgeInsets.only(
                  bottom: 70,
                  top: 16,
                ),
                reverse: true,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return GestureDetector(
                    onLongPress: () {
                    },
                    child: chatMessageTile(
                      ds['type'],
                      ds['message'],
                      myUserName == ds['sendBy'],
                    ),
                  );
                },
              )
            : Center(
                child: CircularProgressIndicator(),
              );
      },
    );
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPrefernce();
    getAndSetMessage();
  }

  addMessage(bool sendClicked) {
    if (messageTextEditingController.text != "" && sendClicked) {
      String message = messageTextEditingController.text;

      var lastMessageTs = DateTime.now();

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "ts": lastMessageTs,
        "type": "text",
        "imgUrl": myProfilePic,
      };

      messageId = randomAlphaNumeric(12);

      DatabaseMethods().addMessage(chatRoomId, messageId, messageInfoMap).then(
        (value) {
          Map<String, dynamic> lastMessageInfoMap = {
            "lastMessage": message,
            "lastMessageSendTs": lastMessageTs,
            "lastMessageSendBy": myUserName,
          };

          DatabaseMethods()
              .updateLastMessageSend(chatRoomId, lastMessageInfoMap);

          messageTextEditingController.text = "";

          // make msgid blank to get generate on new msg
          messageId = "";
        },
      );
    }
  }

  Future _takePicture() async {
    ImagePicker _picker = ImagePicker();

    await _picker
        .getImage(source: ImageSource.gallery, imageQuality: 50)
        .then((xFile) async {
      if (xFile != null) {
        _storedImage = File(xFile.path);
        String imgUrl = await DatabaseMethods()
            .uploadImage(_storedImage, chatRoomId)
            .catchError((onError) {
          print("Error $onError");
        });

        var lastMessageTs = DateTime.now();
        String messageId = randomAlphaNumeric(12);
        Map<String, dynamic> messageInfoMap = {
          "message": imgUrl,
          "sendBy": myUserName,
          "ts": lastMessageTs,
          "type": "img",
          "imgUrl": myProfilePic,
        };

        DatabaseMethods()
            .addMessage(chatRoomId, messageId, messageInfoMap)
            .then(
          (value) {
            Map<String, dynamic> lastMessageInfoMap = {
              "lastMessage": "Photo",
              "lastMessageSendTs": lastMessageTs,
              "lastMessageSendBy": myUserName,
            };

            DatabaseMethods()
                .updateLastMessageSend(chatRoomId, lastMessageInfoMap);
          },
        );
      }
    });
  }

// method of updating same msg again and again
// can be use when we want to show if someone is typing

  // addMessage(bool sendClicked) {
  //   if (messageTextEditingController.text != "") {
  //     String message = messageTextEditingController.text;

  //     var lastMessageTs = DateTime.now();

  //     Map<String, dynamic> messageInfoMap = {
  //       "message": message,
  //       "sendBy": myUserName,
  //       "ts": lastMessageTs,
  //       "imgUrl": myProfilePic,
  //     };

  //     if (messageId == "") {
  //       messageId = randomAlphaNumeric(12);
  //     }

  //     DatabaseMethods()
  //         .addMessage(chatRoomId, messageId, messageInfoMap)
  //         .then((value) {
  //       Map<String, dynamic> lastMessageInfoMap = {
  //         "lastMessage": message,
  //         "lastMessageSendTs": lastMessageTs,
  //         "lastMessageSendBy": myUserName,
  //       };

  //       DatabaseMethods().updateLastMessageSend(chatRoomId, lastMessageInfoMap);

  //       if (sendClicked) {
  //         messageTextEditingController.text = "";

  //         // make msgid blank to get generate on new msg
  //         messageId = "";
  //       }
  //     });
  //   }
  // }

  @override
  void initState() {
    // TODO: implement initState
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
        backgroundColor: Colors.purple,
      ),
      body: Container(
        child: Stack(
          children: [
            chatMessages(),
            Container(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          addMessage(false);
                        },
                        controller: messageTextEditingController,
                        style: TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            onPressed: () {
                              _takePicture();
                            },
                            icon: Icon(Icons.photo),
                            color: Colors.white,
                          ),
                          border: InputBorder.none,
                          hintText: "Type a Message...",
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                        onTap: () {
                          addMessage(true);
                        },
                        child: Icon(
                          Icons.send,
                          color: Colors.white,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
