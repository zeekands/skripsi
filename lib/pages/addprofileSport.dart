import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddSportPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Sport'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: SportList(),
    );
  }
}

class SportList extends StatelessWidget {
  String? userEmail = FirebaseAuth.instance.currentUser?.email;

  Future<bool> checkIfUserHasDataForSport(
      String sportName, String? userEmail) async {
    CollectionReference skillLevelCollection =
        FirebaseFirestore.instance.collection('skilllevel');

    try {
      QuerySnapshot querySnapshot = await skillLevelCollection
          .where('email', isEqualTo: userEmail)
          .where('sportName', isEqualTo: sportName)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (error) {
      print('Error checking data for sport: $error');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sports').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<QueryDocumentSnapshot> sportsList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: sportsList.length,
            itemBuilder: (BuildContext context, int index) {
              var sportDoc = sportsList[index];
              String sportName = sportDoc['sport_name'];
              String sportImage = sportDoc['sport_image'];

              return FutureBuilder<bool>(
                future: checkIfUserHasDataForSport(sportName, userEmail),
                builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                  bool hasData = snapshot.data ?? false;

                  return Card(
                    child: ListTile(
                      leading: Image.network(
                        sportImage, height: 50, // Set your desired height
                        width: 50, // Set your desired width
                        fit: BoxFit.cover,
                      ),
                      title: Text(sportName),
                      trailing: hasData
                          ? Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        _showRatingDialog(context, sportName);
                      },
                    ),
                  );
                },
              );
            },
          );
        }
      },
    );
  }

  void _showRatingDialog(BuildContext context, String sportName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return RatingDialog(sportName: sportName);
      },
    );
  }
}

class RatingDialog extends StatefulWidget {
  final String sportName;

  RatingDialog({required this.sportName});

  @override
  _RatingDialogState createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  String selectedRating = 'Newbie';
  String? userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enter Your Self Rating'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: selectedRating,
            onChanged: (String? newValue) {
              setState(() {
                selectedRating = newValue!;
              });
            },
            items: <String>[
              'Newbie',
              'Beginner',
              'Intermediate',
              'Upper Intermediate',
              'Advanced',
              'Expert'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              saveSelfRating(userEmail!, widget.sportName, selectedRating);
              Navigator.of(context).pop();
            },
            child: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 230, 0, 0),
            ),
          ),
        ],
      ),
    );
  }

  void saveSelfRating(String email, String sportName, String selfRating) async {
    CollectionReference skillLevelCollection =
        FirebaseFirestore.instance.collection('skilllevel');

    try {
      QuerySnapshot querySnapshot = await skillLevelCollection
          .where('email', isEqualTo: email)
          .where('sportName', isEqualTo: sportName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing document
        String documentID = querySnapshot.docs.first.id;
        await skillLevelCollection.doc(documentID).update({
          'selfRating': selfRating,
        });
      } else {
        // Create new document
        await skillLevelCollection.add({
          'email': email,
          'sportName': sportName,
          'selfRating': selfRating,
        });
      }

      print('Self rating saved successfully!');
    } catch (e) {
      print('Error saving self rating: $e');
    }
  }
}
