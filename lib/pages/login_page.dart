import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onclickSignup;

  const LoginPage({Key? key, required this.onclickSignup}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailLogin = TextEditingController();
  final passwordLogin = TextEditingController();

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailLogin.text.trim(), password: passwordLogin.text.trim());
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Invalid Email/Password")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(20),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 120,
                    backgroundImage:
                        AssetImage('assets/images/sportify_logo.png'),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: emailLogin,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(),
                      // border: OutlineInputBorder(
                      //   borderSide: BorderSide(color: Colors.black, width: 2.0),
                      // ),
                      // enabledBorder: OutlineInputBorder(
                      //   borderSide: BorderSide(color: Colors.white, width: 2.0),
                      // ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2.0),
                      ),
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (email) =>
                        email != null && !EmailValidator.validate(email)
                            ? "Enter a valid email"
                            : null,
                  ),
                  SizedBox(height: 10),
                  TextFormField(
                    controller: passwordLogin,
                    textInputAction: TextInputAction.done,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2.0),
                      ),
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) => value != null && value.length < 6
                        ? "Enter at least 6 characters"
                        : null,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: login,
                    child: Text("Login"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 230, 0, 0),
                    ),
                  ),
                  SizedBox(height: 10),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey),
                      text: "Don't have an account? ",
                      children: [
                        TextSpan(
                          recognizer: TapGestureRecognizer()
                            ..onTap = widget.onclickSignup,
                          text: "Sign Up",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            color: Color.fromARGB(255, 230, 0, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
