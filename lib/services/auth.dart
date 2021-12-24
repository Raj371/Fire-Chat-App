import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_firebase/helperfunctions/sharedpref_helper.dart';
import 'package:flutter_firebase/services/database.dart';
import 'package:flutter_firebase/views/home.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser() async {
    return await auth.currentUser;
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    final GoogleSignInAccount _googleSignInAccount = await _googleSignIn.signIn();
  
    final GoogleSignInAuthentication googleSignInAuthentication = await _googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleSignInAuthentication.idToken,
      accessToken:googleSignInAuthentication.accessToken,
    );

    UserCredential result = await _firebaseAuth.signInWithCredential(credential);

    User userDetails = result.user;

    if(result != null) {
      SharePreferenceHelper().saveUserEmail(userDetails.email);
      SharePreferenceHelper().saveUserId(userDetails.uid);
      SharePreferenceHelper().saveUserName(userDetails.email.replaceAll("@gmail.com","" ));
      SharePreferenceHelper().saveDisplayName(userDetails.displayName);
      SharePreferenceHelper().saveUserProfileUrl(userDetails.photoURL);

      Map<String,dynamic> userInfoMap = {
        "email":userDetails.email,
        "username":userDetails.email.replaceAll("@gmail.com", ""),
        "name":userDetails.displayName,
        "imgUrl":userDetails.photoURL
      };

      DatabaseMethods().addUserInfoToDB(userDetails.uid, userInfoMap)
      .then((value) {
        Navigator.pushReplacement(context , MaterialPageRoute(builder: (context) => HomePage()));
      }) ;
    }
  }

 Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await auth.signOut();
  }
}