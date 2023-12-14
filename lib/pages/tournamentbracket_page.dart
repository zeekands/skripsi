import 'dart:convert';
import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportifyapp/pages/team.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tournament_bracket/tournament_bracket.dart';

class TournamentBracketPage extends StatefulWidget {
  final String activityId;

  TournamentBracketPage({required this.activityId});

  @override
  _TournamentBracketPageState createState() => _TournamentBracketPageState();
}

class _TournamentBracketPageState extends State<TournamentBracketPage> {
  List<String> teams = [];
  List<List<String>> bracket = [];
  List<Map<String, dynamic>> tournamentBracketData = [];
  String? userEmail = FirebaseAuth.instance.currentUser?.email;

  Future<List<List<Team>>> getAllTeams() {
    return Future(() => allTeams);
  }

  List<List<Team>> allTeams = [];

  bool test = false;

  @override
  void initState() {
    super.initState();
    debugPrint('id: ${widget.activityId}');
    fetchTournamentBracketData();
    debugPrint('IS SHUFFLED : $test');
    setState(() {});
  }

  Future<bool> isUserHost(String activityId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return false;
    }

    DocumentSnapshot activitySnapshot = await FirebaseFirestore.instance
        .collection('activities')
        .doc(activityId)
        .get();

    if (!activitySnapshot.exists) {
      return false;
    }

    String hostEmail = activitySnapshot.get('user_email');

