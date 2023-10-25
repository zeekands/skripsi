import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Container(
            // margin: const EdgeInsets.all(4.0),
            color: Colors.white,
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.label,
              indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  color: Colors.redAccent),
              controller: _tabController,
              tabs: [
                Tab(
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: Colors.redAccent, width: 1)),
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
                        border: Border.all(color: Colors.redAccent, width: 1)),
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
                        border: Border.all(color: Colors.redAccent, width: 1)),
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
                        border: Border.all(color: Colors.redAccent, width: 1)),
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          InboxTab(category: 'All', currentUserEmail: currentUserEmail),
          InboxTab(category: 'Activity', currentUserEmail: currentUserEmail),
          InboxTab(category: 'Team', currentUserEmail: currentUserEmail),
          InboxTab(category: 'Friends', currentUserEmail: currentUserEmail),
        ],
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

            // Now you can call showTeamMemberDialog2 here
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Join Request'),
                  content:
                      Text('$requestEmail has requested to join $teamName'),
                  actions: <Widget>[
                    TextButton(
                      child: Text('Accept'),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('team_members')
                            .doc(teamMemberId)
                            .update({'status': 'Confirmed'}).then((value) {
                          print('Request accepted');
                          // Optionally, you may want to remove the notification or mark it as accepted.
                          // This depends on your specific use case.
                          // For example:
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
                      child: Text('Decline'),
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
                      child: Text('Close'),
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
        print('Document does not exist');
      }
    }).catchError((error) {
      print('Error getting document: $error');
    });
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
            var notificationId = notifications[index].id;

            return Card(
              child: ListTile(
                title: Text(title),
                subtitle: Text(message),
                onTap: () {
                  if (type == 'Request' && title == 'Team') {
                    showTeamMemberDialog(context, teamMemberId, notificationId);
                  } else
                    showNotificationDetails(context, title, message);
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
