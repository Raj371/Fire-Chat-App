import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/helperfunctions/sharedpref_helper.dart';
import 'package:flutter_firebase/services/auth.dart';
import 'package:flutter_firebase/services/database.dart';
import 'package:flutter_firebase/views/chatscreen.dart';
import 'package:flutter_firebase/views/signin.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isSearching = false;
  String myName, myProfilePic, myUserName, myEmail;
  Stream usersStream, chatRoomsStream;
  TextEditingController searchUsernameEditingController =
      TextEditingController();

  getMyInfoFromSharedPrefernce() async {
    myName = await SharePreferenceHelper().getDisplayName();
    myProfilePic = await SharePreferenceHelper().getUserProfileUrl();
    myUserName = await SharePreferenceHelper().getUserName();
    myEmail = await SharePreferenceHelper().getUserEmail();
  }

  onSearchBtnClick() async {
    usersStream = await DatabaseMethods()
        .getUserByUserName(searchUsernameEditingController.text);
  }

  getChatRoomIdByUsernames(String a, String b) {
    // if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0))
    if (a.compareTo(b) > 0) {
      // codeunitat gives ascii value
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  Widget searchListUserTile({String profileUrl, name, username, email}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Image.network(
              profileUrl,
              height: 40,
              width: 40,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              name != null
                  ? Text(
                      name,
                      style: TextStyle(fontSize: 17),
                    )
                  : Container(),
              SizedBox(height: 3),
              username != null ? Text(username) : Container(),
            ],
          ),
        ],
      ),
    );
  }

  Widget searchUserList() {
    return StreamBuilder(
      stream: usersStream,
      builder: (context, snapshot) {
        return snapshot.data != null && snapshot.hasData
            ? ListView.builder(
                shrinkWrap:
                    true, //listview builder inside column must have shrink wrap
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return GestureDetector(
                    onTap: () {
                      var chatRoomId =
                          getChatRoomIdByUsernames(myUserName, ds['username']);

                      Map<String, dynamic> chatRoomInfoMap = {
                        "users": [myUserName, ds['username']],
                      };

                      DatabaseMethods()
                          .createChatRoom(chatRoomId, chatRoomInfoMap);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(ds['username'], ds['name'])),
                      );
                    },
                    child: searchListUserTile(
                      profileUrl: ds['imgUrl'],
                      name: ds['name'],
                      email: ds['email'],
                      username: ds['username'],
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

  getChatRooms() async {
    chatRoomsStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  Widget chatRoomsList() {
    return StreamBuilder(
      stream: chatRoomsStream,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  return Dismissible(
                    key: Key(ds.id),
                    onDismissed: (direction) {
                      setState(() {
                        DatabaseMethods().deleteChatRoomId(ds.id);

                        snapshot.data.docs[index].removeAt(index);
                      });
                      Scaffold.of(context).showSnackBar(
                          SnackBar(content: Text("${ds.id} dismissed")));
                    },
                    background: Container(
                      color: Colors.red,
                      child: Icon(Icons.delete),
                    ),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: ChatRoomListTile(ds['lastMessage'], ds.id,
                          myUserName, ds['lastMessageSendTs']),
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

  onScreenLoaded() async {
    await getMyInfoFromSharedPrefernce();
    getChatRooms();
  }

  @override
  void initState() {
    // TODO: implement initState
    onScreenLoaded();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Messenger App"),
        backgroundColor: Colors.purple,
        actions: [
          InkWell(
            onTap: () {
              AuthMethods().signOut().then((value) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => SignIn()),
                );
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.exit_to_app),
            ),
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                isSearching
                    ? GestureDetector(
                        onTap: () {
                          searchUsernameEditingController.text = "";
                          setState(() {
                            isSearching = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Icon(Icons.arrow_back),
                        ),
                      )
                    : Container(),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey,
                            width: 1.0,
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: searchUsernameEditingController,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Search by Username"),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (searchUsernameEditingController.text != "") {
                              setState(() {
                                isSearching = true;
                              });
                              onSearchBtnClick();
                            }
                          },
                          child: Icon(Icons.search),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            isSearching
                ? searchUserList()
                : searchUsernameEditingController != null
                    ? chatRoomsList()
                    : Container(),
          ],
        ),
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  String chatRoomId, lastMessage, myUsername;
  Timestamp dt;

  ChatRoomListTile(this.lastMessage, this.chatRoomId, this.myUsername, this.dt);

  @override
  _ChatRoomListTileState createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  // DateTime myDt = w.dt.toDate();
  String profilePicUrl, name, username;
  getThisUserInfo() async {
    username =
        widget.chatRoomId.replaceAll(widget.myUsername, "").replaceAll("_", "");
    QuerySnapshot querySnapshot = await DatabaseMethods().getUserInfo(username);
    name = "${querySnapshot.docs[0]['name']}";
    profilePicUrl = "${querySnapshot.docs[0]['imgUrl']}";
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    getThisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(username, name)),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: profilePicUrl != null
                ? Image.network(profilePicUrl, height: 40, width: 40)
                : Container(
                    height: 40,
                    width: 40,
                  ),
          ),
          SizedBox(width: 12),
          name != null
              ? Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(fontSize: 17),
                          ),
                          SizedBox(height: 3),
                          Text(widget.lastMessage),

                          // var date = new ;
                        ],
                      ),
                      Text(
                        widget.dt.toDate().toString().substring(10, 16),
                        style: TextStyle(fontSize: 16),
                      )
                    ],
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
