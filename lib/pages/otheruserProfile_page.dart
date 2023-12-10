import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sportifyapp/pages/detailSportUser_page.dart';

class OtherUserProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String userEmail;

  OtherUserProfilePage({required this.userData, required this.userEmail});
  String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  Future<List<Map<String, dynamic>>> getCommendationsData(
      String? userEmail) async {
    var commendationsData = await FirebaseFirestore.instance
        .collection('commendations')
        .where('toUser', isEqualTo: userEmail)
        .get();

    List<Map<String, dynamic>> commendations = [];

    for (var doc in commendationsData.docs) {
      commendations.add(doc.data() as Map<String, dynamic>);
    }

    return commendations;
  }

  Future<bool> areUsersFriends(
      String currentUserEmail, String userEmail) async {
    try {
      if (currentUserEmail == userEmail) {
        // Users are the same, not friends
        return false;
      }

      // Check if currentUserEmail is in the friends array of userEmail
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (userDoc.exists) {
        List<dynamic> friendsList = userDoc['friends'] ?? [];
        return friendsList.contains(currentUserEmail);
      } else {
        // User document not found
        return false;
      }
    } catch (e) {
      print('Error checking friendship: $e');
      return false;
    }
  }

  Future<void> sendFriendRequest(
      String currentUserEmail, String userEmail, BuildContext context) async {
    try {
      // Check if users are already friends
      DocumentSnapshot senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserEmail)
          .get();

      List<dynamic> senderFriendsList = senderDoc['friends'] ?? [];

      if (senderFriendsList.contains(userEmail)) {
        // Users are already friends
        showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('Already Friends'),
              content:
                  Text('$currentUserEmail is already a friend of $userEmail.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        // Check if a friend request has already been sent
        QuerySnapshot existingRequestQuery = await FirebaseFirestore.instance
            .collection('notifications')
            .where('from_user', isEqualTo: currentUserEmail)
            .where('recipient_email', isEqualTo: userEmail)
            .where('category', isEqualTo: "Friend")
            .where('type', isEqualTo: 'Request')
            .limit(1)
            .get();

        if (existingRequestQuery.docs.isNotEmpty) {
          // A friend request has already been sent
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text('Friend Request Already Sent'),
                content: Text(
                    'You have already sent a friend request to this user.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // No existing friend request, proceed to send
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipient_email': userEmail,
            'message': '$currentUserEmail has sent you a friend request.',
            'from_user': currentUserEmail,
            'timestamp': FieldValue.serverTimestamp(),
            'category': 'Friend',
            'type': 'Request',
          });

          // Show success dialog
          showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text('Friend Request Sent'),
                content:
                    Text('Your friend request has been sent successfully.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );

          print('Friend request sent successfully.');
        }
      }
    } catch (e) {
      print('Error sending friend request: $e');
    }
  }

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
                  Text(
                    '${userData['contactPerson']}',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 5),
                  FutureBuilder<bool>(
                    future: areUsersFriends(currentUserEmail!, userEmail),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        bool areFriends = snapshot.data ?? false;

                        return Visibility(
                          visible: !areFriends,
                          child: ElevatedButton(
                            onPressed: () {
                              sendFriendRequest(
                                  currentUserEmail!, userEmail, context);
                            },
                            child: Text("Add Friend"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 230, 0, 0),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: getCommendationsData(userEmail),
                    builder: (
                      BuildContext context,
                      AsyncSnapshot<List<Map<String, dynamic>>>
                          commendationSnapshot,
                    ) {
                      if (commendationSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (commendationSnapshot.hasError) {
                        return Text('Error: ${commendationSnapshot.error}');
                      } else {
                        List<Map<String, dynamic>> commendations =
                            commendationSnapshot.data!;
                        int totalCommendation1 = 0;
                        int totalCommendation2 = 0;
                        int totalCommendation3 = 0;
                        int totalCommendation4 = 0;

                        for (var commendationData in commendations) {
                          totalCommendation1 +=
                              commendationData['commendation1'] as int? ?? 0;
                          totalCommendation2 +=
                              commendationData['commendation2'] as int? ?? 0;
                          totalCommendation3 +=
                              commendationData['commendation3'] as int? ?? 0;
                          totalCommendation4 +=
                              commendationData['commendation4'] as int? ?? 0;
                        }

                        int count = commendations.length;

                        // Calculate the average commendation for each type
                        double averageCommendation1 =
                            count > 0 ? totalCommendation1 / count : 0.0;
                        double averageCommendation2 =
                            count > 0 ? totalCommendation2 / count : 0.0;
                        double averageCommendation3 =
                            count > 0 ? totalCommendation3 / count : 0.0;
                        double averageCommendation4 =
                            count > 0 ? totalCommendation4 / count : 0.0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            commendationImage('skillfull.png', 'Skillfull',
                                averageCommendation1),
                            commendationImage('friendly.png', 'Positive',
                                averageCommendation2),
                            commendationImage('teamplayer.png', 'Teamwork',
                                averageCommendation3),
                            commendationImage('sportmanship.png',
                                'Sportsmanship', averageCommendation4),
                          ],
                        );
                      }
                    },
                  )
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
                                    return GestureDetector(
                                      onTap: () {
                                        // Navigate to the detailSportUser_page when the card is tapped
                                        if (userEmail != null) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  DetailSportUserPage(
                                                userEmail:
                                                    userEmail, // Non-nullable due to the check
                                                sportName: selfRatingSport,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Card(
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
                                                    child: Image.network(
                                                        sportImage),
                                                  ),
                                                  SizedBox(width: 5),
                                                  Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.start,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
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

Widget commendationImage(String imageName, String name, double number) {
  return Column(
    children: [
      Image.asset(
        'assets/images/$imageName',
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          return Container(
            width: 80,
            height: 80,
            color: Colors.red,
            margin: EdgeInsets.all(5),
          );
        },
      ),
      Row(
        children: [
          Text('${number.toStringAsFixed(1)}'),
          Image.asset(
            'assets/images/star.png',
            width: 20,
            height: 20,
          ),
        ],
      ),
      Text(name),
    ],
  );
}
