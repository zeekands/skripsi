import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sportifyapp/pages/manageactivity_page.dart';
import 'package:sportifyapp/pages/result_page.dart';
import 'package:sportifyapp/pages/teamdetail_page.dart';
import 'package:sportifyapp/pages/tournamentbracket_page.dart';

import 'commendation_page.dart';
import 'editactivity_page.dart';
import 'otheruserProfile_page.dart';

class ActivityDetailsPage extends StatelessWidget {
  final String activityID;

  ActivityDetailsPage(this.activityID);

  void editActivity(
      BuildContext context, String activityId, String activityStatus) {
    if (activityStatus == 'Ongoing' || activityStatus == 'Completed') {
      // Show a dialog indicating that the activity cannot be edited
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cannot Edit Activity'),
            content: Text(
                'The activity is ongoing or completed and cannot be edited.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.black, // Set the text color to black
                  ),
                ),
              ),
            ],
          );
        },
      );
    } else {
      // Navigate to the EditActivityPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditActivityPage(activityId: activityId),
        ),
      );
    }
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

        CollectionReference brackets =
            FirebaseFirestore.instance.collection('TournamentBracket');
        QuerySnapshot bracketSnapshot = await brackets
            .where('team_id', isEqualTo: teamID)
            .where('activity_id', isEqualTo: activityID)
            .get();

        if (bracketSnapshot.docs.isNotEmpty) {
          print("masuk if 1");
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
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.black, // Set the text color to black
                      ),
                    ),
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
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.black, // Set the text color to black
                    ),
                  ),
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
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.black, // Set the text color to black
                    ),
                  ),
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
              title: Text(
                'Pending',
                style: TextStyle(
                  color: Colors.black, // Set the text color to black
                ),
              ),
              content:
                  Text('You have requested to join the activity, Please wait.'),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.black, // Set the text color to black
                    ),
                  ),
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

  String _formatFee(String fee) {
    // Convert the fee to an integer
    int? feeValue = int.tryParse(fee);

    // Check if the conversion is successful
    if (feeValue != null) {
      // Format the fee using NumberFormat
      String formattedFee = NumberFormat('#,###').format(feeValue);
      return formattedFee;
    } else {
      // Handle the case where activity['activityFee'] is not a valid number
      return 'Invalid Fee';
    }
  }

  Future<void> addParticipant(
      BuildContext context, String activityID, String userEmail) async {
    try {
      bool isParticipant = await isUserParticipant(activityID, userEmail);

      if (!isParticipant) {
        CollectionReference participants =
            FirebaseFirestore.instance.collection('participants');

        int participantID = await getNextParticipantID();

        await participants.doc(participantID.toString()).set({
          'activity_id': activityID,
          'user_email': userEmail,
          'status': 'Confirmed',
        });

        await updateLatestParticipantID(participantID);

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('You are in the activity!'),
              content: Text('You have successfully joined the activity.'),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.black, // Set the text color to black
                    ),
                  ),
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
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.black, // Set the text color to black
                    ),
                  ),
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
          // .where('status', isEqualTo: 'Confirmed')
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking participant status: $e');
      return false;
    }
  }

  Future<bool> isTeamParticipant(String activityID, String userEmail) async {
    try {
      // Check if the user has a team in team_members
      QuerySnapshot teamSnapshot = await FirebaseFirestore.instance
          .collection('team_members')
          .where('user_email', isEqualTo: userEmail)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      if (teamSnapshot.docs.isNotEmpty) {
        for (var doc in teamSnapshot.docs) {
          int teamID = doc['team_id'];
          String strTeamID = teamID.toString();
          print(teamID);

          // Check if the team is registered in Tournament Bracket
          QuerySnapshot bracketSnapshot = await FirebaseFirestore.instance
              .collection('TournamentBracket')
              .where('team_id', isEqualTo: strTeamID)
              .where('activity_id', isEqualTo: activityID)
              .where('status', isEqualTo: 'Confirmed')
              .get();

          if (bracketSnapshot.docs.isNotEmpty) {
            print('User\'s team is participating');
            return true; // User's team is participating
          }
        }
      }
      print('User doesn\'t have a team or team is not participating');
      return false; // User doesn't have a team or team is not participating
    } catch (e) {
      print('Error checking team participant status: $e');
      return false;
    }
  }

  Future<bool> isActivityFull(
      Future<int> participantCount, int activityQuota) async {
    int partiCount = await participantCount;
    return partiCount <= activityQuota;
  }

  Future<int> getParticipantCount(String activityID) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference participants =
          FirebaseFirestore.instance.collection('participants');

      // Query Firestore to get the number of participants for the provided activity ID
      QuerySnapshot snapshot =
          await participants.where('activity_id', isEqualTo: activityID).get();

      return snapshot.docs.length;
    } catch (e) {
      // Handle errors here
      print('Error fetching total participants: $e');
      return 0; // Return 0 in case of an error
    }
  }

  Future<void> updateActivityStatus(String newStatus, String activityID) async {
    try {
      // Get a reference to the activity document
      CollectionReference activities =
          FirebaseFirestore.instance.collection('activities');
      DocumentReference activityRef = activities.doc(activityID.toString());

      // Update the activity status
      await activityRef.update({'activityStatus': newStatus});
    } catch (e) {
      // Handle any errors that may occur during the update
      print('Error updating activity status: $e');
    }
  }

  Future<void> cancelJoin(BuildContext context, activityID, String? userEmail,
      String CreatorEmail) async {
    try {
      await FirebaseFirestore.instance
          .collection('participants')
          .where('activity_id', isEqualTo: activityID)
          .where('user_email', isEqualTo: userEmail)
          .get()
          .then((querySnapshot) {
        querySnapshot.docs.forEach((doc) {
          doc.reference.delete(); // Delete the document
        });
      });

      // Show a dialog to confirm the cancellation
      showDialog(
        context: context, // Make sure to have access to the BuildContext
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cancellation Successful'),
            content: Text(
                'You have successfully canceled your participation in this activity.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.black, // Set the text color to black
                  ),
                ),
              ),
            ],
          );
        },
      );

      // Update notifications collection in Firebase
      // await FirebaseFirestore.instance.collection('notifications').add({
      //   'message':
      //       '$userEmail has cancelled their participations in your activity $activityID',
      //   'recipient_email': CreatorEmail,
      //   'category': 'Activity',
      //   'activity_id': activityID,
      //   'type': 'Notice',
      //   'isRead': false,
      // });

      print('Successfully canceled join request for activity $activityID');
    } catch (error) {
      // Handle any errors that may occur during the cancellation process
      print('Error canceling join request: $error');
    }
  }

  Future<void> cancelJoinTournamentSparring(
      BuildContext context,
      String userEmail,
      String sportName,
      String activityID,
      String CreatorEmail) async {
    try {
      CollectionReference teams =
          FirebaseFirestore.instance.collection('teams');
      QuerySnapshot teamSnapshot = await teams
          .where('team_creator_email', isEqualTo: userEmail)
          .where('team_sport', isEqualTo: sportName)
          .get();

      if (teamSnapshot.docs.isNotEmpty) {
        String teamID = teamSnapshot.docs.first.id;

        CollectionReference brackets =
            FirebaseFirestore.instance.collection('TournamentBracket');
        QuerySnapshot bracketSnapshot = await brackets
            .where('team_id', isEqualTo: teamID)
            .where('activity_id', isEqualTo: activityID)
            .get();

        if (bracketSnapshot.docs.isNotEmpty) {
          String bracketID = bracketSnapshot.docs.first.id;

          // Delete the tournament bracket
          await brackets.doc(bracketID.toString()).delete();

          // Optionally, you may want to update other data or perform additional actions

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Cancellation Successful'),
                content: Text(
                    'You have successfully canceled your participation in this activity.'),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.black, // Set the text color to black
                      ),
                    ),
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
                title: Text('Bracket Not Found'),
                content: Text('No tournament bracket found for this activity.'),
                actions: <Widget>[
                  TextButton(
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.black, // Set the text color to black
                      ),
                    ),
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
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.black, // Set the text color to black
                    ),
                  ),
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
      print('Error deleting tournament bracket: $e');
    }
  }

  void navigateToManageActivityPage(
      BuildContext context, String activityID, String activityType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ManageActivityPage(
          activityID: activityID,
          activityType: activityType,
        ),
      ),
    );
  }

  Future<String> getUserName(String userEmail) async {
    try {
      // Assuming you have a 'users' collection in Firestore
      DocumentSnapshot<Map<String, dynamic>>? documentSnapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userEmail) // Assuming user_email is the document ID
              .get();

      if (documentSnapshot != null && documentSnapshot.exists) {
        // Assuming each user document has a 'name' field
        return documentSnapshot.data()?['name'] ?? 'Name not available';
      } else {
        return 'User not found'; // or handle this case accordingly
      }
    } catch (e) {
      print('Error getting user name: $e');
      return 'Error';
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
              print(activity?['activityStatus']);

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
                                  editActivity(context, activityID,
                                      activity['activityStatus']);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.group),
                                title: Text('Participant Management'),
                                onTap: () {
                                  Navigator.pop(
                                      context); // Close the current screen
                                  navigateToManageActivityPage(context,
                                      activityID, activity['activityType']);
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
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
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
                                  SizedBox(height: 10),
                                  if (activity['activityType'] == 'Tournament')
                                    Text('Registration Date: '),
                                  if (activity['activityType'] == 'Tournament')
                                    SizedBox(height: 10),
                                  Text('Status: '),
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
                                    FutureBuilder<String>(
                                      future:
                                          getUserName(activity['user_email']),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          return Text(
                                              'Error: ${snapshot.error}');
                                        } else {
                                          String hostName =
                                              snapshot.data ?? 'User not found';
                                          return Text(hostName);
                                        }
                                      },
                                    ),
                                    SizedBox(height: 10),
                                    Text('${activity['activityLocation']}'),
                                    SizedBox(height: 10),
                                    Text('${activity['activityDate']}'),
                                    SizedBox(height: 10),
                                    Text('${activity['activityTime']}'),
                                    SizedBox(height: 10),
                                    Text(
                                        'IDR ${_formatFee(activity['activityFee'])}'),
                                    SizedBox(height: 10),
                                    Text('${activity['activityDescription']}'),
                                    SizedBox(height: 10),
                                    if (activity['activityType'] ==
                                        'Tournament')
                                      Text(
                                          '${activity['registrationStart']} to ${activity['registrationEnd']}'),
                                    if (activity['activityType'] ==
                                        'Tournament')
                                      SizedBox(height: 10),
                                    Text('${activity['activityStatus']}'),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 6.0),
                      Visibility(
                        visible: activity['activityType'] == 'Tournament',
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TournamentBracketPage(
                                    activityId: activityID),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            primary: Color.fromARGB(
                                255, 230, 0, 0), // Set the background color
                            onPrimary: Colors.white, // Set the text color
                            minimumSize:
                                Size(double.infinity, 30), // Set the height
                          ),
                          child: Text('Tournament Bracket'),
                        ),
                      ),
                      SizedBox(height: 10.0),
                      Text(
                        'Participants:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (activity['activityType'] == "Normal Activity")
                                StreamBuilder(
                                  stream: FirebaseFirestore.instance
                                      .collection('participants')
                                      .where('activity_id',
                                          isEqualTo: activityID)
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

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: participants
                                          .map((participant) =>
                                              FutureBuilder<DocumentSnapshot>(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection('users')
                                                    .doc(participant[
                                                        'user_email'])
                                                    .get(),
                                                builder: (
                                                  BuildContext context,
                                                  AsyncSnapshot<
                                                          DocumentSnapshot>
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

                                                  return GestureDetector(
                                                    onTap: () async {
                                                      DocumentSnapshot
                                                          userSnapshot =
                                                          await FirebaseFirestore
                                                              .instance
                                                              .collection(
                                                                  'users')
                                                              .doc(participant[
                                                                  'user_email'])
                                                              .get();

                                                      Map<String, dynamic>
                                                          userData =
                                                          userSnapshot.data()
                                                              as Map<String,
                                                                  dynamic>;

                                                      // Navigate to other user's profile page
                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              OtherUserProfilePage(
                                                            userData: userData,
                                                            userEmail:
                                                                participant[
                                                                    'user_email'],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.all(4),
                                                      child: Column(
                                                        children: [
                                                          CircleAvatar(
                                                            backgroundImage: profileImageUrl
                                                                    .isNotEmpty
                                                                ? NetworkImage(
                                                                    profileImageUrl)
                                                                : AssetImage(
                                                                        'assets/images/defaultprofile.png')
                                                                    as ImageProvider,
                                                            radius: 26,
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            user!['name'],
                                                            maxLines: 2,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
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
                                      .where('activity_id',
                                          isEqualTo: activityID)
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

                                    return Row(
                                      children: bracketDocuments.map(
                                        (bracket) {
                                          String teamID = bracket['team_id'];
                                          return FutureBuilder<
                                              DocumentSnapshot>(
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

                                              if (teamSnapshot
                                                      .connectionState ==
                                                  ConnectionState.waiting) {
                                                return CircularProgressIndicator();
                                              }

                                              var teamData = teamSnapshot.data;

                                              if (teamData == null ||
                                                  !teamData.exists) {
                                                return Text(
                                                    'Team data not found');
                                              }

                                              var teamImageUrl =
                                                  teamData['teamImageUrl'];
                                              var teamName =
                                                  teamData['team_name'];
                                              var teamId = teamData['team_id'];
                                              var teamSport =
                                                  teamData['team_sport'];
                                              var teamCreator = teamData[
                                                  'team_creator_email'];
                                              var teamDes =
                                                  teamData['team_description'];
                                              var winCount =
                                                  teamData['winCount'];

                                              return GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          TeamDetailPage(
                                                        teamName: teamName,
                                                        teamId: teamId,
                                                        teamSport: teamSport,
                                                        teamCreator:
                                                            teamCreator,
                                                        teamImageUrl:
                                                            teamImageUrl,
                                                        teamDes: teamDes,
                                                        winCount: winCount,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Padding(
                                                  padding: EdgeInsets.all(4),
                                                  child: Column(
                                                    children: [
                                                      CircleAvatar(
                                                        backgroundImage: teamImageUrl
                                                                .isNotEmpty
                                                            ? NetworkImage(
                                                                teamImageUrl)
                                                            : AssetImage(
                                                                    'assets/images/defaultTeam.png')
                                                                as ImageProvider,
                                                        radius: 26,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        teamData['team_name'],
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ).toList(),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            SizedBox(), // This SizedBox will take all available space
                      ),
                      FutureBuilder<bool>(
                        future: activity['activityType'] == 'Normal Activity'
                            ? isUserParticipant(activityID, userEmail!)
                            : isTeamParticipant(activityID, userEmail!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator(); // Show loading indicator while waiting for the result.
                          } else if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          } else {
                            bool isParticipant = snapshot.data ?? false;

                            if (!isParticipant) {
                              Future<int> participantCount =
                                  getParticipantCount(activityID);
                              return FutureBuilder<int>(
                                future: participantCount,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (snapshot.hasError) {
                                    return Text('Error: ${snapshot.error}');
                                  } else {
                                    int count = snapshot.data ?? 0;

                                    if (count >= activity['activityQuota']) {
                                      return SizedBox(
                                        height: 30,
                                      );
                                    }
                                    return SizedBox(
                                      height: 30,
                                      child: activity['activityStatus'] ==
                                              'Waiting'
                                          ? ElevatedButton(
                                              onPressed: () {
                                                if (activity[
                                                            'activityisPrivate'] ==
                                                        true &&
                                                    activity['activityType'] ==
                                                        "Normal Activity") {
                                                  requestToJoinActivity(
                                                    context,
                                                    activityID,
                                                    userEmail!,
                                                    activity['user_email'],
                                                  );
                                                  print("private dan normal");
                                                } else if (activity[
                                                            'activityisPrivate'] ==
                                                        true &&
                                                    (activity['activityType'] ==
                                                            "Tournament" ||
                                                        activity[
                                                                'activityType'] ==
                                                            "Sparring")) {
                                                  addTournamentBracket(
                                                    context,
                                                    userEmail!,
                                                    activity['sportName'],
                                                    activityID,
                                                    activity['user_email'],
                                                  );
                                                } else {
                                                  addParticipant(context,
                                                      activityID, userEmail!);
                                                }
                                              },
                                              child: Text(
                                                activity['activityisPrivate'] ==
                                                        true
                                                    ? 'Request to Join'
                                                    : 'Join Activity',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color.fromARGB(
                                                    255, 230, 0, 0),
                                                minimumSize:
                                                    Size(double.infinity, 0),
                                              ),
                                            )
                                          : Container(), // If activityStatus is not 'Waiting', return an empty container.
                                    );
                                  }
                                },
                              );
                            } else {
                              // If the user is already a participant
                              if (activity['user_email'] == userEmail) {
                                if (activity['activityStatus'] == 'Waiting') {
                                  return SizedBox(
                                    height: 30,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        updateActivityStatus(
                                            'Ongoing', activityID);
                                      },
                                      child: Text('Ongoing'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        minimumSize: Size(double.infinity, 0),
                                      ),
                                    ),
                                  );
                                } else if (activity['activityStatus'] ==
                                    'Ongoing') {
                                  return SizedBox(
                                    height: 30,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        updateActivityStatus(
                                            'Completed', activityID);
                                      },
                                      child: Text('Completed'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        minimumSize: Size(double.infinity, 0),
                                      ),
                                    ),
                                  );
                                }
                              } else if (activity['activityStatus'] ==
                                  'Waiting') {
                                return SizedBox(
                                  height: 30,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Add code to handle canceling the join request
                                      // This could be a function similar to updateActivityStatus
                                      if (activity['activityType'] ==
                                          'Normal Activity') {
                                        cancelJoin(context, activityID,
                                            userEmail, activity['user_email']);
                                      } else {
                                        print('not normal');
                                        cancelJoinTournamentSparring(
                                            context,
                                            userEmail!,
                                            activity['sportName'],
                                            activityID,
                                            activity['user_email']);
                                      }
                                    },
                                    child: Text('Cancel Join'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors
                                          .red, // You can choose a color for cancellation
                                      minimumSize: Size(double.infinity, 0),
                                    ),
                                  ),
                                );
                              }
                              if (activity['activityStatus'] == 'Completed' &&
                                  activity['activityType'] ==
                                      'Normal Activity') {
                                return SizedBox(
                                  height: 30,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CommendationPage(activityID),
                                        ),
                                      );
                                    },
                                    child: Text('Give Commendation'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      minimumSize: Size(double.infinity, 0),
                                    ),
                                  ),
                                );
                              }
                              if (activity['activityStatus'] == 'Completed' &&
                                  activity['activityType'] == 'Sparring') {
                                return SizedBox(
                                  height: 30,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ResultPage(activityID),
                                        ),
                                      );
                                    },
                                    child: Text('Result'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      minimumSize: Size(double.infinity, 0),
                                    ),
                                  ),
                                );
                              }
                              if (activity['activityStatus'] == 'Completed' &&
                                  activity['activityType'] == 'Tournament') {
                                return SizedBox(
                                    // height: 30,
                                    // child: ElevatedButton(
                                    //   onPressed: () {
                                    //     Navigator.push(
                                    //       context,
                                    //       MaterialPageRoute(
                                    //         builder: (context) =>
                                    //             CommendationPage(activityID),
                                    //       ),
                                    //     );
                                    //   },
                                    //   child: Text('Give Commendation'),
                                    //   style: ElevatedButton.styleFrom(
                                    //     backgroundColor: Colors.orange,
                                    //     minimumSize: Size(double.infinity, 0),
                                    //   ),
                                    // ),
                                    );
                              }

                              return SizedBox(
                                height: 30,
                                child: ElevatedButton(
                                  onPressed:
                                      null, // This will make the button non-functional
                                  child: Text(
                                      'You already requested to join this activity'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    minimumSize: Size(double.infinity, 0),
                                  ),
                                ),
                              );
                              // If none of the conditions are met, return an empty SizedBox
                              // If none of the conditions are met, return an empty SizedBox
                            }
                          }
                        },
                      )
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
