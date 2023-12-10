import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path/path.dart';

class SportsManagementPage extends StatefulWidget {
  @override
  SportsManagementPageState createState() => SportsManagementPageState();
}

class SportsManagementPageState extends State<SportsManagementPage> {
  String? uploadedImageUrl;
  PlatformFile? pickedFile;
  UploadTask? uploadTask;
  File? image;
  final ImagePicker picker = ImagePicker();

  Future selectedFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    setState(() {
      pickedFile = result.files.first;
    });
  }

  Future uploadFile() async {
    final path = 'sports/${pickedFile!.name}';
    final file = File(pickedFile!.path!);

    final ref = FirebaseStorage.instance.ref().child(path);
    ref.putFile(file);

    final snapshot = await uploadTask!.whenComplete(() {});
    final urlDownload = await snapshot.ref.getDownloadURL();
    print('Download Link: $urlDownload');
  }

  var result = null;
  void uploadImage(BuildContext context) async {
    try {
      result = await file_picker.FilePicker.platform
          .pickFiles(type: file_picker.FileType.image);
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future processUpload() async {
    if (image == null) return;
    final fileName = basename(image!.path);
    final destination = 'sports/$fileName';

    try {
      UploadTask task =
          FirebaseStorage.instance.ref(destination).putFile(image!);
      TaskSnapshot snapshot = await task;

      uploadedImageUrl = await snapshot.ref.getDownloadURL();
      print(uploadedImageUrl);

      print('Image uploaded to Firebase');
    } catch (e) {
      print('Error uploading image: $e');
    }
  }

  Future<String> getImageDownloadUrl(String imageName) async {
    String downloadUrl = await firebase_storage.FirebaseStorage.instance
        .ref('sports/$imageName')
        .getDownloadURL();

    return downloadUrl;
  }

  String capitalizeFirst(String s) {
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
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

  Future<void> addSport(BuildContext context) async {
    TextEditingController sportNameController = TextEditingController();
    String? selectedImagePath;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Add Sport'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: sportNameController,
                    decoration: InputDecoration(
                      labelText: 'Sport Name',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 2.0),
                      ),
                      labelStyle: TextStyle(color: Colors.black),
                    ),
                  ),
                  SizedBox(height: 20),
                  Column(
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
                          final pickedFile = await picker.pickImage(
                              source: ImageSource.gallery);

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
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    String sportName = sportNameController.text;
                    if (selectedImagePath != null) {
                      image = File(selectedImagePath!);
                      print(image);
                      await processUpload();
                      Navigator.of(context).pop();
                    }

                    if (sportName.isNotEmpty) {
                      sportName = capitalizeFirst(sportName);
                      DocumentReference newSportRef =
                          FirebaseFirestore.instance.collection('sports').doc();
                      print("upload " + uploadedImageUrl.toString());

                      newSportRef.set({
                        'sport_id': newSportRef.id,
                        'sport_name': sportName,
                        'sport_image': uploadedImageUrl,
                      });

                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    'Add Sport',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void deleteSport(String sportId) async {
    await FirebaseFirestore.instance.collection('sports').doc(sportId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sports Management'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sports').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                String sportId = data['sport_id'];
                String sportName = data['sport_name'];

                return ListTile(
                  title: Text(sportName),
                  subtitle: Text('Sport ID: $sportId'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => deleteSport(sportId),
                  ),
                );
              }).toList(),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addSport(context),
        child: Icon(Icons.add),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SportsManagementPage(),
  ));
}
