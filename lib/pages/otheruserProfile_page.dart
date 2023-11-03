import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OtherUserProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userEmail;

  OtherUserProfilePage({required this.userData, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        elevation: 0,
        title: Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(top: 16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 64,
              backgroundImage: userData['profileImageUrl'] != null &&
                      userData['profileImageUrl'].isNotEmpty
                  ? NetworkImage(userData['profileImageUrl'])
                  : AssetImage('assets/images/defaultprofile.png')
                      as ImageProvider,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${userData['name']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${userData['age']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${userData['gender']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '${userData['bio']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 5),

                  // Add commendation images here if needed
                ],
              ),
            ),
            Card(
              color: Colors.transparent,
              elevation: 0,
              child: Padding(
                padding: EdgeInsets.all(5.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('skilllevel')
                      .where('email', isEqualTo: userEmail)
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      var data = snapshot.data!.docs;
                      if (data.isNotEmpty) {
                        return Column(
                          children: data.map((doc) {
                            var selfRating = doc['selfRating'];
                            var selfRatingSport = doc['sportName'];
                            return FutureBuilder<QuerySnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('sports')
                                  .where('sport_name',
                                      isEqualTo: selfRatingSport)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                } else if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                } else {
                                  var sportData = snapshot.data!.docs[0].data()
                                      as Map<String, dynamic>?;
                                  if (sportData != null) {
                                    var sportImage = sportData['sport_image'];
                                    return Card(
                                      margin: EdgeInsets.all(16.0),
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  child:
                                                      Image.network(sportImage),
                                                ),
                                                SizedBox(width: 5),
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      selfRatingSport,
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                      ),
                                                    ),
                                                    SizedBox(height: 2),
                                                    Text(selfRating),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Text('Sport data not found');
                                  }
                                }
                              },
                            );
                          }).toList(),
                        );
                      } else {
                        return Center(child: Text('Self Rating not available'));
                      }
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
