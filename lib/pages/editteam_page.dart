import 'package:flutter/material.dart';

class EditTeamPage extends StatelessWidget {
  final String teamName;
  final int teamId;
  final String teamSport;
  final String teamCreator;

  EditTeamPage({
    required this.teamName,
    required this.teamId,
    required this.teamSport,
    required this.teamCreator,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Team'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: teamName,
              decoration: InputDecoration(labelText: 'Team Name'),
              // Add logic to update team name
            ),
            TextFormField(
              initialValue: teamSport,
              decoration: InputDecoration(labelText: 'Team Sport'),
              // Add logic to update team sport
            ),
            TextFormField(
              initialValue: teamId.toString(),
              decoration: InputDecoration(labelText: 'Team ID'),
              enabled: false,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add logic to save changes
                Navigator.pop(context); // Navigate back after saving
              },
              child: Text('Save Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color.fromARGB(255, 230, 0, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
