import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_firebase/helperfunctions/sharedpref_helper.dart';
import 'package:random_string/random_string.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
// import 'package:image_picker/image_picker.dart';

class DatabaseMethods {
  Future addUserInfoToDB(
      String userId, Map<String, dynamic> userInfoMap) async {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(userInfoMap);
  }

  Future<Stream<QuerySnapshot>> getUserByUserName(String username) async {
    return FirebaseFirestore.instance
        .collection("users")
        // .where("username", isEqualTo: username)
        .where('username', isGreaterThanOrEqualTo: username, isLessThan: username.substring(0, username.length-1) + String.fromCharCode(username.codeUnitAt(username.length - 1) + 1))
        .snapshots();
  }

  Future addMessage(
      String chatRoomId, String messageId, Map messageInfoMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageInfoMap);
  }

  updateLastMessageSend(String chatRoomId, Map lastMessageInfoMap) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .update(lastMessageInfoMap);
  }

  createChatRoom(String chatRoomId, Map chatRoomInfoMap) async {
    final snapShot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();

    if (snapShot.exists) {
      return true;
    } else {
      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
    }
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("ts", descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String myUserName = await SharePreferenceHelper().getUserName();
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .orderBy("lastMessageSendTs", descending: true)
        .where("users", arrayContains: myUserName)
        .snapshots();
  }

  Future<QuerySnapshot> getUserInfo(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();
  }

  Future<void> deleteChatRoomId(String chatRoomId) async {
    // print(chatRoomId);
    return await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .get()
        .then((snapshot) {
      for (DocumentSnapshot<Map<String, dynamic>> ds in snapshot.docs) {
        print(ds.id);
        FirebaseFirestore.instance
            .collection("chatrooms")
            .doc(chatRoomId)
            .collection("chats")
            .doc(ds.id)
            .delete();
      }
      ;
    }).then((value) {
      FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .delete();
    });
  }

  Future<String> uploadImage(File imageFile, String chatRoomId) async {
    // print(chatRoomId);
    String uniqueFilename = Uuid().v1();
    var ref = FirebaseStorage.instance
        .ref()
        .child('images')
        .child("$uniqueFilename.jpg");

    var uploadTask = await ref.putFile(imageFile).catchError((onError) {
      print("Img error $onError");
      return onError;
    });

    String imgUrl = await uploadTask.ref.getDownloadURL();
    print(imgUrl);
    return imgUrl;
  }

  
}
