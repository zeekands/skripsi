import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sportifyapp/pages/teamdetail_page.dart';

class TeamPage extends StatefulWidget {
  @override
  _TeamPageState createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Team'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'My Team'),
            Tab(text: 'Teams'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MyTeamTab(),
          TeamsTab(),
        ],
      ),
    );
  }
}

Future<void> createTeamMember(String userEmail, int teamId) async {
  try {
    await FirebaseFirestore.instance.collection('team_members').add(
        {'user_email': userEmail, 'team_id': teamId, 'status': 'Confirmed'});
    print('Team member created successfully!');
  } catch (e) {
    print('Error creating team member: $e');
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
            child: CircularProgressIndicator(), // Loading indicator
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
          value: selectedCategory.isEmpty
              ? items[0].value
              : selectedCategory, // Set initial value
          items: items,
          decoration: InputDecoration(labelText: 'Sport Category'),
          onChanged: (value) {
            setState(() {
              selectedCategory = value!;
            });
            widget.onCategoryChanged(value!); // Add this line
          },
        );
      },
    );
  }
}

Future<void> _showCreateTeamDialog(BuildContext context) async {
  TextEditingController teamNameController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String selectedCategory = '';

  await FirebaseFirestore.instance
      .collection('latest_team_id')
      .doc('latest_id')
      .get()
      .then((value) {
    int latestId = value.data()?['id'] ?? 0;

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
                decoration: InputDecoration(
                  labelText: 'Team Name',
                ),
              ),
              TextFormField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              CategoryDropdown(
                onCategoryChanged: (category) {
                  selectedCategory = category; // Update selectedCategory
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () async {
                // Rest of the code remains the same
              },
              child: Text(
                'Create Team',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  });
}

class MyTeamTab extends StatefulWidget {
  @override
  _MyTeamTabState createState() => _MyTeamTabState();
}

class _MyTeamTabState extends State<MyTeamTab> {
  String selectedCategory = '';
  String? userEmail = FirebaseAuth.instance.currentUser?.email;
  InputDecoration buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      border: OutlineInputBorder(),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black, width: 2.0),
      ),
      labelStyle: TextStyle(color: Colors.black),
    );
  }

  void _showCreateTeamDialog(BuildContext context) {
    TextEditingController teamNameController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    FirebaseFirestore.instance
        .collection('latest_team_id')
        .doc('latest_id')
        .get()
        .then((value) {
      int latestId = value.data()?['id'] ?? 0;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Create Team'),
            content: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: teamNameController,
                    decoration: buildInputDecoration('Team Name'),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: descriptionController,
                    decoration: buildInputDecoration('Description'),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2.0),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: CategoryDropdown(
                      onCategoryChanged: (category) {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              TextButton(
                onPressed: () async {
                  String teamName = teamNameController.text;
                  String description = descriptionController.text;

                  if (teamName.isNotEmpty && description.isNotEmpty) {
                    QuerySnapshot teamQuery = await FirebaseFirestore.instance
                        .collection('teams')
                        .where('team_sport', isEqualTo: selectedCategory)
                        .where('team_creator_email', isEqualTo: userEmail)
                        .get();

                    if (teamQuery.docs.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Cannot create team'),
                            content: Text(
                                'You already have a team for this category.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text(
                                  'OK',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                      return;
                    } else {
                      latestId++;

                      String teamId = latestId.toString();
                      FirebaseFirestore.instance
                          .collection('teams')
                          .doc(teamId)
                          .set({
                        'team_id': latestId,
                        'team_name': teamName,
                        'team_description': description,
                        'team_sport': selectedCategory,
                        'team_creator_email': userEmail,
                        'teamImageUrl': "",
                        'winCount': 0,
                      });

                      FirebaseFirestore.instance
                          .collection('latest_team_id')
                          .doc('latest_id')
                          .set({'id': latestId});

                      if (userEmail != null) {
                        await createTeamMember(userEmail!, latestId);
                      }

                      Navigator.of(context).pop();
                    }
                  }
                },
                child: Text(
                  'Create Team',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _showCreateTeamDialog(context),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              'Create Team',
              style: TextStyle(fontSize: 20),
            ),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 0),
            backgroundColor: Color.fromARGB(255, 145, 145, 145),
            padding: const EdgeInsets.all(5),
          ),
        ),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('team_members')
              .where('user_email', isEqualTo: userEmail)
              .where('status', isEqualTo: 'Confirmed')
              .get(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(), // Loading indicator
              );
            }

            var teamMembers = snapshot.data!.docs;

            return Column(
              children: teamMembers.map((teamMember) {
                int teamId = teamMember['team_id'];

                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('teams')
                      .doc(teamId.toString())
                      .snapshots(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> teamSnapshot) {
                    if (teamSnapshot.hasError) {
                      return Text('Error: ${teamSnapshot.error}');
                    }

                    if (teamSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(), // Loading indicator
                      );
                    }

                    var teamData =
                        teamSnapshot.data!.data() as Map<String, dynamic>;

                    return Card(
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TeamDetailPage(
                                teamName: teamData['team_name'],
                                teamId: teamId,
                                teamSport: teamData['team_sport'],
                                teamCreator: teamData['team_creator_email'],
                                teamImageUrl: teamData!['teamImageUrl'],
                                teamDes: teamData!['team_description'],
                                winCount: teamData['winCount'],
                                // Add more details as needed
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 60, // Adjust the size as needed
                              height: 60, // Adjust the size as needed
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: teamData!['teamImageUrl'] != null &&
                                          teamData!['teamImageUrl'].isNotEmpty
                                      ? NetworkImage(teamData!['teamImageUrl'])
                                      : AssetImage(
                                              'assets/images/defaultTeam.png')
                                          as ImageProvider,
                                ),
                              ),
                            ),
                            SizedBox(
                                width:
                                    16), // Add some space between the containers
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${teamData['team_name']}',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text('${teamData['team_sport']}',
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class TeamsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('sports').snapshots(),
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<QueryDocumentSnapshot> sportsList = snapshot.data!.docs;
          List<Tab> tabs = [];
          List<Widget> tabContents = [];

          for (var sportDoc in sportsList) {
            String sportName = sportDoc['sport_name'];
            String sportImage = sportDoc['sport_image'];
            tabs.add(Tab(icon: Image.network(sportImage)));
            tabContents.add(TabContent(sportName: sportName));
          }

          return DefaultTabController(
            length: tabs.length,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      color: Color.fromARGB(255, 230, 0, 0),
                    ),
                    tabs: tabs.map((tab) {
                      return Tab(
                        icon: Container(
                          // decoration: BoxDecoration(
                          //   borderRadius: BorderRadius.circular(50),
                          //   border:
                          //       Border.all(color: Colors.redAccent, width: 1),
                          // ),
                          child: tab.icon,
                        ),
                      );
                    }).toList(),
                    // labelColor: Colors.white,
                    // indicatorColor: Colors.white,
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: tabContents,
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}

class TabContent extends StatelessWidget {
  final String sportName;

  TabContent({required this.sportName});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: FirebaseFirestore.instance
          .collection('teams')
          .where('team_sport', isEqualTo: sportName)
          .get(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.data!.docs.isNotEmpty) {
          List<QueryDocumentSnapshot> teamsList = snapshot.data!.docs;
          return ListView.builder(
            itemCount: teamsList.length,
            itemBuilder: (BuildContext context, int index) {
              var teamData = teamsList[index].data() as Map<String, dynamic>?;
              var teamName = teamData?['team_name'];
              var teamId = teamsList[index].id;

              return Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TeamDetailPage(
                          teamName: teamName ?? 'Team Name Unavailable',
                          teamId: int.parse(teamId),
                          teamSport: teamData?['team_sport'] ??
                              'Sport Name Unavailable',
                          teamCreator: teamData!['team_creator_email'],
                          teamImageUrl: teamData!['teamImageUrl'],
                          teamDes: teamData!['team_description'],
                          winCount: teamData['winCount'],
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 60, // Adjust the size as needed
                        height: 60, // Adjust the size as needed
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: teamData!['teamImageUrl'] != null &&
                                    teamData!['teamImageUrl'].isNotEmpty
                                ? NetworkImage(teamData!['teamImageUrl'])
                                : AssetImage('assets/images/defaultTeam.png')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                      SizedBox(
                          width: 16), // Add some space between the containers
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${teamData['team_name']}',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text('${teamData['team_sport']}',
                              style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        } else {
          return Center(child: Text('No Teams Found'));
        }
      },
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: TeamPage(),
  ));
}
