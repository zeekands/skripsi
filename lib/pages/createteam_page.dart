import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateTeamPage extends StatefulWidget {
  @override
  _CreateTeamPageState createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  TextEditingController teamNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String selectedCategory = '';

  Future<void> _showCreateTeamDialog(BuildContext context) async {
    int latestId = await FirebaseFirestore.instance
        .collection('latest_team_id')
        .doc('latest_id')
        .get()
        .then((value) => value.data()?['id'] ?? 0);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create Team'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: teamNameController,
                decoration: InputDecoration(labelText: 'Team Name'),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              CategoryDropdown(
                onCategoryChanged: (category) {
                  setState(() {
                    selectedCategory = category;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Rest of the code remains the same
                // You can access teamNameController.text for team name
                // and descriptionController.text for description
                // selectedCategory contains the selected category
                // Implement your logic here for creating the team
                // Make sure to update the latest team ID after creating the team
              },
              child: Text('Create Team'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Team'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showCreateTeamDialog(context),
          child: Text('Create Team'),
        ),
      ),
    );
  }
}

class CategoryDropdown extends StatefulWidget {
  final ValueChanged<String> onCategoryChanged;

  CategoryDropdown({required this.onCategoryChanged});

  @override
  _CategoryDropdownState createState() => _CategoryDropdownState();
}

class _CategoryDropdownState extends State<CategoryDropdown> {
  String selectedCategory = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sports').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        var sportsList = snapshot.data!.docs;
        List<DropdownMenuItem<String>> items = [];

        for (var sportDoc in sportsList) {
          String sportName = sportDoc['sport_name'];
          items.add(DropdownMenuItem(
            value: sportName,
            child: Text(sportName),
          ));
        }

        return DropdownButtonFormField<String>(
          value: selectedCategory.isEmpty ? items[0].value : selectedCategory,
          items: items,
          decoration: InputDecoration(labelText: 'Sport Category'),
          onChanged: (value) {
            setState(() {
              selectedCategory = value!;
            });
            widget.onCategoryChanged(value!);
          },
        );
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: CreateTeamPage(),
  ));
}
