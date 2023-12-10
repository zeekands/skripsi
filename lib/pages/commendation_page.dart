import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommendationPage extends StatefulWidget {
  final String activityID;

  CommendationPage(this.activityID);

  @override
  _CommendationPageState createState() => _CommendationPageState();
}

class _CommendationPageState extends State<CommendationPage> {
  List<int> commendationCounts = [0, 0, 0, 0];
  String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

  void _showCommendationDialog(BuildContext context, String userEmail) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CommendationDialog(
          userEmail: userEmail,
          onCountsChanged: (List<int> newCounts) {
            setState(() {
              commendationCounts = newCounts;
            });
          },
          submitCommendations: (List<int> newCounts) {
            _submitCommendations(userEmail, newCounts);
          },
        );
      },
    );
  }

  Future<String?> getActivitySport(String activityID) async {
    try {
      var activitySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .doc(activityID)
          .get();

      if (activitySnapshot.exists) {
        var activityData = activitySnapshot.data() as Map<String, dynamic>;
        var activitySport = activityData['sportName'] as String?;

        return activitySport;
      } else {
        // Activity with the provided ID doesn't exist
        return null;
      }
    } catch (e) {
      // Handle any errors that occurred during the process
      print('Error getting activity sport: $e');
      return null;
    }
  }

  void _submitCommendations(String toUser, List<int> commendationCounts) async {
    int commendation1 = commendationCounts[0];
    int commendation2 = commendationCounts[1];
    int commendation3 = commendationCounts[2];
    int commendation4 = commendationCounts[3];

    // Check if commendation already exists
    QuerySnapshot commendationQuery = await FirebaseFirestore.instance
        .collection('commendations')
        .where('fromUser', isEqualTo: currentUserEmail)
        .where('toUser', isEqualTo: toUser)
        .where('activity_id', isEqualTo: widget.activityID)
        .get();

    if (commendationQuery.docs.isNotEmpty) {
      print('You have already commended this user for this activity.');
      return;
    }
    String? activitySport = await getActivitySport(widget.activityID);

    FirebaseFirestore.instance.collection('commendations').add({
      'toUser': toUser,
      'fromUser': currentUserEmail,
      'activity_id': widget.activityID,
      'commendation1': commendation1,
      'commendation2': commendation2,
      'commendation3': commendation3,
      'commendation4': commendation4,
      'activitySport': activitySport ?? "",
    });
  }

  Future<bool> isUserCommended(String userEmail) async {
    try {
      // Check if commendation already exists
      var commendationQuery = await FirebaseFirestore.instance
          .collection('commendations')
          .where('fromUser', isEqualTo: currentUserEmail)
          .where('toUser', isEqualTo: userEmail)
          .where('activity_id', isEqualTo: widget.activityID)
          .get();

      return commendationQuery.docs.isNotEmpty;
    } catch (e) {
      // Handle any errors that occurred during the process
      print('Error checking commendation: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Give Commendation'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: SingleChildScrollView(
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('participants')
              .where('activity_id', isEqualTo: widget.activityID)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Text('No participants found for this activity.');
            }

            var participants = snapshot.data!.docs;

            return Column(
              children: participants
                  .map<Widget>((doc) {
                    var userEmail = doc['user_email'];

                    if (userEmail == currentUserEmail) {
                      return SizedBox.shrink();
                    }
                    return FutureBuilder(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(userEmail)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        }

                        if (!userSnapshot.hasData) {
                          return Text('No user data found.');
                        }

                        var userData = userSnapshot.data!;
                        var userName = userData['name'];
                        var touserEmail = userSnapshot.data!.id;
                        var profileImageUrl = userData['profileImageUrl'];
                        var userAge = userData['age'];

                        return GestureDetector(
                          onTap: () {
                            _showCommendationDialog(context, touserEmail);
                          },
                          child: FutureBuilder(
                            future: isUserCommended(touserEmail),
                            builder: (context, isCommendedSnapshot) {
                              if (isCommendedSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              }

                              var isCommended =
                                  isCommendedSnapshot.data as bool? ?? false;

                              return Card(
                                margin: EdgeInsets.all(16.0),
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: profileImageUrl !=
                                                            null &&
                                                        profileImageUrl
                                                            .isNotEmpty
                                                    ? NetworkImage(
                                                        profileImageUrl)
                                                    : AssetImage(
                                                            'assets/images/defaultprofile.png')
                                                        as ImageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 5),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                userName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
                                                ),
                                              ),
                                              SizedBox(height: 2),
                                              Text(userAge),
                                            ],
                                          ),
                                        ],
                                      ),
                                      // Display checklist icon if user is commended
                                      isCommended
                                          ? Icon(
                                              Icons.check,
                                              color: Colors.green,
                                            )
                                          : SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  })
                  .where((widget) => widget != null)
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}

class CommendationDialog extends StatefulWidget {
  final String userEmail;
  final ValueChanged<List<int>> onCountsChanged;
  final ValueChanged<List<int>> submitCommendations;

  CommendationDialog({
    required this.userEmail,
    required this.onCountsChanged,
    required this.submitCommendations,
  });

  @override
  _CommendationDialogState createState() => _CommendationDialogState();
}

class _CommendationDialogState extends State<CommendationDialog> {
  List<int> commendationCounts = [0, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Give Commendation to ${widget.userEmail}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
            child: Column(
              children: [
                commendationImage('skillfull.png', 'Skillfull', 0),
                commendationImage('friendly.png', 'Positive', 1),
                commendationImage('teamplayer.png', 'Teamwork', 2),
                commendationImage('sportmanship.png', 'Sportsmanship', 3),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () {
                  widget.onCountsChanged(commendationCounts);
                  widget.submitCommendations(commendationCounts);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Submit',
                  style: TextStyle(
                    color: Colors.black, // Set the text color to black
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black, // Set the text color to black
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget commendationImage(String imageName, String name, int index) {
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4.0),
        child: Container(
          padding: EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Column(
            children: [
              Text(name),
              Image.asset(
                'assets/images/$imageName',
                width: 45,
                height: 45,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.red,
                    margin: EdgeInsets.all(5),
                  );
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () {
                      if (commendationCounts[index] > 0) {
                        setState(() {
                          commendationCounts[index] -= 1;
                        });
                      }
                    },
                  ),
                  Row(
                    children: [
                      Text('${commendationCounts[index]}'),
                      Image.asset(
                        'assets/images/star.png',
                        width: 20,
                        height: 20,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: () {
                      if (commendationCounts[index] < 5) {
                        setState(() {
                          commendationCounts[index] += 1;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
