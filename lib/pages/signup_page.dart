import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csc_picker/csc_picker.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sportifyapp/pages/signup2_page.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback onclickLogin;
  const SignupPage({Key? key, required this.onclickLogin}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPage();
}

class _SignupPage extends State<SignupPage> {
  final formKey = GlobalKey<FormState>();
  final emailSignup = TextEditingController();
  final passwordSignup = TextEditingController();
  final nameSignup = TextEditingController();
  final ageSignup = TextEditingController();
  final genderSignup = TextEditingController();
  final countrySignup = TextEditingController();
  final citySignup = TextEditingController();

  String selectedGender = 'Male';
  String? countryValue = '';
  String? stateValue = '';
  String? cityValue = '';

  Future SignUp() async {
    print("function signup");
    final isValid = formKey.currentState!.validate();
    if (!isValid) return;
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailSignup.text.trim(),
        password: passwordSignup.text.trim(),
      );

      User user = userCredential.user!;

      // Additional user data
      Map<String, dynamic> userData = {
        'name': nameSignup.text.trim(),
        'age': ageSignup.text.trim(),
        'gender': selectedGender,
        'country': countryValue,
        'city': cityValue,
        'user_type': 0
      };

      // Save additional data to Firebase Firestore (you should initialize Firebase Firestore in your app)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData);

      // Navigate to SignUp2
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignUp2()),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Email sudah terdaftar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sportify SignUp"),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: Container(
        padding: EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 20),
                TextFormField(
                  controller: emailSignup,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: "Email"),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (email) =>
                      email != null && !EmailValidator.validate(email)
                          ? "Enter a valid email"
                          : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: passwordSignup,
                  textInputAction: TextInputAction.next,
                  obscureText: true,
                  decoration: InputDecoration(labelText: "Password"),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (value) => value != null && value.length < 6
                      ? "Enter at least 6 characters"
                      : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: nameSignup,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: "Name"),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (name) =>
                      name != null && name.isEmpty ? "Enter your name" : null,
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: ageSignup,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(labelText: "Age"),
                  keyboardType: TextInputType.number,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (age) {
                    if (age != null && age.isNotEmpty) {
                      int? ageValue = int.tryParse(age);
                      if (ageValue == null || ageValue <= 0) {
                        return "Enter a valid age";
                      }
                    }
                    return null;
                  },
                ),
                SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  onChanged: (String? value) {
                    setState(() {
                      selectedGender = value!;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Gender",
                    border: OutlineInputBorder(),
                  ),
                  items: <String>['Male', 'Female']
                      .map<DropdownMenuItem<String>>(
                        (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 10),
                CSCPicker(
                  layout: Layout.vertical,
                  flagState: CountryFlag.DISABLE,
                  onCountryChanged: (value) {
                    setState(() {
                      countryValue = value;
                    });
                  },
                  onStateChanged: (value) {
                    setState(() {
                      stateValue = value;
                    });
                  },
                  onCityChanged: (value) {
                    setState(() {
                      cityValue = value;
                    });
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      minimumSize: Size.fromHeight(50),
                      backgroundColor: Color.fromARGB(255, 230, 0, 0)),
                  onPressed: SignUp,
                  icon: Icon(Icons.arrow_forward),
                  label: Text("Sign Up"),
                ),
                SizedBox(height: 10),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.grey),
                    text: "Sudah punya akun? ",
                    children: [
                      TextSpan(
                        recognizer: TapGestureRecognizer()
                          ..onTap = widget.onclickLogin,
                        text: "Login",
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
    );
  }
}
