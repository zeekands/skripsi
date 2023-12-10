import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sportifyapp/pages/teamdetail_page.dart';

class InboxPage extends StatefulWidget {
  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  String currentUserEmail = FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.only(top: 5.0),
        child: Column(
          children: [
            PreferredSize(
              preferredSize: Size.fromHeight(50),
              child: Container(
                color: Colors.transparent,
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color: Color.fromARGB(255, 230, 0, 0),
                  ),
                  controller: _tabController,
                  tabs: [
                    Tab(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Color.fromARGB(255, 230, 0, 0),
                            width: 1,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "All",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Color.fromARGB(255, 230, 0, 0),
                            width: 1,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Activity",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Color.fromARGB(255, 230, 0, 0),
                            width: 1,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Team",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    Tab(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Color.fromARGB(255, 230, 0, 0),
                            width: 1,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: Text(
                            "Friend",
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  InboxTab(category: 'All', currentUserEmail: currentUserEmail),
                  InboxTab(
                      category: 'Activity', currentUserEmail: currentUserEmail),
                  InboxTab(
                      category: 'Team', currentUserEmail: currentUserEmail),
                  InboxTab(
                      category: 'Friend', currentUserEmail: currentUserEmail),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InboxTab extends StatelessWidget {
  final String category;
  final String currentUserEmail;

  InboxTab({required this.category, required this.currentUserEmail});

  void showNotificationDetails(
      BuildContext context, String title, String message) {
    // The function we defined earlier.
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void handleRequestAction(bool accept, String teamMemberId, String teamId) {
    if (accept) {
      // Accept the request
      FirebaseFirestore.instance
          .collection('team_members')
          .doc(teamMemberId)
          .update({'status': 'Confirmed'}).then((value) {
        print('Request accepted');
        // Optionally, you may want to remove the notification or mark it as accepted.
        // This depends on your specific use case.
        // For example:
        // FirebaseFirestore.instance
        //     .collection('notifications')
        //     .doc(teamMemberId)
        //     .delete();
      }).catchError((error) {
        print('Error accepting request: $error');
      });
    } else {
      // Decline the request
      // Delete notification or mark it as declined
    }
  }

  void handleActivityRequestAction(
      bool accept, String participantId, String activityId) {
    if (accept) {
      // Accept the request
      FirebaseFirestore.instance
          .collection('participants')
          .doc(participantId)
          .update({'status': 'Confirmed'}).then((value) {
        print('Request accepted');
        // Optionally, you may want to remove the notification or mark it as accepted.
        // This depends on your specific use case.
        // For example:
        // FirebaseFirestore.instance
        //     .collection('notifications')
        //     .doc(teamMemberId)
        //     .delete();
      }).catchError((error) {
        print('Error accepting request: $error');
      });
    } else {
      // Decline the request
      // Delete notification or mark it as declined
    }
  }

  void showTeamMemberDialog(
      BuildContext context, String teamMemberId, String notificationId) {
    FirebaseFirestore.instance
        .collection('team_members')
        .doc(teamMemberId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        String requestEmail = data['user_email'];
        int teamId = data['team_id'];
        String status = data['status'];
        print('User Email: $requestEmail, Team ID: $teamId, Status: $status');

        FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId.toString())
            .get()
            .then((DocumentSnapshot teamDocumentSnapshot) {
          if (teamDocumentSnapshot.exists) {
            Map<String, dynamic> teamData =
                teamDocumentSnapshot.data() as Map<String, dynamic>;
            String teamName = teamData['team_name'];
            String teamSport = teamData['team_sport'];
            String teamCreatorEmail = teamData['team_creator_email'];
            print(
                'Team Name: $teamName, Sport: $teamSport, Creator Email: $teamCreatorEmail');

            // Fetch user data
            FirebaseFirestore.instance
                .collection('users')
                .doc(requestEmail) // Use requestEmail to get user data
                .get()
                .then((DocumentSnapshot userSnapshot) {
              if (userSnapshot.exists) {
                Map<String, dynamic> userData =
                    userSnapshot.data() as Map<String, dynamic>;
                String profileImageUrl = userData['profileImageUrl'];

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Center(child: Text('Join Request')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                backgroundImage: profileImageUrl != null &&
                                        profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : AssetImage(
                                            'assets/images/defaultprofile.png')
                                        as ImageProvider,
                                radius: 26,
                              ),
                              Text(
                                ">>",
                                style: TextStyle(fontSize: 24),
                              ),
                              CircleAvatar(
                                backgroundImage:
                                    teamData['teamImageUrl'] != null &&
                                            teamData['teamImageUrl'].isNotEmpty
                                        ? NetworkImage(teamData['teamImageUrl'])
                                        : AssetImage(
                                                'assets/images/defaultTeam.png')
                                            as ImageProvider,
                                radius: 26,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Container(
                            child: Text(
                              '$requestEmail has requested to join $teamName',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            'Accept',
                            style: TextStyle(
                              color:
                                  Colors.black, // Set the text color to black
                            ),
                          ),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('team_members')
                                .doc(teamMemberId)
                                .update({'status': 'Confirmed'}).then((value) {
                              print('Request accepted');
                              FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notificationId)
                                  .delete();
                            }).catchError((error) {
                              print('Error accepting request: $error');
                            });
                            Navigator.of(context).pop(); // Close the dialog
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Decline',
                            style: TextStyle(
                              color:
                                  Colors.black, // Set the text color to black
                            ),
                          ),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('team_members')
                                .doc(teamMemberId)
                                .delete()
                                .then((value) {
                              print('Request declined');
                              FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notificationId)
                                  .delete();
                            }).catchError((error) {
                              print('Error declining request: $error');
                            });
                            Navigator.of(context).pop(); // Close the dialog
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color:
                                  Colors.black, // Set the text color to black
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
                print('User Document does not exist');
              }
            });
          } else {
            print('Team Document does not exist');
          }
        }).catchError((error) {
          print('Error getting team document: $error');
        });
      } else {
        print('Document does not exist');
      }
    }).catchError((error) {
      print('Error getting document: $error');
    });
  }

  void showActivityRequestDialog(
      BuildContext context, String participantId, String notificationId) {
    FirebaseFirestore.instance
        .collection('participants')
        .doc(participantId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        String requestEmail = data['user_email'];
        String activityId = data['activity_id'];
        String status = data['status'];
        print(
            'User Email: $requestEmail, Activity ID: $activityId, Status: $status');

        FirebaseFirestore.instance
            .collection('activities')
            .doc(activityId)
            .get()
            .then((DocumentSnapshot activityDocumentSnapshot) {
          if (activityDocumentSnapshot.exists) {
            Map<String, dynamic> activityData =
                activityDocumentSnapshot.data() as Map<String, dynamic>;
            String activityTitle = activityData['activityTitle'];
            String activitySport = activityData['sportName'];
            String activityCreatorEmail = activityData['user_email'];
            print(
                'Activity Title: $activityTitle, Sport: $activitySport, Creator Email: $activityCreatorEmail');

            // Fetch user data
            FirebaseFirestore.instance
                .collection('users')
                .doc(requestEmail) // Use requestEmail to get user data
                .get()
                .then((DocumentSnapshot userSnapshot) {
              if (userSnapshot.exists) {
                Map<String, dynamic> userData =
                    userSnapshot.data() as Map<String, dynamic>;
                String profileImageUrl = userData['profileImageUrl'];

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Center(child: Text('Join Request')),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                backgroundImage: profileImageUrl != null &&
                                        profileImageUrl.isNotEmpty
                                    ? NetworkImage(profileImageUrl)
                                    : AssetImage(
                                            'assets/images/defaultprofile.png')
                                        as ImageProvider,
                                radius: 26,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Container(
                            child: Text(
                              '$requestEmail has requested to join your activity $activityTitle',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            'Accept',
                            style: TextStyle(
                              color:
                                  Colors.black, // Set the text color to black
                            ),
                          ),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('participants')
                                .doc(participantId)
                                .update({'status': 'Confirmed'}).then((value) {
                              print('Request accepted');
                              FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notificationId)
                                  .delete();
                            }).catchError((error) {
                              print('Error accepting request: $error');
                            });
                            Navigator.of(context).pop(); // Close the dialog
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Decline',
                            style: TextStyle(
                              color:
                                  Colors.black, // Set the text color to black
                            ),
                          ),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('participants')
                                .doc(participantId)
                                .delete()
                                .then((value) {
                              print('Request declined');
                              FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notificationId)
                                  .delete();
                            }).catchError((error) {
                              print('Error declining request: $error');
                            });
                            Navigator.of(context).pop(); // Close the dialog
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color:
                                  Colors.black, // Set the text color to black
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
                print('User Document does not exist');
              }
            });
          } else {
            print('Activity Document does not exist');
          }
        }).catchError((error) {
          print('Error getting activity document: $error');
        });
      } else {
        print('Document does not exist');
      }
    }).catchError((error) {
      print('Error getting document: $error');
    });
  }

