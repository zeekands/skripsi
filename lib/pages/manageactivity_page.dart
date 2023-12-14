import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageActivityPage extends StatelessWidget {
  final String activityID;
  final String activityType;

  ManageActivityPage({required this.activityID, required this.activityType});

  Future<List<Map<String, dynamic>>> getParticipants() async {
    try {
      if (activityType == 'Normal Activity') {
        var participantsSnapshot = await FirebaseFirestore.instance
            .collection('participants')
            .where('activity_id', isEqualTo: activityID)
            .where('status', isEqualTo: 'Confirmed')
            .get();

        return await Future.wait(
            participantsSnapshot.docs.map((participantDoc) async {
          var user_email = participantDoc['user_email'] as String;

          // Query users collection for additional information
          var userSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user_email)
              .get();

          if (userSnapshot.exists) {
            var userData = userSnapshot.data() as Map<String, dynamic>;

            return {
              'user_email': user_email,
              'name': userData['name'] as String,
              'profileImageUrl': userData['profileImageUrl'] as String,
              'teamID': '0' as String,
            };
          } else {
            return {};
          }
        }));
      } else if (activityType == 'Tournament' || activityType == 'Sparring') {
        print("masuk elseif");
        var bracketSnapshot = await FirebaseFirestore.instance
            .collection('TournamentBracket')
            .where('activity_id', isEqualTo: activityID)
            .get();

        if (bracketSnapshot.docs.isNotEmpty) {
          var participants = <Map<String, dynamic>>[];

          for (var doc in bracketSnapshot.docs) {
            var teamId = doc['team_id'] as String;
            print('spar not empty');

            // Query teams collection for additional information
            var teamSnapshot = await FirebaseFirestore.instance
                .collection('teams')
                .doc(teamId)
                .get();

            if (teamSnapshot.exists) {
              var teamData = teamSnapshot.data() as Map<String, dynamic>;
              print(teamData);
              print('masuk');

              participants.add({
                'user_email': teamData['team_creator_email'] as String,
                'name': teamData['team_name'] as String,
                'profileImageUrl': teamData['teamImageUrl'] as String,
                'teamID': teamData['team_id'] as int,
              });
            }
          }

          return participants;
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      print('Error retrieving participants: $e');
      return [];
    }
  }

  Future<void> removeParticipant(
      BuildContext context, String userEmail, String teamID) async {
    try {
      // Check if the user trying to remove is the host
      var isHost = await checkIfUserIsHost(userEmail);
      print('$isHost + useremail $userEmail');
      print('teamid :$teamID');

      if (isHost) {
        // Show a dialog to inform the host that they cannot remove themselves
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Cannot Remove Host'),
              content: Text('You cannot remove yourself as the host.'),
              actions: [
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
      } else {
        // Show a confirmation dialog for removing the participant
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Confirm Removal'),
              content:
                  Text('Are you sure you want to remove this participant?'),
              actions: [
                TextButton(
                  onPressed: () {
                    // Perform the removal action here
                    // Example: deleteParticipant(userEmail);

                    // Close the dialog
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: Colors.black, // Set the text color to black
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (activityType == 'Normal Activity') {
                      deleteParticipant(activityID, userEmail);
                    } else if (activityType == 'Tournament') {
                      deleteSparringParticipant(activityID, teamID);
                    } else if (activityType == 'Sparring') {
                      deleteSparringParticipant(activityID, teamID);
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Yes',
                    style: TextStyle(
                      color: Colors.black, // Set the text color to black
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('Error removing participant: $e');
    }
  }

  Future<void> deleteTournamentParticipant(
      String activityID, String userEmail) async {
    // Implement deletion logic for Tournament
  }

  Future<void> deleteSparringParticipant(
      String activityID, String teamID) async {
    print('$activityID team$teamID');
    try {
      var participantsCollection =
          FirebaseFirestore.instance.collection('TournamentBracket');

      // Query for the participant document to delete
      var participantDoc = await participantsCollection
          .where('activity_id', isEqualTo: activityID)
          .where('team_id', isEqualTo: teamID)
          .get();

      // Check if the document exists before attempting to delete
      if (participantDoc.docs.isNotEmpty) {
        // Delete the participant document
        await participantsCollection.doc(participantDoc.docs.first.id).delete();

        print('Participant $teamID removed successfully');
      } else {
        print('Participant $teamID not found');
      }
    } catch (e) {
      print('Error removing participant: $e');
    }
  }

  Future<void> deleteParticipant(String activityID, String userEmail) async {
    try {
      var participantsCollection =
          FirebaseFirestore.instance.collection('participants');

      // Query for the participant document to delete
      var participantDoc = await participantsCollection
          .where('activity_id', isEqualTo: activityID)
          .where('user_email', isEqualTo: userEmail)
          .get();

      // Check if the document exists before attempting to delete
      if (participantDoc.docs.isNotEmpty) {
        // Delete the participant document
        await participantsCollection.doc(participantDoc.docs.first.id).delete();

        print('Participant $userEmail removed successfully');
      } else {
        print('Participant $userEmail not found');
      }
    } catch (e) {
      print('Error removing participant: $e');
    }
  }

  Future<bool> checkIfUserIsHost(String userEmail) async {
    try {
      // Query the activities collection to get the host email for the given activityID
      var activitySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .doc(activityID)
          .get();

      if (activitySnapshot.exists) {
        var hostEmail = activitySnapshot['user_email'] as String;
        print('$hostEmail + $userEmail');

        // Compare the provided userEmail with the host email
        return userEmail == hostEmail;
      } else {
        // Handle the case where the activity doesn't exist
        return false;
      }
    } catch (e) {
      // Handle any errors that may occur during the query
      print('Error checking if user is host: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: getParticipants(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Participant Management'),
              backgroundColor: Color.fromARGB(255, 230, 0, 0),
            ),
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Participant Management'),
              backgroundColor: Color.fromARGB(255, 230, 0, 0),
            ),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          List<Map<String, dynamic>> participants = snapshot.data ?? [];

          return Scaffold(
            appBar: AppBar(
              title: Text('Participant Management'),
              backgroundColor: Color.fromARGB(255, 230, 0, 0),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // SizedBox(height: 20),
                  if (participants.isEmpty)
                    Text('No participants for this activity.')
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: participants.length,
                        itemBuilder: (context, index) {
                          var participant = participants[index];

                          return ListTile(
                            title: Text(participant['name']),
                            subtitle: Text(participant['user_email']),
                            leading: CircleAvatar(
                              backgroundImage: participant['profileImageUrl'] !=
                                          null &&
                                      participant['profileImageUrl'].isEmpty
                                  ? NetworkImage(participant['profileImageUrl'])
                                  : AssetImage(
                                          'assets/images/defaultprofile.png')
                                      as ImageProvider,
                            ),

                            trailing: IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                removeParticipant(
                                    context,
                                    participant['user_email'],
                                    participant['teamID'].toString());
                              },
                            ),
                            // You can customize the ListTile based on your participant data
                            // For example, you might want to show participant details or actions
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
