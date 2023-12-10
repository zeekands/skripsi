import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ResetPasswordPage extends StatefulWidget {
  final Function onclickSignup;

  ResetPasswordPage({required this.onclickSignup});

  @override
  _YourResetPasswordPageState createState() => _YourResetPasswordPageState();
}

class _YourResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
                labelStyle: TextStyle(color: Colors.black),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                String email = _emailController.text.trim();

                if (email.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance
                        .sendPasswordResetEmail(email: email);
                    _showResetPasswordSuccessDialog();
                  } catch (e) {
                    print('Error sending password reset email: $e');
                    _showResetPasswordErrorDialog();
                  }
                } else {
                  // Handle the case where the email field is empty.
                }
              },
              child: Text('Reset Password'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 230, 0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content:
              Text('Password reset email sent successfully. Check your email.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                // Navigate back to the login page or any other desired page
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.black, // Set the text color to black
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showResetPasswordErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(
              'Error sending password reset email. Please check your email and try again.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.black, // Set the text color to black
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
