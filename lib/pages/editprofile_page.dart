import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:path/path.dart';

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
  TextEditingController _bioController = TextEditingController();
  File? image;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user!.displayName ?? '';
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user!.email)
        .get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;

      if (userData.containsKey('age')) {
        _ageController.text = userData['age'].toString();
      }
      if (userData.containsKey('bio')) {
        _bioController.text = userData['bio'];
      }
    }
  }

  Future<void> _uploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
        uploadFile();
      } else {
        print('No image selected.');
      }
    });
  }

  Future<void> uploadFile() async {
    if (image == null) return;
    final fileName = basename(image!.path);
    final destination = 'profile_images/$fileName';

    try {
      UploadTask task =
          FirebaseStorage.instance.ref(destination).putFile(image!);
      TaskSnapshot snapshot = await task;

      // Get the download URL for the image
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user data in Firestore with the download URL
      String uid = widget.user!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'profileImageUrl':
            downloadUrl, // Assuming you have a field named 'profileImageUrl'
      });

      print('Image uploaded to Firebase');
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  void showDialogUploadImage(BuildContext context) {
    String? selectedImagePath; // Variable to hold the selected image path

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Upload Image"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  selectedImagePath != null
                      ? Image.file(
                          File(selectedImagePath!),
                          height: 100, // Set the desired height
                          width: 100, // Set the desired width
                        )
                      : SizedBox(),
                  ElevatedButton(
                    onPressed: () async {
                      final pickedFile =
                          await picker.pickImage(source: ImageSource.gallery);

                      if (pickedFile != null) {
                        setState(() {
                          selectedImagePath = pickedFile.path;
                        });
                      }
                    },
                    child: Text("Select Image"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 230, 0, 0),
                    ),
                  ),
                  // Show nothing if no image is selected
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (selectedImagePath != null) {
                      image = File(selectedImagePath!);
                      uploadFile();
                      Navigator.of(context).pop(); // Close the dialog
                    }
                  },
                  child: Text("Upload"),
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.black), // Change the color here
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: Text("Close"),
                  style: ButtonStyle(
                    foregroundColor: MaterialStateProperty.all<Color>(
                        Colors.black), // Change the color here
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      String uid = widget.user!.uid;
      String newName = _nameController.text;
      String newAge = _ageController.text;
      String newBio = _bioController.text;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.email)
          .update({
        'name': newName,
        'age': newAge,
        'bio': newBio,
      });

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
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
                          showDialogUploadImage(context);
                          print('Upload Image');
                        } else if (value == 2) {
                          // Handle Delete Image option
                          print('Delete Image');
                        }
                      },
                      child: FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.user!.email)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator(); // or some loading indicator
                          }
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }
                          String? profileImageUrl =
                              snapshot.data!['profileImageUrl'];
                          return CircleAvatar(
                            radius: 64,
                            backgroundImage: profileImageUrl != null &&
                                    profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : AssetImage('assets/images/defaultprofile.png')
                                    as ImageProvider, // Cast to ImageProvider
                          );
                        },
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
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(labelText: 'Bio'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your bio';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _submitForm(context), // Fix is here
                child: Text('Save Changes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 230, 0, 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
