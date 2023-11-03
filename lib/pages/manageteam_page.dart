import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageTeamMemberPage extends StatefulWidget {
  final int teamId;

  ManageTeamMemberPage({required this.teamId});

  @override
  _ManageTeamMemberPageState createState() => _ManageTeamMemberPageState();
}

class _ManageTeamMemberPageState extends State<ManageTeamMemberPage> {
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
