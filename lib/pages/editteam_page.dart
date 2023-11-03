import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:path/path.dart';

class EditTeamPage extends StatefulWidget {
  final String teamName;
  final int teamId;
  final String teamSport;
  final String teamCreator;
  final String teamDescription;
  final String teamImageUrl;

  EditTeamPage({
    required this.teamName,
    required this.teamId,
    required this.teamSport,
    required this.teamCreator,
    required this.teamDescription,
    required this.teamImageUrl,
  });

  @override
  _EditTeamPageState createState() => _EditTeamPageState();
}

class _EditTeamPageState extends State<EditTeamPage> {
  TextEditingController _TeamnameController = TextEditingController();
  TextEditingController _TeamDescriptionController = TextEditingController();
  File? image;
  final ImagePicker picker = ImagePicker();

  void _uploadImage() async {
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
    final destination = 'team_images/$fileName';

    try {
      UploadTask task =
          FirebaseStorage.instance.ref(destination).putFile(image!);
      TaskSnapshot snapshot = await task;

      // Get the download URL for the image
      String downloadUrl = await snapshot.ref.getDownloadURL();
      print(downloadUrl);

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId.toString())
          .update({
        'teamImageUrl': downloadUrl,
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
      String newTeamName = _TeamnameController.text;
      String newTeamDescription = _TeamDescriptionController.text;

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId.toString())
          .update({
        'team_name': newTeamName,
        'team_description': newTeamDescription,
      });

      Navigator.pop(context);
    }
  }

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _TeamnameController.text = widget.teamName;
    _TeamDescriptionController.text = widget.teamDescription;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Team'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () {
                  showDialogUploadImage(context);
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
                      child: CircleAvatar(
                        radius: 64,
                        backgroundImage: widget.teamImageUrl != null &&
                                widget.teamImageUrl.isNotEmpty
                            ? NetworkImage(widget.teamImageUrl)
                            : AssetImage('assets/images/defaultTeam.png')
                                as ImageProvider, // Cast to ImageProvider
                      ),
                    ),
                  ),
                ),
              ),
              TextFormField(
                controller: _TeamnameController,
                decoration: InputDecoration(labelText: 'Team Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _TeamDescriptionController,
                decoration: InputDecoration(labelText: 'Team Description'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _submitForm(context);
                },
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
