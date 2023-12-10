import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTeamMemberPage extends StatefulWidget {
  final int teamId;

  ManageTeamMemberPage({required this.teamId});

  @override
  _ManageTeamMemberPageState createState() => _ManageTeamMemberPageState();
}

class _ManageTeamMemberPageState extends State<ManageTeamMemberPage> {
  Future<void> removeUserFromTeam(String userEmail) async {
    // Check if the user is the creator of the team
    bool isCreator = await checkIfUserIsCreator(userEmail);

    // Show different dialogs based on whether the user is the creator
    if (isCreator) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Remove User'),
            content: Text(
              'You cannot remove yourself as the team creator. Please ask another team member to remove you.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
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
      // Show the regular removal confirmation dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Remove User'),
            content: Text(
              'Are you sure you want to remove ${userEmail} from the team?',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.black, // Set the text color to black
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await removeMember(userEmail);
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text(
                  'Remove',
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
  }

  Future<void> removeMember(String userEmail) async {
    // Add the logic to remove the user from the team here
    // For example, you can delete the team member document from the 'team_members' collection
    await FirebaseFirestore.instance
        .collection('team_members')
        .where('team_id', isEqualTo: widget.teamId)
        .where('user_email', isEqualTo: userEmail)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        snapshot.docs.first.reference.delete();
      }
    });
  }

  Future<bool> checkIfUserIsCreator(String userEmail) async {
    try {
      // Query the teams collection to check if the user is the creator
      var teamSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId.toString())
          .get();

      if (teamSnapshot.exists) {
        var teamData = teamSnapshot.data() as Map<String, dynamic>;
        return teamData['team_creator_email'] == userEmail;
      } else {
        // Handle the case where the team with the specified ID does not exist
        return false;
      }
    } catch (e) {
      // Handle errors
      print('Error checking if user is creator: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Team Members'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance
            .collection('team_members')
            .where('team_id', isEqualTo: widget.teamId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No team members found'));
          }

          List<DocumentSnapshot> teamMembers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: teamMembers.length,
            itemBuilder: (context, index) {
              var memberData =
                  teamMembers[index].data() as Map<String, dynamic>;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(memberData['user_email'])
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (userSnapshot.hasError) {
                    return Text('Error: ${userSnapshot.error}');
                  }
                  if (!userSnapshot.hasData) {
                    return SizedBox(); // Handle empty data
                  }

                  var userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;

                  return ListTile(
                    title: Text(userData['name']), // Display user's name
                    leading: CircleAvatar(
                      backgroundImage: userData['profileImageUrl'] != null
                          ? NetworkImage(userData['profileImageUrl'])
                          : AssetImage('assets/images/defaultprofile.png')
                              as ImageProvider,
                    ), // Display user's profile image
                    // Add more information if needed
                    trailing: IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        removeUserFromTeam(memberData['user_email']);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
