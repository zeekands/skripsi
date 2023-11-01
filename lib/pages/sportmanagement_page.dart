import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:path/path.dart' as path;

class SportsManagementPage extends StatefulWidget {
  @override
  SportsManagementPageState createState() => SportsManagementPageState();
}

class SportsManagementPageState extends State<SportsManagementPage> {
  String? uploadedImageUrl;
  PlatformFile? pickedFile;
  UploadTask? uploadTask;

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
    if (result != null) {
      final fileBytes = result.files.first.bytes;
      final fileName = result.files.first.name;

      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('sports/$fileName');

      final SettableMetadata metadata =
          SettableMetadata(contentType: 'image/png');
      var uploadTask = ref.putData(fileBytes!, metadata);

      var snapshot = await uploadTask.whenComplete(() {});

      setState(() {});

      uploadedImageUrl = await snapshot.ref.getDownloadURL() as String?;

      String fileNameWithoutExtension = path.basenameWithoutExtension(fileName);
      print('Uploaded Image URL: $uploadedImageUrl');
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

  Future<void> addSport(BuildContext context) async {
    TextEditingController sportNameController = TextEditingController();
    print(uploadedImageUrl);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Sport'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: sportNameController,
                decoration: InputDecoration(labelText: 'Sport Name'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => uploadImage(context),
                child: Text('Upload Image'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                String sportName = sportNameController.text;

                await processUpload();
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
              child: Text('Add Sport'),
            ),
          ],
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
