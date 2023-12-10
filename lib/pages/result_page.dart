import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResultPage extends StatelessWidget {
  final String activityID;

  ResultPage(this.activityID);

  Future<bool> _isCurrentUserHost() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      String currentUserEmail = currentUser.email ?? '';
      DocumentSnapshot activitySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .doc(activityID)
          .get();

      if (activitySnapshot.exists) {
        Map<String, dynamic> activityData =
            activitySnapshot.data() as Map<String, dynamic>;

        String activityUserEmail = activityData['user_email'] ?? '';

        return currentUserEmail == activityUserEmail;
      }
    }

    return false;
  }

  Future<bool> haveResult(String activityID) async {
    try {
      var result = await FirebaseFirestore.instance
          .collection('sparringResult')
          .where('activity_id', isEqualTo: activityID)
          .get();

      return result.docs.isNotEmpty;
    } catch (error) {
      print('Error checking for result: $error');
      return false;
    }
  }

  Future<void> _showUpdateResultDialog(
      BuildContext context, String activityID) async {
    TextEditingController team1ScoreController = TextEditingController();
    TextEditingController team2ScoreController = TextEditingController();

    QuerySnapshot bracketSnapshot = await FirebaseFirestore.instance
        .collection('TournamentBracket')
        .where('activity_id', isEqualTo: activityID)
        .get();

    if (bracketSnapshot.docs.length < 2) {
      // Show a dialog indicating that the result cannot be updated
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Cannot Update Result'),
            content: Text('There are not enough teams to update the result.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    String team1Id = bracketSnapshot.docs[0]['team_id'];
    String team2Id = bracketSnapshot.docs[1]['team_id'];

    DocumentSnapshot team1Doc =
        await FirebaseFirestore.instance.collection('teams').doc(team1Id).get();

// Query team information for team2
    DocumentSnapshot team2Doc =
        await FirebaseFirestore.instance.collection('teams').doc(team2Id).get();

    String team1Name = team1Doc['team_name'];
    String team2Name = team2Doc['team_name'];

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Result'),
          content: Column(
            children: [
              Text('Enter the new scores for both teams:'),
              SizedBox(height: 10),
              TextField(
                controller: team1ScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: '$team1Name Score',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    )),
              ),
              SizedBox(height: 10),
              TextField(
                controller: team2ScoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: '$team2Name Score',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                // Validate and update the result
                if (team1ScoreController.text.isNotEmpty &&
                    team2ScoreController.text.isNotEmpty) {
                  int team1Score = int.parse(team1ScoreController.text);
                  int team2Score = int.parse(team2ScoreController.text);
                  await _updateResult(team1Id, team2Id, team1Score, team2Score);
                  Navigator.of(context).pop(); // Close the dialog
                }
              },
              child: Text('Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 230, 0, 0),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateResult(
      String team1, String team2, int team1score, int team2score) async {
    // Assume you have variables for team1_id, team2_id, team1_score, and team2_score
    String team1_id = team1;
    String team2_id = team2;
    int team1_score = team1score; // Replace with the actual score
    int team2_score = team2score; // Replace with the actual score

    // Create a new document in the sparringResult collection
    await FirebaseFirestore.instance.collection('sparringResult').add({
      'activity_id': activityID,
      'team1_id': team1_id,
      'team2_id': team2_id,
      'team1_score': team1_score,
      'team2_score': team2_score,
    });

    // Update the win count for the winning team
    if (team1_score > team2_score) {
      await _updateWinCount(team1_id);
    } else if (team2_score > team1_score) {
      await _updateWinCount(team2_id);
    }
  }

  Future<void> _updateWinCount(String teamId) async {
    // Query the teams collection for the specified teamId
    QuerySnapshot teamQuery = await FirebaseFirestore.instance
        .collection('teams')
        .where(FieldPath.documentId, isEqualTo: teamId)
        .get();

    // Check if the team exists
    if (teamQuery.docs.isNotEmpty) {
      DocumentSnapshot teamDoc = teamQuery.docs.first;
      int currentWinCount = teamDoc['winCount'] ?? 0;

      // Update the win count in the teams collection
      await teamDoc.reference.update({
        'winCount': currentWinCount + 1,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Result Page'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('TournamentBracket')
                  .where('activity_id', isEqualTo: activityID)
                  .get(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var brackets = snapshot.data!.docs;

                if (brackets.isEmpty) {
                  return Center(
                    child: Text('No results available for this activity.'),
                  );
                }

                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('sparringResult')
                      .where('activity_id', isEqualTo: activityID)
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> sparringResultSnapshot) {
                    if (sparringResultSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (sparringResultSnapshot.hasError) {
                      return Center(
                        child: Text('Error: ${sparringResultSnapshot.error}'),
                      );
                    }

                    var sparringResultDocs = sparringResultSnapshot.data?.docs;

                    if (sparringResultDocs != null &&
                        sparringResultDocs.isNotEmpty) {
                      // Assuming each document in sparringResult corresponds to a match
                      return Center(
                        child: ListView.builder(
                          itemCount: sparringResultDocs.length,
                          itemBuilder: (BuildContext context, int index) {
                            var team1Id = sparringResultDocs[index]['team1_id'];
                            var team2Id = sparringResultDocs[index]['team2_id'];
                            var team1Score =
                                sparringResultDocs[index]['team1_score'];
                            var team2Score =
                                sparringResultDocs[index]['team2_score'];

                            return Container(
                              margin: EdgeInsets.symmetric(vertical: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Team 1
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('teams')
                                        .doc(team1Id)
                                        .get(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<DocumentSnapshot>
                                            team1Snapshot) {
                                      if (team1Snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }

                                      if (team1Snapshot.hasError) {
                                        return Text(
                                            'Error: ${team1Snapshot.error}');
                                      }

                                      var team1 = team1Snapshot.data?.data()
                                          as Map<String, dynamic>?;

                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 64,
                                              backgroundImage: team1![
                                                              'teamImageUrl'] !=
                                                          null &&
                                                      team1['teamImageUrl']
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                      team1['teamImageUrl'])
                                                  : AssetImage(
                                                          'assets/images/defaultTeam.png')
                                                      as ImageProvider,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '${team1?['team_name'] ?? 'Unknown'}',
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Team 1 Score: $team1Score',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),

                                  // Team 2
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('teams')
                                        .doc(team2Id)
                                        .get(),
                                    builder: (BuildContext context,
                                        AsyncSnapshot<DocumentSnapshot>
                                            team2Snapshot) {
                                      if (team2Snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      }

                                      if (team2Snapshot.hasError) {
                                        return Text(
                                            'Error: ${team2Snapshot.error}');
                                      }

                                      var team2 = team2Snapshot.data?.data()
                                          as Map<String, dynamic>?;

                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 64,
                                              backgroundImage: team2![
                                                              'teamImageUrl'] !=
                                                          null &&
                                                      team2['teamImageUrl']
                                                          .isNotEmpty
                                                  ? NetworkImage(
                                                      team2['teamImageUrl'])
                                                  : AssetImage(
                                                          'assets/images/defaultTeam.png')
                                                      as ImageProvider,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '${team2?['team_name'] ?? 'Unknown'}',
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Team 2 Score: $team2Score',
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    } else {
                      return Center(
                        child: Text('No match data available.'),
                      );
                    }
                  },
                );
              },
            ),
          ),
          FutureBuilder<bool>(
            future: _isCurrentUserHost(),
            builder: (context, hostSnapshot) {
              if (hostSnapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              }

              if (hostSnapshot.hasError) {
                return Text('Error: ${hostSnapshot.error}');
              }

              if (hostSnapshot.data == true) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        bool hasResult = await haveResult(activityID);

                        if (hasResult) {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Activity Result'),
                                content:
                                    Text('This activity already has results.'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          _showUpdateResultDialog(context, activityID);
                        }
                      },
                      child: Text('Update Result'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 230, 0, 0),
                      ),
                    ),
                  ),
                );
              } else {
                return SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }
}