    return currentUser.email == hostEmail;
  }

  Future<bool> bracketCanShuffle(String activityId) async {
    // Check if the user is the host
    bool userIsHost = await isUserHost(activityId);
    if (!userIsHost) {
      return false; // User is not the host, cannot shuffle
    }

    try {
      // Query the matchup_bracket collection
      DocumentSnapshot bracketSnapshot = await FirebaseFirestore.instance
          .collection('matchup_bracket')
          .doc(activityId)
          .get();

      if (!bracketSnapshot.exists) {
        return true; // Bracket doesn't exist, allow shuffling
      }

      // Check the value of isShuffled
      bool isShuffled = bracketSnapshot.get('isShuffled') ?? false;

      return !isShuffled; // Return true if not shuffled, false otherwise
    } catch (e) {
      // Handle any potential errors
      print('Error checking if bracket can shuffle: $e');
      return false;
    }
  }

  void fetchTeamsAndPopulateBracket() {
    List<String> fetchedTeams = getTeamsForActivityId(widget.activityId);

    setState(() {
      teams = fetchedTeams;
      populateBracket();
    });
  }

  initShuffle() async {
    test = await getIsShuffled();
    setState(() {});
  }

  refreshBracket() async {
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('matchup_bracket')
        .doc(widget.activityId)
        .get();
    if (documentSnapshot.exists) {
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>? ?? {};
      List<dynamic> matchList = data['match'] as List<dynamic>? ?? [];

      if (matchList.isNotEmpty) {
        var matchAtIndex0 = matchList[0] as Map<String, dynamic>;

        dynamic fieldValue = matchAtIndex0;
        List<dynamic> updatedTeams = fieldValue['round_0'].map((team) {
          return {
            'score': 0,
            'name': team['name'],
            'id': team['id'],
            'slot': team['slot'],
          };
        }).toList();

        fieldValue['round_0'] = updatedTeams;
        var collection =
            FirebaseFirestore.instance.collection('matchup_bracket');

        collection.doc(widget.activityId).set({
          'match': [fieldValue],
          'isShuffled': test
        });
        // print('Value at index 0: $fieldValue');
      } else {
        print('No elements in the match list');
      }
    }
  }

  updateToFirebase() async {
    var teamsToUpdate = [];
    for (var i = 0; i < allTeams.length; i++) {
      List<dynamic> teamsToDb = [];
      for (var team in allTeams[i]) {
        teamsToDb.add(
          Team(
                  id: team.id.toString(),
                  name: team.name,
                  score: team.score,
                  slot: i)
              .toJson(),
        );
      }

      teamsToUpdate.add({'round_$i': teamsToDb});
    }

    debugPrint('data: ${json.encode(teamsToUpdate)}');

    var collection = FirebaseFirestore.instance.collection('matchup_bracket');
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('matchup_bracket')
        .doc(widget.activityId)
        .get();
    if (documentSnapshot.exists) {
      // Retrieve the value of 'isShuffled' from the document data
      Map<String, dynamic> data =
          documentSnapshot.data() as Map<String, dynamic>? ?? {};
      bool? isShuffled = data['isShuffled'] as bool?;

      // Use the value of 'isShuffled' as needed
      print('isShuffled: $isShuffled');
      if (isShuffled == true) {
        test = true;
        print('tes bool$test');
      } else {
        test = false;
        print('tes bool$test');
      }
    } else {
      print('Document does not exist');
    }

    print('ttttttt $collection');
    collection
        .doc(widget.activityId)
        .set({'match': teamsToUpdate, 'isShuffled': test});
  }

  saveWinner(Team team) {
    // int score = inputScore.text.isEmpty ? 0 : int.parse(inputScore.text);
    var teamIndex =
        allTeams[team.slot].indexWhere((element) => element.id == team.id);
    debugPrint('team index: $teamIndex');
    var slot = team.slot;
    var remainder = allTeams[slot].length % 2;
    var lengthTeam = ((allTeams[slot].length - remainder) / 2) + remainder;

    List<Team> tempEmptyTeam = [];

    debugPrint('MAX NEXT TEAM LENGTH: ${lengthTeam.toInt()}');

    if (allTeams.length <= slot + 1) {
      try {
        var item = allTeams[slot + 1].length;
      } catch (err) {
        // debugPrint('err');
        // debugPrint("ADD WINNER ON NEXT ROUND");
        if (teamIndex != 0) {
          if (remainder != 0 && lengthTeam > 2) {
            var teamslot = (teamIndex / 2).ceil();
            if (teamIndex > 0 && teamslot > 0) {
              for (var i = 0; i < teamslot; i++) {
                tempEmptyTeam.add(
                  Team(id: 'empty', name: '', score: 0, slot: slot + 1),
                );
              }
            }
          } else {
            var teamslot = (teamIndex / 2).floor();
            if (teamIndex > 0 && teamslot > 0) {
              for (var i = 0; i < teamslot; i++) {
                tempEmptyTeam.add(
                  Team(id: 'empty', name: '', score: 0, slot: slot + 1),
                );
              }
            }
          }
          // fill empty
          // if (teamIndex > 0 && lengthTeam > 3) {
          //   for (var i = 0; i < lengthTeam - 1; i++) {
          //     tempEmptyTeam.add(
          //       Team(id: 'empty', name: '', score: 0, slot: slot + 1),
          //     );
          //   }
          // }
        }
      }
      //modify if data exist

      allTeams[team.slot][teamIndex] =
          Team(id: team.id, name: team.name, score: 0, slot: team.slot);

      tempEmptyTeam
          .add(Team(id: team.id, name: team.name, score: 0, slot: slot + 1));

      allTeams.add(tempEmptyTeam);

      updateToFirebase();
      Navigator.pop(context);

      return;
    }
    debugPrint('ALLTEM LENGTH ${allTeams.length} slot ${slot + 1}');
    if (allTeams.length >= slot + 1) {
      if (allTeams[slot + 1].length <= lengthTeam.toInt()) {
        try {
          //winner final
          if (lengthTeam.toInt() == 1) {
            debugPrint('LENGTH TEAM 1');
            allTeams[slot + 1][0] =
                Team(id: team.id, name: team.name, score: 0, slot: slot + 1);

            updateToFirebase();

            Navigator.pop(context);
            return;
          }

          if (allTeams[slot + 1].length == lengthTeam.toInt()) {
            debugPrint(
                'LENGTH TEAM ${allTeams[slot + 1].length} : $lengthTeam');

            if (teamIndex == 0) {
              allTeams[slot + 1][0] =
                  Team(id: team.id, name: team.name, score: 0, slot: slot + 1);
            }

            if (teamIndex > 0) {
              if (remainder != 0 && lengthTeam > 2) {
                var teamslot = (teamIndex / 2).ceil();
                allTeams[slot + 1][teamslot] = Team(
                    id: team.id, name: team.name, score: 0, slot: slot + 1);
              } else {
                var teamslot = (teamIndex / 2).floor();
                allTeams[slot + 1][teamslot] = Team(
                    id: team.id, name: team.name, score: 0, slot: slot + 1);
              }
            }

            updateToFirebase();
            Navigator.pop(context);
            return;
          }

          if (allTeams[slot + 1][teamIndex - 1].id.isNotEmpty) {
            debugPrint('TEAM INDEX: $teamIndex');
            if (teamIndex > 0) {
              allTeams[slot + 1][teamIndex - 1] = Team(
                  id: team.id,
                  name: team.name,
                  score: team.score,
                  slot: slot + 1);
            }
          }
        } catch (err, stack) {
          debugPrint('err disini $stack');
          if (teamIndex == 0) {
            allTeams[slot + 1][teamIndex] = Team(
                id: team.id,
                name: team.name,
                score: team.score,
                slot: slot + 1);
          } else {
            debugPrint(
                "ADD WINNER ON NEXT ROUND AFTER INSERT FIRST slot ${json.encode(allTeams[1])}");

            allTeams[slot + 1].add(
                Team(id: team.id, name: team.name, score: 0, slot: slot + 1));
          }
          // return;
        }

        // updateToFirebase();
      }
      setState(() {});
      Navigator.pop(context, true);
      return;
    }
    updateToFirebase();
    setState(() {});
    Navigator.pop(context, true);
  }

  Widget inputScoreWidget(TextEditingController inputScore) {
    return Row(
      children: [
        const SizedBox(
          width: 5,
        ),
        Container(
          width: 35,
          height: 35,
          // padding: EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: Colors.red)),
          child: TextField(
            controller: inputScore,
            style: const TextStyle(fontSize: 17),
            keyboardType: TextInputType.number,
            textAlignVertical: TextAlignVertical.center,
            decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(bottom: 15)),
            maxLength: 3,
            minLines: 1,
            maxLines: 1,
          ),
        )
      ],
    );
  }

  void setIsShuffled() async {
    var prefs = await SharedPreferences.getInstance();
    var activityId = widget.activityId;
    var key = 'activity_$activityId';
    prefs.setBool(key, true);
  }

  void setIsWinner(String team, String slot) async {
    var prefs = await SharedPreferences.getInstance();
    var activityId = widget.activityId;
    var key = 'activity_${activityId}_team_${team}_slot_$slot';
    prefs.setBool(key, true);
  }

  Future<bool> getIsWinner(String team, String slot) async {
    var prefs = await SharedPreferences.getInstance();
    var activityId = widget.activityId;
    var key = 'activity_${activityId}_team_${team}_slot_$slot';
    return prefs.getBool(key) ?? false;
  }

  Future<bool> getIsShuffled() async {
    var prefs = await SharedPreferences.getInstance();
    var activityId = widget.activityId;

    var key = 'activity_$activityId';
    return prefs.getBool(key) ?? false;
  }

  Future showMatchDialog(BuildContext context, Team team) {
    TextEditingController inputScore = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          contentPadding: const EdgeInsets.only(top: 10.0),
          content: SizedBox(
            height: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 15,
                ),
                Text(
                  "${team.name} Score: ${team.score}",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 20,
                ),
                FutureBuilder(
                  future: isUserHost(widget.activityId),
                  builder: (context, snapshot) {
                    bool isUserHost = snapshot.data == true;
                    print('Snapshot data: ${snapshot.data}');

                    if (snapshot.hasData) {
                      print("isuer host $isUserHost");
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 10,
                              ),
                              Visibility(
                                visible: !isUserHost ? false : true,
                                child: inputScoreWidget(inputScore),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Visibility(
                            visible: !isUserHost ? false : true,
                            child: ElevatedButton(
                              onPressed: () async {
                                int score = inputScore.text.isEmpty
                                    ? 0
                                    : int.parse(inputScore.text);
                                saveWinner(team);
                                var teamIndexA = allTeams[team.slot].indexWhere(
                                    (element) => element.id == team.id);
                                debugPrint('team index a: $teamIndexA');
                                allTeams[team.slot][teamIndexA] = Team(
                                    id: team.id,
                                    name: team.name,
                                    score: score,
                                    slot: team.slot);

                                updateToFirebase();
                                setIsWinner(team.name, team.slot.toString());
                              },
                              child: const Text('Save'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color.fromARGB(255, 230, 0, 0),
                              ),
                            ),
                          )
                        ],
                      );
                    }
                    return Container();
                  },
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future showMatchDialogTwoTeam(BuildContext context, Team teamA, Team teamB) {
    TextEditingController inputScoreA = TextEditingController();
    TextEditingController inputScoreB = TextEditingController();

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10.0))),
          contentPadding: const EdgeInsets.only(top: 10.0),
          content: SizedBox(
            height: 200,
            child: FutureBuilder(
              future: isUserHost(widget.activityId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // While the future is still being resolved, return a loading indicator or placeholder.
                  return CircularProgressIndicator();
                }

                if (snapshot.hasError) {
                  // If there's an error with the future, handle it accordingly.
                  return Text('Error: ${snapshot.error}');
                }

                bool isUserHost = snapshot.data == true;

                // Check if the user is a host or not.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      height: 15,
                    ),
                    Text(
                      "${teamA.name} vs ${teamB.name} ",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Visibility(
                      visible: isUserHost,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 10,
                          ),
                          inputScoreWidget(inputScoreA),
                          const SizedBox(
                            width: 10,
                          ),
                          Text("vs"),
                          inputScoreWidget(inputScoreB),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Visibility(
                      visible: isUserHost,
                      child: ElevatedButton(
                        onPressed: () {
                          int scoreA = inputScoreA.text.isEmpty
                              ? 0
                              : int.parse(inputScoreA.text);
                          int scoreB = inputScoreB.text.isEmpty
                              ? 0
                              : int.parse(inputScoreB.text);
                          var winner;
                          if (scoreA > scoreB) {
                            winner = teamA;
                          }
                          if (scoreB > scoreA) {
                            winner = teamB;
                          }
                          saveWinner(winner);

                          // update score team a
                          var teamIndexA = allTeams[teamA.slot]
                              .indexWhere((element) => element.id == teamA.id);
                          debugPrint('team index a: $teamIndexA');
                          allTeams[teamA.slot][teamIndexA] = Team(
                            id: teamA.id,
                            name: teamA.name,
                            score: scoreA,
                            slot: teamA.slot,
                          );

                          // update score team b
                          var teamIndexB = allTeams[teamB.slot]
                              .indexWhere((element) => element.id == teamB.id);
                          allTeams[teamB.slot][teamIndexB] = Team(
                            id: teamB.id,
                            name: teamB.name,
                            score: scoreB,
                            slot: teamB.slot,
                          );
                          setIsWinner(teamA.name, teamA.slot.toString());
                          setIsWinner(teamB.name, teamB.slot.toString());

                          updateToFirebase();
                        },
                        child: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 230, 0, 0),
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  saveToFirebase() {
    List<dynamic> teamsToDb = [];
    for (var team in tournamentBracketData) {
      teamsToDb.add(
        json.encode(
          Team(
              id: team['team_id'].toString(),
              name: team['team_name'],
              score: 0,
              slot: 0),
        ),
      );
    }
    var collection = FirebaseFirestore.instance.collection('matchup_bracket');
    collection.doc(widget.activityId).set({
      'match': [
        {'round_0': teamsToDb},
      ]
    });
  }

  void fetchTournamentBracketData() async {
    try {
      debugPrint('fetch tournament dialog');
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('TournamentBracket')
          .where('activity_id', isEqualTo: widget.activityId)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      List<String> teamIds = querySnapshot.docs
          .map((doc) {
            Map<String, dynamic>? data =
                doc.data() as Map<String, dynamic>?; // Explicit cast
            return data?['team_id'] as String?;
          })
          .where((teamId) => teamId != null)
          .map((teamId) => teamId.toString())
          .toList();
      debugPrint('teamId: $teamIds');

      List<Map<String, dynamic>> teamDataList = [];

      for (String teamId in teamIds) {
        DocumentSnapshot teamSnapshot = await FirebaseFirestore.instance
            .collection('teams')
            .doc(teamId)
            .get();

        if (teamSnapshot.exists) {
          teamDataList.add(teamSnapshot.data() as Map<String, dynamic>);
        }
      }

      debugPrint('TEAMLIST: $teamDataList');

      setState(() {
        tournamentBracketData = teamDataList;
      });
    } catch (e, stack) {
      print('Error fetching tournament bracket data: $stack');
    }
  }

  void populateBracket() {
    bracket = [];
    for (int i = 0; i < teams.length; i += 2) {
      if (i + 1 < teams.length) {
        bracket.add([teams[i], teams[i + 1]]);
      } else {
        bracket.add([teams[i]]);
      }
    }
  }

  void shuffleBracketAndSave() async {
    try {
      tournamentBracketData.shuffle();

      List<dynamic> teamsToDb = [];
      for (var team in tournamentBracketData) {
        teamsToDb.add(
          Team(
                  id: team['team_id'].toString(),
                  name: team['team_name'],
                  score: 0,
                  slot: 0)
              .toJson(),
        );
      }
      var collection = FirebaseFirestore.instance.collection('matchup_bracket');
      collection.doc(widget.activityId).set({
        'match': [
          {'round_0': teamsToDb},
        ],
        'isShuffled': false,
      });

      setIsShuffled();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bracket shuffled and saved successfully!'),
        ),
      );
      setState(() {});
    } catch (e) {
      print('Error shuffling and saving bracket: $e');
    }
  }

  void shuffleBracket() {
    setState(() {
      teams.shuffle();
      populateBracket();
    });
  }

  void _showTeamsDialog(BuildContext context) {
    fetchTournamentBracketData();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Participating Teams'),
          content: Column(
            children: tournamentBracketData.map((teamData) {
              return Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: teamData['teamImageUrl'] != null &&
                                teamData['teamImageUrl'].isNotEmpty
                            ? NetworkImage(teamData['teamImageUrl'])
                            : const AssetImage('assets/images/defaultTeam.png')
                                as ImageProvider,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${teamData['team_name']}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text('${teamData['team_sport']}',
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateIsShuffled(String activityId) async {
    try {
      // Update the isShuffled field in the matchup_bracket collection
      await FirebaseFirestore.instance
          .collection('matchup_bracket')
          .doc(activityId)
          .set({'isShuffled': true}, SetOptions(merge: true));

      print('isShuffled updated successfully.');
    } catch (e) {
      // Handle any potential errors
      print('Error updating isShuffled: $e');
    }
  }

  @override
  void didUpdateWidget(covariant TournamentBracketPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tournament Bracket'),
        actions: [
          FutureBuilder<bool>(
            future: isUserHost(widget.activityId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data == true) {
                return IconButton(
                  onPressed: () {
                    // Call the refreshBracket function when the button is pressed
                    refreshBracket();
                  },
                  icon: Icon(Icons.refresh),
                );
              }
              return Container(); // or you can return an empty SizedBox for spacing
            },
          ),
        ],
        backgroundColor: const Color.fromARGB(255, 230, 0, 0),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              height: 40,
              child: FutureBuilder(
                future: bracketCanShuffle(widget.activityId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    debugPrint('status ${snapshot.data}');
                    bool userIsHost = snapshot.data ?? false;
                    return Visibility(
                      visible: userIsHost,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: shuffleBracketAndSave,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 230, 0, 0),
                            ),
                            child: const Text(
                              'Shuffle Bracket',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 10), // Adjust the spacing as needed
                          ElevatedButton(
                            onPressed: () {
                              updateIsShuffled(widget.activityId);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 230, 0, 0),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Container();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Column(
          //   children: bracket.map((matchup) {
          //     return Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: matchup.map((team) {
          //         return Padding(
          //           padding: EdgeInsets.all(8.0),
          //           child: Text(team),
          //         );
          //       }).toList(),
          //     );
          //   }).toList(),
          // ),

          Flexible(
              child: StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('matchup_bracket')
                .doc(widget.activityId)
                .snapshots(),
            builder: (context, snapshot) {
              allTeams.clear();
              if (!snapshot.hasData) {
                return const Center(
                  child: Text('Loading...'),
                );
              }

              var item = snapshot.data!.data();

              if (item == null) {
                var collection =
                    FirebaseFirestore.instance.collection('matchup_bracket');
                collection.doc(widget.activityId).set({'match': []});
              }
              var matches;
              try {
                matches = item!['match'];
                if (matches.length <= 0) {
                  return const Center(
                    child: Text(
                        'Match Data not found, please wait for host to shuffle!'),
                  );
                }
              } catch (err) {
                return const Center(
                  child: Text('No match data found!'),
                );
              }

              List<List<Team>> teamfromDb = [];
              for (var i = 0; i < matches.length; i++) {
                List<Team> tempTeam = [];
                for (var team in matches[i]['round_$i']) {
                  tempTeam.add(Team.fromJson(team));
                }
                teamfromDb.add(tempTeam);
                allTeams.add(tempTeam);
              }

              debugPrint(json.encode(item));
              if (matches[0]['round_0'].isNotEmpty) {
                return TBracket<Team>(
                  space: 200 / 4,
                  separation: 150,
                  stageWidth: 200,
                  onSameTeam: (team1, team2) {
                    if (team1 != null && team2 != null) {
                      return team1.name == team2.name;
                    }
                    return false;
                  },
                  hadderBuilder: (context, index, count) => Container(),
                  lineIcon: LineIcon(
                      icon: Icons.info,
                      backgroundColor: Colors.grey,
                      iconsSize: 14),
                  connectorColor: const Color.fromARGB(144, 244, 67, 54),
                  winnerConnectorColor: Colors.green,
                  teamContainerDecoration: BracketBoxDecroction(
                      borderRadious: 15, color: Colors.black),
                  stageIndicatorBoxDecroction:
                      BracketStageIndicatorBoxDecroction(
                          borderRadious: const Radius.circular(15),
                          primaryColor: Colors.transparent,
                          secondaryColor: Colors.transparent),
                  containt: teamfromDb,
                  teamNameBuilder: (Team t) {
                    return BracketText(
                      text: '${t.name} (${t.score.toString()})',
                      textStyle: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    );
                  },
                  onContainerTapDown:
                      (Team? model, TapDownDetails tapDownDetails) async {
                    if (model != null) {
                      await showMatchDialog(context, model);
                    }
                  },
                  onLineIconPress: ((team1, team2, tapDownDetails) async {
                    if (team1 != null && team2 != null) {
                      print("${team1.name} and ${team2.name}");
                      await showMatchDialogTwoTeam(context, team1, team2);
                    } else {
                      print(null);
                    }
                  }),
                  context: context,
                );
              }
              return Column(
                children: [
                  Text('Fail to load team, Shuffle again!'),
                  ElevatedButton(
                    onPressed: shuffleBracketAndSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 230, 0, 0),
                    ),
                    child: const Text(
                      'Shuffle Bracket',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              );
            },
          ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showTeamsDialog(context);
        },
        child: const Icon(
          Icons.group,
          color: Colors.white,
        ),
        backgroundColor: const Color.fromARGB(255, 230, 0, 0),
      ),
    );
  }
}

List<String> getTeamsForActivityId(String activityId) {
  return [];
}
