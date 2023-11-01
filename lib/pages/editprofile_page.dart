import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends StatefulWidget {
  final User? user;

  EditProfilePage({required this.user});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  File? _image;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user!.displayName ?? '';
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    String uid = widget.user!.uid;
    DocumentSnapshot userSnapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;

      if (userData.containsKey('age')) {
        _ageController.text = userData['age'].toString();
      }
    }
  }

  Future<void> _uploadImage(String uid) async {
    if (_image != null) {
      Reference storageReference =
          FirebaseStorage.instance.ref().child('profile_images/$uid.jpg');
      UploadTask uploadTask = storageReference.putFile(_image!);
      await uploadTask.whenComplete(() => print('Image uploaded to Firebase'));
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      String uid = widget.user!.uid;
      String newName = _nameController.text;
      String newAge = _ageController.text;

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': newName,
        'age': newAge,
      });

      await _uploadImage(uid);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  // Handle the click event here
                  print('Clicked on CircleAvatar');
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: PopupMenuButton<int>(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 1,
                          child: Text('Upload Image'),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: Text('Delete Image'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 1) {
                          // Handle Upload Image option
                          print('Upload Image');
                        } else if (value == 2) {
                          // Handle Delete Image option
                          print('Delete Image');
                        }
                      },
                      child: CircleAvatar(
                        radius: 64,
                        backgroundImage: NetworkImage(
                          'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_LdbmhiNM6Ypzb3FM4PPuFP9rHe7ri8Ju.jpg',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitForm,
                child: Text('Save Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
