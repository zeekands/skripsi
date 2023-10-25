import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUp2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Additional Registration')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            if (user != null) {
              // Update additional registration status
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({
                'additionalRegistrationComplete': true,
              });
            }
          },
          child: Text('Complete Registration'),
        ),
      ),
    );
  }
}
