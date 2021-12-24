import 'package:flutter/material.dart';
import 'package:flutter_firebase/services/auth.dart';

class SignIn extends StatefulWidget {
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Messenger Clone"),
        backgroundColor:Colors.purple,
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            AuthMethods().signInWithGoogle(context);
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Color(0xffDB4437),
            ),
            padding: EdgeInsets.symmetric(horizontal: 18,vertical: 10),
            child: Text("Sign In with Google",style: TextStyle(fontSize: 18,color: Colors.white),),
          ),
        ),
      ),
    );
  }
}
