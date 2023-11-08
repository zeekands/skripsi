import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'editteam_page.dart';
import 'manageteam_page.dart';
import 'otheruserProfile_page.dart';

class TeamDetailPage extends StatefulWidget {
  final String teamName;
  final int teamId;
  final String teamSport;
  final String teamCreator;
  final String teamImageUrl;
  final String teamDes;

  TeamDetailPage({
    required this.teamName,
    required this.teamId,
    required this.teamSport,
    required this.teamCreator,
    required this.teamImageUrl,
    required this.teamDes,
  });

  @override
  _TeamDetailPageState createState() => _TeamDetailPageState();
}

class _TeamDetailPageState extends State<TeamDetailPage> {
  bool isCurrentUserMember = false;
  bool isCurrentUserAlreadyInTeam = false;

  @override
  void initState() {
    super.initState();
    checkMembership();
  }

  void checkMembership() async {
    var userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      var snapshot = await FirebaseFirestore.instance
          .collection('team_members')
          .where('team_id', isEqualTo: widget.teamId)
          .where('user_email', isEqualTo: userEmail)
          .get();

      setState(() {
        isCurrentUserMember = snapshot.docs.isNotEmpty;
      });

      var userTeamSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('team_sport', isEqualTo: widget.teamSport)
          .where('team_creator_email', isEqualTo: userEmail)
          .get();

      setState(() {
        isCurrentUserAlreadyInTeam = userTeamSnapshot.docs.isNotEmpty;
      });
    }
  }

  void requestToJoinTeam() async {
    var userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      if (!isCurrentUserMember && !isCurrentUserAlreadyInTeam) {
        // Send a request to join the team
        var teamMemberRef =
            await FirebaseFirestore.instance.collection('team_members').add({
          'team_id': widget.teamId,
          'user_email': userEmail,
          'status': 'Pending', // Set an initial status
        });

        String teamMemberId = teamMemberRef.id;

        await FirebaseFirestore.instance.collection('notifications').add({
          'recipient_email': widget.teamCreator,
          'message':
              '$userEmail has requested to join your team "${widget.teamName}".',
          'timestamp': FieldValue.serverTimestamp(),
          'category': 'Team',
          'type': 'Request',
          'teammemberid': teamMemberId,
        });

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Request Sent'),
              content: Text('Your request to join has been sent.'),
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
              title: Text('Already In Team'),
              content: Text(
                  'You are already a member of this team or have a team for this sport.'),
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
    }
  }

  void editTeam() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditTeamPage(
          teamName: widget.teamName,
          teamId: widget.teamId,
          teamSport: widget.teamSport,
          teamCreator: widget.teamCreator,
          teamDescription: widget.teamDes,
          teamImageUrl: widget.teamImageUrl,
        ),
      ),
    );
  }

  void ManageTeamMember() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManageTeamMemberPage(
          teamId: widget.teamId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var userEmail = FirebaseAuth.instance.currentUser?.email;
    String? teamUrl = widget.teamImageUrl;
    return Scaffold(
      appBar: AppBar(
        title: Text('Team Details'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        actions: [
          if (userEmail ==
              widget.teamCreator) // Check if current user is team creator
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  editTeam();
                } else if (value == 'manageMembers') {
                  ManageTeamMember();
                } else if (value == 'Leaveteam') {
                  // leaveTeam();
                }
              },
              itemBuilder: (BuildContext context) {
                if (userEmail == widget.teamCreator) {
                  return {'edit', 'manageMembers'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(
                          choice == 'edit' ? 'Edit Team' : 'Manage Members'),
                    );
                  }).toList();
                } else {
                  return {'Leaveteam'}.map((String choice) {
                    return PopupMenuItem<String>(
                      value: choice,
                      child: Text(choice),
                    );
                  }).toList();
                }
              },
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 64,
                backgroundImage: teamUrl != null && teamUrl.isNotEmpty
                    ? NetworkImage(teamUrl)
                    : AssetImage('assets/images/defaultTeam.png')
                        as ImageProvider,
              ),
            ),
            Text(
              'Team Name: ${widget.teamName}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text('Team ID: ${widget.teamId}', style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text('Team Sport: ${widget.teamSport}',
                style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Text(
              'Members:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              // margin: const EdgeInsets.only(right: 20.0),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('team_members')
                    .where('team_id', isEqualTo: widget.teamId)
                    .where('status', isEqualTo: 'Confirmed') // Add this filter
                    .snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }

                  var teamMembers = snapshot.data!.docs;

                  if (teamMembers.isEmpty) {
                    return Text('No members yet.');
                  }

                  return Expanded(
                    child: ListView.builder(
                      itemCount: (teamMembers.length / 2).ceil(),
                      itemBuilder: (context, index) {
                        int startIndex = index * 2;
                        int endIndex = startIndex + 2;
                        if (endIndex > teamMembers.length) {
                          endIndex = teamMembers.length;
                        }

                        return Row(
                          children: teamMembers
                              .sublist(startIndex, endIndex)
                              .map((teamMember) {
                            String userEmail = teamMember['user_email'];
                            return FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userEmail)
                                  .get(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<DocumentSnapshot>
                                      userSnapshot) {
                                if (userSnapshot.hasError) {
                                  return Text('Error: ${userSnapshot.error}');
                                }

                                if (userSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                if (!userSnapshot.hasData) {
                                  return SizedBox(); // Handle empty data
                                }

                                var userData = userSnapshot.data!.data()
                                    as Map<String, dynamic>;

                                return GestureDetector(
                                  onTap: () {
                                    // Navigate to other user's profile page
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OtherUserProfilePage(
                                          userData: userData,
                                          userEmail: userEmail,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: userData[
                                                        'profileImageUrl'] !=
                                                    null &&
                                                userData['profileImageUrl']
                                                    .isNotEmpty
                                            ? NetworkImage(
                                                userData['profileImageUrl'])
                                            : AssetImage(
                                                    'assets/images/defaultprofile.png')
                                                as ImageProvider,
                                        radius: 26,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        userData['name'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  );
                },
              ),
            ),

            // Display "Request to Join" button if the user is not a member
            if (!isCurrentUserMember)
              Expanded(
                child:
                    SizedBox(), // This SizedBox will take all available space
              ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: requestToJoinTeam,
                    child: Text('Request to Join'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 230, 0, 0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