  void showActivityRequestDialog2(
      BuildContext context, String bracketId, String notificationId) {
    FirebaseFirestore.instance
        .collection('TournamentBracket')
        .doc(bracketId)
        .get()
        .then((DocumentSnapshot documentSnapshot) {
      if (documentSnapshot.exists) {
        Map<String, dynamic> data =
            documentSnapshot.data() as Map<String, dynamic>;
        String requestTeam = data['team_id'];
        String activityId = data['activity_id'];
        String status = data['status'];
        print(
            'Team ID: $requestTeam, Activity ID: $activityId, Status: $status');

        FirebaseFirestore.instance
            .collection('activities')
            .doc(activityId)
            .get()
            .then((DocumentSnapshot activityDocumentSnapshot) {
          if (activityDocumentSnapshot.exists) {
            Map<String, dynamic> activityData =
                activityDocumentSnapshot.data() as Map<String, dynamic>;
            String activityTitle = activityData['activityTitle'];
            String activitySport = activityData['sportName'];
            String activityCreatorEmail = activityData['user_email'];
            print(
                'Activity Title: $activityTitle, Sport: $activitySport, Creator Email: $activityCreatorEmail');

            FirebaseFirestore.instance
                .collection('teams')
                .doc(requestTeam)
                .get()
                .then((DocumentSnapshot teamDocumentSnapshot) {
              if (teamDocumentSnapshot.exists) {
                Map<String, dynamic> teamData =
                    teamDocumentSnapshot.data() as Map<String, dynamic>;
                String teamImageUrl = teamData['teamImageUrl'];
                String teamName = teamData['team_name'];
                int teamID = int.parse(requestTeam);
                String teamSport = teamData['team_sport'];
                String teamCreator = teamData['team_creator_email'];
                String teamDes = teamData['team_description'];
                int winCount = teamData['winCount'];

                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Center(child: Text('Join Request')),
                      content: Column(
                        mainAxisSize: MainAxisSize
                            .min, // Make the column take the minimum vertical space needed
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TeamDetailPage(
                                    teamName: teamName,
                                    teamId: teamID,
                                    teamSport: teamSport,
                                    teamCreator: teamCreator,
                                    teamImageUrl: teamImageUrl,
                                    teamDes: teamDes,
                                    winCount: winCount,
                                  ),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  backgroundImage: teamImageUrl != null &&
                                          teamImageUrl.isNotEmpty
                                      ? NetworkImage(teamImageUrl)
                                      : AssetImage(
                                              'assets/images/defaultTeam.png')
                                          as ImageProvider,
                                  radius: 26,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                              height:
                                  8), // Add a small vertical space between the Row and the Text
                          Container(
                            child: Text(
                              '$requestTeam has requested to join your activity $activityTitle',
                              textAlign: TextAlign.center, // Center the text
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text(
                            'Accept',
                            style: TextStyle(
                              color:
                                  Colors.black, // Set the text color to black
                            ),
                          ),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('TournamentBracket')
                                .doc(bracketId)
                                .update({'status': 'Confirmed'}).then((value) {
                              print('Request accepted');
                              FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notificationId)
                                  .delete();
                            }).catchError((error) {
                              print('Error accepting request: $error');
                            });
                            Navigator.of(context).pop(); // Close the dialog
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Decline',
                            style: TextStyle(
                              color:
                                  Colors.black, // Set the text color to black
                            ),
                          ),
                          onPressed: () {
                            FirebaseFirestore.instance
                                .collection('TournamentBracket')
                                .doc(bracketId)
                                .delete()
                                .then((value) {
                              print('Request declined');
                              FirebaseFirestore.instance
                                  .collection('notifications')
                                  .doc(notificationId)
                                  .delete();
                            }).catchError((error) {
                              print('Error declining request: $error');
                            });
                            Navigator.of(context).pop(); // Close the dialog
                          },
                        ),
                        TextButton(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color:
                                  Colors.black, // Set the text color to black
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
                print('Team Document does not exist');
              }
            }).catchError((error) {
              print('Error getting team document: $error');
            });
          } else {
            print('Activity Document does not exist');
          }
        }).catchError((error) {
          print('Error getting activity document: $error');
        });
      } else {
        print('Document does not exist');
      }
    }).catchError((error) {
      print('Error getting document: $error');
    });
  }

