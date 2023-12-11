import 'package:csc_picker/csc_picker.dart';
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
  TextEditingController cp = TextEditingController();
  TextEditingController country = TextEditingController();
  TextEditingController state = TextEditingController();
  TextEditingController city = TextEditingController();
  File? image;
  final ImagePicker picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _nameController.text = widget.user!.displayName ?? '';

    print("test " + city.text);
  }

  Future<void> _fetchUserData() async {
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user!.email)
        .get();

    if (userSnapshot.exists) {
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;

      if (userData.containsKey('name')) {
        _nameController.text = userData['name'].toString();
      }
      if (userData.containsKey('country')) {
        country.text = userData['country'].toString();
      }
      if (userData.containsKey('city')) {
        city.text = userData['city'].toString();
      }
      if (userData.containsKey('contactPerson')) {
        cp.text = userData['contactPerson'].toString();
      }

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

      String downloadUrl = await snapshot.ref.getDownloadURL();
      print(downloadUrl);

      String uid = widget.user!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.email)
          .update({
        'profileImageUrl': downloadUrl,
      });

      print('Image uploaded to Firebase');
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  void showDialogUploadImage(BuildContext context) {
    String? selectedImagePath;

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
                          height: 100,
                          width: 100,
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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    if (selectedImagePath != null) {
                      image = File(selectedImagePath!);
                      print(image);
                      uploadFile();
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text("Upload"),
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text("Close"),
                  style: ButtonStyle(
                    foregroundColor:
                        MaterialStateProperty.all<Color>(Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void changeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Change City and Country'),
          content: CSCPicker(
            defaultCountry: CscCountry.Indonesia,
            onCountryChanged: (value) {
              setState(() {
                country.text = value;
              });
            },
            onStateChanged: (value) {
              setState(() {
                state.text = value ?? '';
              });
            },
            onCityChanged: (value) {
              setState(() {
                city.text = value ?? '';
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  String _extractCountryName(String fullCountry) {
    // Remove the flag emoji from the country name
    return fullCountry.replaceAll(RegExp(r'[^\x00-\x7F]+'), '').trim();
  }

  void _updateCityAndCountry(String newCity, String newCountry) {
    setState(() {
      city.text = newCity;
      country.text = newCountry;
    });
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      String uid = widget.user!.uid;
      String newName = _nameController.text;
      String newAge = _ageController.text;
      String newBio = _bioController.text;
      String newCP = cp.text;
      String newCountry = _extractCountryName(country.text);
      String newCity = city.text;
      print(newCountry);
      print(newCity);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user!.email)
          .update({
        'name': newName,
        'age': newAge,
        'bio': newBio,
        'contactPerson': newCP,
        'country': newCountry,
        'city': newCity,
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    print('Clicked on CircleAvatar');
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
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
                              return CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            String? profileImageUrl =
                                snapshot.data!['profileImageUrl'];
                            return Column(
                              children: [
                                CircleAvatar(
                                  radius: 64,
                                  backgroundImage: profileImageUrl != null &&
                                          profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : AssetImage(
                                              'assets/images/defaultprofile.png')
                                          as ImageProvider,
                                ),
                                SizedBox(height: 20),
                                Padding(
                                  padding: const EdgeInsets.all(
                                      4.0), // Adjust the padding as needed
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${city.text}, ${_extractCountryName(country.text)}',
                                            style: TextStyle(
                                              color: Colors.black,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => changeDialog(context),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Row(
                                                children: [
                                                  SizedBox(width: 8.0),
                                                  // Icon(Icons.edit, color: Colors.red),
                                                  Text(
                                                    "Change",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                      decoration: TextDecoration
                                                          .underline,
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      TextFormField(
                                        controller: _nameController,
                                        decoration: InputDecoration(
                                          labelText: 'Name',
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.black,
                                                width: 2.0),
                                          ),
                                          labelStyle:
                                              TextStyle(color: Colors.black),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(
                                          height:
                                              16.0), // Add vertical spacing between TextFormField widgets
                                      TextFormField(
                                        controller: _ageController,
                                        decoration: InputDecoration(
                                          labelText: 'Age',
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.black,
                                                width: 2.0),
                                          ),
                                          labelStyle:
                                              TextStyle(color: Colors.black),
                                        ),
                                        keyboardType: TextInputType.number,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your age';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: _bioController,
                                        decoration: InputDecoration(
                                          labelText: 'Description',
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.black,
                                                width: 2.0),
                                          ),
                                          labelStyle:
                                              TextStyle(color: Colors.black),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your bio';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: 16.0),
                                      TextFormField(
                                        controller: cp,
                                        decoration: InputDecoration(
                                          labelText: 'Contact Person',
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: Colors.black,
                                                width: 2.0),
                                          ),
                                          labelStyle:
                                              TextStyle(color: Colors.black),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your contact information';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _submitForm(context),
                  child: Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 230, 0, 0),
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
