import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityDetailsPage extends StatelessWidget {
  final String activityID;

  ActivityDetailsPage(this.activityID);

  void editActivity() {
    // Implement your edit action here
  }

  Future<void> removeActivity(String activityID, String activityType) async {
    try {
      // Get a reference to the Firestore collection for activities
      CollectionReference activities =
          FirebaseFirestore.instance.collection('activities');

      // Get a reference to the Firestore collection for participants
      if (activityType == 'Normal Activity') {
        CollectionReference participants =
            FirebaseFirestore.instance.collection('participants');
        QuerySnapshot participantSnapshot = await participants
            .where('activity_id', isEqualTo: activityID)
            .get();

        for (QueryDocumentSnapshot participant in participantSnapshot.docs) {
          await participants.doc(participant.id).delete();
        }
      } else {
        CollectionReference brackets =
            FirebaseFirestore.instance.collection('TournamentBracket');
        QuerySnapshot bracketSnapshot =
            await brackets.where('activity_id', isEqualTo: activityID).get();

        for (QueryDocumentSnapshot bracket in bracketSnapshot.docs) {
          await brackets.doc(bracket.id).delete();
        }
      }

      await activities.doc(activityID).delete();

      print('Activity removed successfully!');
    } catch (e) {
      // Handle errors here
      print('Error removing activity: $e');
    }
  }

  Future<void> addTournamentBracket(BuildContext context, String userEmail,
      String sportName, String activityID, String CreatorEmail) async {
    try {
      CollectionReference teams =
          FirebaseFirestore.instance.collection('teams');
      QuerySnapshot teamSnapshot = await teams
          .where('team_creator_email', isEqualTo: userEmail)
          .where('team_sport', isEqualTo: sportName)
          .get();

      if (teamSnapshot.docs.isNotEmpty) {
        String teamID = teamSnapshot.docs.first.id;
        print("masuk if 0");

        // Check if the team is already registered in TournamentBracket
        CollectionReference brackets =
            FirebaseFirestore.instance.collection('TournamentBracket');
        QuerySnapshot bracketSnapshot = await brackets
            .where('team_id', isEqualTo: teamID)
            .where('activity_id', isEqualTo: activityID)
            .get();

        if (bracketSnapshot.docs.isNotEmpty) {
          print("masuk if 1");
          // If the team is already registered, show a message to the user
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Already Registered'),
                content: Text('You have already registered for this activity.'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          // If the team is not registered, add a new TournamentBracket entry
          int bracketID = await getNextTournamentBracketID();
          print("masuk else");
          await brackets.doc(bracketID.toString()).set({
            'team_id': teamID,
            'activity_id': activityID,
            'bracket_slot': 0,
            'status': "Pending",
          });

          await updateLatestTournamentBracketID(bracketID);

          await FirebaseFirestore.instance.collection('notifications').add({
            'recipient_email': CreatorEmail,
            'message': '$userEmail has requested to join the activity.',
            'timestamp': FieldValue.serverTimestamp(),
            'category': 'Activity',
            'type': 'Request',
            'activityid': activityID,
            'bracketid': bracketID.toString(),
          });

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('You have requested to join the activity!'),
                content: Text('Please wait for host approval'),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Notice'),
              content: Text(
                  'You dont have a team for $sportName, or not a team leader'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Handle errors here
      print('Error adding tournament bracket: $e');
    }
  }

  Future<void> requestToJoinActivity(BuildContext context, String activityID,
      String userEmail, String CreatorEmail) async {
    try {
      bool isParticipant = await isUserParticipant(activityID, userEmail);

      if (!isParticipant) {
        CollectionReference participants =
            FirebaseFirestore.instance.collection('participants');

        int participantID = await getNextParticipantID();

        await participants.doc(participantID.toString()).set({
          'activity_id': activityID,
          'user_email': userEmail,
          'status': 'Pending',
        });

        await updateLatestParticipantID(participantID);

        // Create notification

        await FirebaseFirestore.instance.collection('notifications').add({
          'recipient_email': CreatorEmail,
          'message': '$userEmail has requested to join the activity.',
          'timestamp': FieldValue.serverTimestamp(),
          'category': 'Activity',
          'type': 'Request',
          'activityid': activityID,
          'participantid': participantID.toString(),
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('You have requested to join the activity!'),
              content: Text('Please wait for host approval'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Pending'),
              content:
                  Text('You have requested to join the activity, Please wait.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error adding participant: $e');
    }
  }

  Future<void> addParticipant(
      BuildContext context, String activityID, String userEmail) async {
    try {
      // Check if the user is already a participant
      bool isParticipant = await isUserParticipant(activityID, userEmail);

      if (!isParticipant) {
        // Get a reference to the participants collection
        CollectionReference participants =
            FirebaseFirestore.instance.collection('participants');

        // Get the next participant ID
        int participantID = await getNextParticipantID();

        // Add the participant
        await participants.doc(participantID.toString()).set({
          'activity_id': activityID,
          'user_email': userEmail,
          'status': 'Confirmed', // You can set an initial status if needed
        });

        await updateLatestParticipantID(participantID);

        // Show join confirmation popup
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('You are in the activity!'),
              content: Text('You have successfully joined the activity.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Already a Participant'),
              content: Text('You are already a participant in this activity.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Handle errors here
      print('Error adding participant: $e');
    }
  }

  Future<int> getNextParticipantID() async {
    // Assuming you have a separate collection for managing IDs
    CollectionReference idCollection =
        FirebaseFirestore.instance.collection('latest_participant_id');
    DocumentSnapshot snapshot = await idCollection.doc('latest_id').get();
    int latestID = snapshot.exists ? snapshot['id'] : 0;
    print(latestID);
    return latestID + 1;
  }

  Future<void> updateLatestParticipantID(int latestID) async {
    CollectionReference idCollection =
        FirebaseFirestore.instance.collection('latest_participant_id');
    await idCollection.doc('latest_id').set({'id': latestID});
  }

  Future<int> getNextTournamentBracketID() async {
    // Assuming you have a separate collection for managing IDs
    CollectionReference idCollection =
        FirebaseFirestore.instance.collection('latest_bracket_id');
    DocumentSnapshot snapshot = await idCollection.doc('latest_id').get();
    int latestID = snapshot.exists ? snapshot['id'] : 0;
    print(latestID);
    return latestID + 1;
  }

  Future<void> updateLatestTournamentBracketID(int latestID) async {
    CollectionReference idCollection =
        FirebaseFirestore.instance.collection('latest_bracket_id');
    await idCollection.doc('latest_id').set({'id': latestID});
  }

  Future<bool> isUserParticipant(String activityID, String userEmail) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('participants')
          .where('activity_id', isEqualTo: activityID)
          .where('user_email', isEqualTo: userEmail)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking participant status: $e');
      return false;
    }
  }

  String? userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Details'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        actions: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('activities')
                .doc(activityID)
                .snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              var activity = snapshot.data;

              if (activity == null || !activity.exists) {
                return SizedBox.shrink();
              }

              if (activity['user_email'] == userEmail) {
                return IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Settings'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit Activity'),
                                onTap: () {
                                  Navigator.pop(context);
                                  editActivity();
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.delete),
                                title: Text('Remove Activity'),
                                onTap: () {
                                  Navigator.pop(context);
                                  removeActivity(
                                      activityID, activity['activityType']);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }

              return SizedBox.shrink();
            },
          ),
        ],
      ),
      backgroundColor: Color.fromARGB(255, 230, 0, 0),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('activities')
                  .doc(activityID)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var activity = snapshot.data;

                if (activity == null || !activity.exists) {
                  return Center(child: Text('Activity not found'));
                }
                return Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.0),
                  margin: EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 3,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            alignment: Alignment.topLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Activity Name:'),
                                SizedBox(height: 10),
                                Text('Sport: '),
                                SizedBox(height: 10),
                                Text('Host: '),
                                SizedBox(height: 10),
                                Text('Location: '),
                                SizedBox(height: 10),
                                Text('Date: '),
                                SizedBox(height: 10),
                                Text('Time: '),
                                SizedBox(height: 10),
                                Text('Fee: '),
                                SizedBox(height: 10),
                                Text('Description: '),
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 10.0),
                            child: Container(
                              alignment: Alignment.topLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${activity['activityTitle']}'),
                                  SizedBox(height: 10),
                                  Text('${activity['sportName']}'),
                                  SizedBox(height: 10),
                                  Text('${activity['user_email']}'),
                                  SizedBox(height: 10),
                                  Text('${activity['activityLocation']}'),
                                  SizedBox(height: 10),
                                  Text('${activity['activityDate']}'),
                                  SizedBox(height: 10),
                                  Text('${activity['activityTime']}'),
                                  SizedBox(height: 10),
                                  Text('${activity['activityFee']}'),
                                  SizedBox(height: 10),
                                  Text('${activity['activityDescription']}'),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                      SizedBox(height: 16.0),
                      Text(
                        'Participants:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Column(
                        children: [
                          if (activity['activityType'] == "Normal Activity")
                            StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection('participants')
                                  .where('activity_id', isEqualTo: activityID)
                                  .where('status', isEqualTo: 'Confirmed')
                                  .snapshots(),
                              builder: (
                                BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot,
                              ) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                var participants = snapshot.data!.docs;

                                if (participants.isEmpty) {
                                  return Text(
                                      'No participants found for this activity.');
                                }

                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: participants
                                      .map((participant) =>
                                          FutureBuilder<DocumentSnapshot>(
                                            future: FirebaseFirestore.instance
                                                .collection('users')
                                                .doc(participant['user_email'])
                                                .get(),
                                            builder: (
                                              BuildContext context,
                                              AsyncSnapshot<DocumentSnapshot>
                                                  userSnapshot,
                                            ) {
                                              if (userSnapshot.hasError) {
                                                return Text(
                                                    'Error: ${userSnapshot.error}');
                                              }

                                              if (userSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return CircularProgressIndicator();
                                              }

                                              var user = userSnapshot.data;
                                              var profileImageUrl =
                                                  user?['profileImageUrl'];

                                              return CircleAvatar(
                                                radius: 20,
                                                backgroundImage: profileImageUrl !=
                                                            null &&
                                                        profileImageUrl
                                                            .isNotEmpty
                                                    ? NetworkImage(
                                                        profileImageUrl)
                                                    : AssetImage(
                                                            'assets/images/defaultprofile.png')
                                                        as ImageProvider,
                                              );
                                            },
                                          ))
                                      .toList(),
                                );
                              },
                            ),
                          if (activity['activityType'] == "Tournament" ||
                              activity['activityType'] == "Sparring")
                            StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .collection('TournamentBracket')
                                  .where('activity_id', isEqualTo: activityID)
                                  .where('status', isEqualTo: 'Confirmed')
                                  .snapshots(),
                              builder: (
                                BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot,
                              ) {
                                if (snapshot.hasError) {
                                  return Text('Error: ${snapshot.error}');
                                }

                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                var bracketDocuments = snapshot.data!.docs;

                                if (bracketDocuments.isEmpty) {
                                  return Text(
                                      'No participants found for this activity.');
                                }

                                return Column(
                                  children: bracketDocuments.map(
                                    (bracket) {
                                      String teamID = bracket['team_id'];
                                      return FutureBuilder<DocumentSnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('teams')
                                            .doc(teamID)
                                            .get(),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<DocumentSnapshot>
                                                teamSnapshot) {
                                          if (teamSnapshot.hasError) {
                                            return Text(
                                                'Error: ${teamSnapshot.error}');
                                          }

                                          if (teamSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          }

                                          var teamData = teamSnapshot.data;

                                          if (teamData == null ||
                                              !teamData.exists) {
                                            return Text('Team data not found');
                                          }

                                          return Text(teamData['team_name'],
                                              textAlign: TextAlign
                                                  .left); // Access the data you need from the 'teams' collection
                                        },
                                      );
                                    },
                                  ).toList(),
                                );
                              },
                            ),
                        ],
                      ),
                      Expanded(
                        child:
                            SizedBox(), // This SizedBox will take all available space
                      ),
                      Row(
                        children: [
                          Expanded(
                              child: ElevatedButton(
                            onPressed: () {
                              if (activity['activityisPrivate'] == true &&
                                  activity['activityType'] ==
                                      "Normal Activity") {
                                requestToJoinActivity(context, activityID,
                                    userEmail!, activity['user_email']);
                                print("private dan normal");
                              } else if (activity['activityisPrivate'] ==
                                      true &&
                                  (activity['activityType'] == "Tournament" ||
                                      activity['activityType'] == "Sparring")) {
                                addTournamentBracket(
                                    context,
                                    userEmail!,
                                    activity['sportName'],
                                    activityID,
                                    activity['user_email']);
                              } else {
                                addParticipant(context, activityID, userEmail!);
                              }
                            },
                            child: Text(
                              activity['activityisPrivate'] == true
                                  ? 'Request to Join'
                                  : 'Join Activity',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color.fromARGB(255, 230, 0, 0),
                            ),
                          )),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