  void showFriendRequestDialog(
      BuildContext context, String fromUserEmail, String notificationId) async {
    try {
      // Fetch user data using await
      DocumentSnapshot userDocumentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUserEmail) // Use doc method to reference the document by ID
          .get();

      if (userDocumentSnapshot.exists) {
        Map<String, dynamic> userData =
            userDocumentSnapshot.data() as Map<String, dynamic>;
        String profileImageUrl = userData['profileImageUrl'];
        String profileName = userData['name'];

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Center(child: Text('Friend Request')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundImage:
                        profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : AssetImage('assets/images/defaultprofile.png')
                                as ImageProvider,
                    radius: 26,
                  ),
                  SizedBox(height: 8),
                  Container(
                    child: Text(
                      '$profileName has sent you a friend request.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(
                    'Accept',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () async {
                    String currentUserEmail =
                        FirebaseAuth.instance.currentUser?.email ?? '';

                    // Update the friend list for the sender (fromUserEmail)
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(fromUserEmail)
                        .update({
                      'friends': FieldValue.arrayUnion([currentUserEmail])
                    });

                    // Update the friend list for the current user
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUserEmail)
                        .update({
                      'friends': FieldValue.arrayUnion([fromUserEmail])
                    });

                    // Handle friend request acceptance
                    // Perform the necessary operations, e.g., update the friends list
                    // and delete the notification
                    // ...

                    // Delete the notification
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(notificationId)
                        .delete();

                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
                TextButton(
                  child: Text(
                    'Decline',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  onPressed: () async {
                    // Handle friend request decline
                    // Perform the necessary operations, e.g., delete the notification
                    // ...

                    // Delete the notification
                    await FirebaseFirestore.instance
                        .collection('notifications')
                        .doc(notificationId)
                        .delete();

                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
                TextButton(
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.black,
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
        print('User document not found');
      }
    } catch (error) {
      print('Error getting user document: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> notificationsStream;

    if (category == 'All') {
      notificationsStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('recipient_email', isEqualTo: currentUserEmail)
          .snapshots();
    } else {
      notificationsStream = FirebaseFirestore.instance
          .collection('notifications')
          .where('category', isEqualTo: category)
          .where('recipient_email', isEqualTo: currentUserEmail)
          .snapshots();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: notificationsStream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var notifications = snapshot.data!.docs;

        if (notifications.isEmpty) {
          return Center(child: Text('No notifications found.'));
        }

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (BuildContext context, int index) {
            var notificationData =
                notifications[index].data() as Map<String, dynamic>;
            var title = notificationData['category'];
            var type = notificationData['type'];
            var message = notificationData['message'];
            var teamMemberId = notificationData['teammemberid'];
            var participantId = notificationData['participantid'];
            var bracketId = notificationData['bracketid'];
            var fromUserEmail = notificationData['from_user'];

            var notificationId = notifications[index].id;

            return Card(
              child: ListTile(
                title: Text(title),
                subtitle: Text(message),
                onTap: () {
                  if (type == 'Request' && title == 'Team') {
                    showTeamMemberDialog(context, teamMemberId, notificationId);
                  }
                  if (type == 'Request' && title == 'Activity') {
                    if (participantId != null) {
                      print("masuk prticipant");
                      showActivityRequestDialog(
                          context, participantId, notificationId);
                    } else {
                      print(bracketId);
                      showActivityRequestDialog2(
                          context, bracketId, notificationId);
                    }
                  }
                  if (type == 'Request' && title == 'Friend') {
                    showFriendRequestDialog(
                        context, fromUserEmail, notificationId);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: InboxPage(),
  ));
}
