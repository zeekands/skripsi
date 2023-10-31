import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'editteam_page.dart';

class TeamDetailPage extends StatefulWidget {
  final String teamName;
  final int teamId;
  final String teamSport;
  final String teamCreator;

  TeamDetailPage({
    required this.teamName,
    required this.teamId,
    required this.teamSport,
    required this.teamCreator,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var userEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: Text('Team Details'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        actions: [
          if (userEmail ==
              widget.teamCreator) // Check if current user is team creator
            IconButton(
              icon: Icon(Icons.settings), // Add settings icon
              onPressed: editTeam,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    child: ListView(
                      children: teamMembers.map((teamMember) {
                        String userEmail = teamMember['user_email'];
                        return ListTile(
                          title: Text(userEmail),
                        );
                      }).toList(),
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
