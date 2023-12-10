import 'dart:collection';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'activity_detail.dart';
import 'activity_type.dart';

class MyActivityPage extends StatefulWidget {
  @override
  _MyActivityPageState createState() => _MyActivityPageState();
}

class _MyActivityPageState extends State<MyActivityPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 230, 0, 0),
          title: Text('My Activities'),
          bottom: TabBar(
            labelColor: Colors.white,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'My Activity'),
              Tab(text: 'Activity History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            MyActivityTab(), // Create a widget for My Activity tab
            ActivityHistoryTab(), // Create a widget for Activity History tab
          ],
        ),
      ),
    );
  }
}

Future<String> getSportImage(String sportName) async {
  try {
    // Get a reference to the Firestore collection
    CollectionReference sports =
        FirebaseFirestore.instance.collection('sports');

    // Query Firestore to get the document for the provided sportName
    QuerySnapshot snapshot =
        await sports.where('sport_name', isEqualTo: sportName).get();

    // Check if a document was found
    if (snapshot.docs.isNotEmpty) {
      // Get the image URL from the document
      String imageUrl = snapshot.docs.first['sport_image'];
      return imageUrl;
    } else {
      // If sportName is not found, return a default image URL
      return 'default_image_url_here';
    }
  } catch (e) {
    // Handle errors here
    print('Error fetching sport image: $e');
    // Return a default image URL in case of an error
    return 'default_image_url_here';
  }
}

class MyActivityTab extends StatelessWidget {
  Future<int> getTotalParticipants(String activityId) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference participants =
          FirebaseFirestore.instance.collection('participants');

      // Query Firestore to get the number of participants for the provided activity ID
      QuerySnapshot snapshot = await participants
          .where('activity_id', isEqualTo: activityId)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      // Handle errors here
      print('Error fetching total participants: $e');
      return 0; // Return 0 in case of an error
    }
  }

  String _formatFee(String fee) {
    // Convert the fee to an integer
    int? feeValue = int.tryParse(fee);

    // Check if the conversion is successful
    if (feeValue != null) {
      // Format the fee using NumberFormat
      String formattedFee = NumberFormat('#,###').format(feeValue);
      return formattedFee;
    } else {
      // Handle the case where activity['activityFee'] is not a valid number
      return 'Invalid Fee';
    }
  }

  Future<int> getTotalTournamentBracket(String activityId) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference brackets =
          FirebaseFirestore.instance.collection('TournamentBracket');

      // Query Firestore to get the total number of brackets for the provided activityId
      QuerySnapshot snapshot = await brackets
          .where('activity_id', isEqualTo: activityId)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      // Return the total number of brackets
      return snapshot.size;
    } catch (e) {
      // Handle errors here
      print('Error fetching total tournament brackets: $e');
      // Return 0 in case of an error
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? userEmail = FirebaseAuth.instance.currentUser?.email;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    HashMap<String, dynamic> dataTournament = HashMap<String, dynamic>();
    //HashMap<String, dynamic> dataTournament2 = HashMap<String, dynamic>();
    HashMap<String, dynamic> dataActivity = HashMap<String, dynamic>();
    List<dynamic> dataTournamentA = [];
    List<String> activityID = [];
    Future<void> getData(String userEmail) async {
      //print("clear");
      activityID = [];
      dataTournamentA = [];

      //print(activityID);
      //print(dataTournamentA.length);
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('TournamentBracket')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        for (var item in querySnapshot.docs) {
          //print("test");
          //print(item.id);
          //print(jsonEncode(item.data()));
          dataTournament[item.id] = item.data();
          dataTournamentA.add(item.data());
        }
        //return querySnapshot.docs.first['activity_id'] as String?;
      }

      QuerySnapshot querySnapshot2 =
          await FirebaseFirestore.instance.collection('activities').get();

      if (querySnapshot2.docs.isNotEmpty) {
        for (var item in querySnapshot2.docs) {
          //print("test");
          //print(item.id);
          //print(jsonEncode(item.data()));
          var temp = item.data() as dynamic;
          temp["key"] = item.id;
          dataActivity[item.id] = temp;
          dataTournamentA.add(temp);
        }
        //return querySnapshot.docs.first['activity_id'] as String?;
      }

      QuerySnapshot querySnapshot3 = await FirebaseFirestore.instance
          .collection('team_members')
          .where("user_email", isEqualTo: userEmail)
          .where("status", isEqualTo: 'Confirmed')
          .get();

      if (querySnapshot3.docs.isNotEmpty) {
        for (var item in querySnapshot3.docs) {
          //print("test");
          //print(item.id);
          //print(jsonEncode(item.data()));
          //print(item.data());
          var itm = item.data() as dynamic;
          for (int i = 0; i < dataTournamentA.length; i++) {
            //print("a" + dataTournamentA[i]["team_id"].toString());
            //print("b" + itm["team_id"].toString());

            if (dataTournamentA[i]["team_id"].toString() ==
                itm["team_id"].toString()) {
              //print("xxx");
              //print(dataTourname
              activityID.add(dataTournamentA[i]["activity_id"]);
            }
          }
          //print("");
        }
      }

      QuerySnapshot querySnapshot4 = await FirebaseFirestore.instance
          .collection('participants')
          .where("user_email", isEqualTo: userEmail)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      if (querySnapshot4.docs.isNotEmpty) {
        for (var item in querySnapshot4.docs) {
          //print("test");
          //print(item.id);
          //print(jsonEncode(item.data()));
          //print(item.data());
          var itm = item.data() as dynamic;

          //print(itm["activity_id"]);
          activityID.add(itm["activity_id"]);
          //print("");
        }
        //return querySnapshot.docs.first['activity_id'] as String?;
      }

      print("activity id");
      print(activityID);

      //print("Tournament");
      //print(dataTournament["10"]);

      //print("Activity");
      //print(dataActivity["39"]);
    }

    return Scaffold(
      body: FutureBuilder<void>(
        future: getData(userEmail!),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (activityID.isEmpty) {
            return Center(child: Text('No data available.'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('activities')
                .where(FieldPath.documentId, whereIn: activityID)
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              var activities = snapshot.data!.docs;

              // Filter activities where activityStatus is not equal to 'Completed'
              activities = activities
                  .where(
                      (activity) => activity['activityStatus'] != 'Completed')
                  .toList();

              if (activities.isEmpty) {
                return Center(
                  child: Text('No activities for now...'),
                );
              }

              activities.sort((a, b) {
                DateTime dateA =
                    DateFormat('dd-MM-yyyy').parse(a['activityDate']);
                DateTime dateB =
                    DateFormat('dd-MM-yyyy').parse(b['activityDate']);

                return dateA.compareTo(dateB);
              });

              // Group the activities by date
              Map<String, List<DocumentSnapshot>> activitiesByDate = {};

              for (var activity in activities) {
                String date = activity['activityDate'];
                if (!activitiesByDate.containsKey(date)) {
                  activitiesByDate[date] = [];
                }
                activitiesByDate[date]!.add(activity);
              }

              return ListView.builder(
                itemCount: activitiesByDate.length,
                itemBuilder: (BuildContext context, int index) {
                  String date = activitiesByDate.keys.elementAt(index);
                  List<DocumentSnapshot> activitiesForDate =
                      activitiesByDate[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          date,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: activitiesForDate.length,
                        itemBuilder: (BuildContext context, int index) {
                          var activity = activitiesForDate[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ActivityDetailsPage(activity.id),
                                ),
                              );
                            },
                            child: Card(
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            FutureBuilder<String>(
                                              future: getSportImage(
                                                  activity['sportName']),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Error: ${snapshot.error}');
                                                } else {
                                                  return Image.network(
                                                    snapshot.data!,
                                                    width: 40,
                                                    height: 40,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              activity['activityTime'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(activity['activityTitle'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              )),
                                          Text(
                                              'Location: ${activity['activityLocation']}'),
                                          Text(
                                              'Fee: IDR ${_formatFee(activity['activityFee'])}'),
                                          if (activity['activityType'] ==
                                                  'Normal Activity' ||
                                              activity['activityType'] ==
                                                  'Sparring')
                                            Text(
                                                'Duration in hour: ${activity['activityDuration']}'),
                                          if (activity['activityType'] ==
                                              'Normal Activity')
                                            FutureBuilder<int>(
                                              future: getTotalParticipants(
                                                  activity.id),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Error: ${snapshot.error}');
                                                } else {
                                                  return Text(
                                                      'Quota: (${snapshot.data}/${activity['activityQuota']})');
                                                }
                                              },
                                            ),
                                          if (activity['activityType'] ==
                                                  'Tournament' ||
                                              activity['activityType'] ==
                                                  'Sparring')
                                            FutureBuilder<int>(
                                              future: getTotalTournamentBracket(
                                                  activity.id),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Error: ${snapshot.error}');
                                                } else {
                                                  return Text(
                                                      'Quota: (${snapshot.data}/${activity['activityQuota']})');
                                                }
                                              },
                                            ),
                                          Text(
                                              'Activity Type: ${activity['activityType']}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityTypeChoosePage(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

class ActivityHistoryTab extends StatelessWidget {
  String? userEmail = FirebaseAuth.instance.currentUser!.email;
  Future<int> getTotalParticipants(String activityId) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference participants =
          FirebaseFirestore.instance.collection('participants');

      // Query Firestore to get the number of participants for the provided activity ID
      QuerySnapshot snapshot = await participants
          .where('activity_id', isEqualTo: activityId)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      // Handle errors here
      print('Error fetching total participants: $e');
      return 0; // Return 0 in case of an error
    }
  }

  Future<int> getTotalTournamentBracket(String activityId) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference brackets =
          FirebaseFirestore.instance.collection('TournamentBracket');

      // Query Firestore to get the total number of brackets for the provided activityId
      QuerySnapshot snapshot = await brackets
          .where('activity_id', isEqualTo: activityId)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      // Return the total number of brackets
      return snapshot.size;
    } catch (e) {
      // Handle errors here
      print('Error fetching total tournament brackets: $e');
      // Return 0 in case of an error
      return 0;
    }
  }

  String _formatFee(String fee) {
    // Convert the fee to an integer
    int? feeValue = int.tryParse(fee);

    // Check if the conversion is successful
    if (feeValue != null) {
      // Format the fee using NumberFormat
      String formattedFee = NumberFormat('#,###').format(feeValue);
      return formattedFee;
    } else {
      // Handle the case where activity['activityFee'] is not a valid number
      return 'Invalid Fee';
    }
  }

  Future<String?> getUserTeamId(String userEmail) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('team_members')
          .where('user_email', isEqualTo: userEmail)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['team_id'] as String?;
      }
    } catch (e) {
      print('Error fetching user team id: $e');
    }
    return null;
  }

  Future<String?> getActivityIdFromTournamentBracket(String teamId) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('TournamentBracket')
          .where('team_id', isEqualTo: teamId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['activity_id'] as String?;
      }
    } catch (e) {
      print('Error fetching activity id from TournamentBracket: $e');
    }
    return null;
  }

  HashMap<String, dynamic> dataTournament = HashMap<String, dynamic>();
  //HashMap<String, dynamic> dataTournament2 = HashMap<String, dynamic>();
  HashMap<String, dynamic> dataActivity = HashMap<String, dynamic>();
  List<dynamic> dataTournamentA = [];
  List<String> activityID = [];
  Future<void> getData(String userEmail) async {
    //print("clear");
    activityID = [];
    dataTournamentA = [];

    //print(activityID);
    //print(dataTournamentA.length);
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('TournamentBracket').get();

    if (querySnapshot.docs.isNotEmpty) {
      for (var item in querySnapshot.docs) {
        //print("test");
        //print(item.id);
        //print(jsonEncode(item.data()));
        dataTournament[item.id] = item.data();
        dataTournamentA.add(item.data());
      }
      //return querySnapshot.docs.first['activity_id'] as String?;
    }

    QuerySnapshot querySnapshot2 =
        await FirebaseFirestore.instance.collection('activities').get();

    if (querySnapshot2.docs.isNotEmpty) {
      for (var item in querySnapshot2.docs) {
        //print("test");
        //print(item.id);
        //print(jsonEncode(item.data()));
        var temp = item.data() as dynamic;
        temp["key"] = item.id;
        dataActivity[item.id] = temp;
        dataTournamentA.add(temp);
      }
      //return querySnapshot.docs.first['activity_id'] as String?;
    }

    QuerySnapshot querySnapshot3 = await FirebaseFirestore.instance
        .collection('team_members')
        .where("user_email", isEqualTo: userEmail)
        .where("status", isEqualTo: 'Confirmed')
        .get();

    if (querySnapshot3.docs.isNotEmpty) {
      for (var item in querySnapshot3.docs) {
        //print("test");
        //print(item.id);
        //print(jsonEncode(item.data()));
        //print(item.data());
        var itm = item.data() as dynamic;
        for (int i = 0; i < dataTournamentA.length; i++) {
          //print("a" + dataTournamentA[i]["team_id"].toString());
          //print("b" + itm["team_id"].toString());

          if (dataTournamentA[i]["team_id"].toString() ==
              itm["team_id"].toString()) {
            //print("xxx");
            //print(dataTourname
            activityID.add(dataTournamentA[i]["activity_id"]);
          }
        }
        //print("");
      }
    }

    QuerySnapshot querySnapshot4 = await FirebaseFirestore.instance
        .collection('participants')
        .where("user_email", isEqualTo: userEmail)
        .where("status", isEqualTo: 'Confirmed')
        .get();

    if (querySnapshot4.docs.isNotEmpty) {
      for (var item in querySnapshot4.docs) {
        //print("test");
        //print(item.id);
        //print(jsonEncode(item.data()));
        //print(item.data());
        var itm = item.data() as dynamic;

        //print(itm["activity_id"]);
        activityID.add(itm["activity_id"]);
        //print("");
      }
      //return querySnapshot.docs.first['activity_id'] as String?;
    }

    print("activity id");
    print(activityID);

    //print("Tournament");
    //print(dataTournament["10"]);

    //print("Activity");
    //print(dataActivity["39"]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: getData(userEmail!),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (activityID.isEmpty) {
            return Center(child: Text('No data available.'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('activities')
                .where(FieldPath.documentId, whereIn: activityID)
                .snapshots(),
            builder:
                (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              var activities = snapshot.data!.docs;

              // Filter activities where activityStatus is not equal to 'Completed'
              activities = activities
                  .where(
                      (activity) => activity['activityStatus'] == 'Completed')
                  .toList();

              if (activities.isEmpty) {
                return Center(
                  child: Text('No activities for now...'),
                );
              }

              activities.sort((a, b) {
                DateTime dateA =
                    DateFormat('dd-MM-yyyy').parse(a['activityDate']);
                DateTime dateB =
                    DateFormat('dd-MM-yyyy').parse(b['activityDate']);

                return dateA.compareTo(dateB);
              });

              // Group the activities by date
              Map<String, List<DocumentSnapshot>> activitiesByDate = {};

              for (var activity in activities) {
                String date = activity['activityDate'];
                if (!activitiesByDate.containsKey(date)) {
                  activitiesByDate[date] = [];
                }
                activitiesByDate[date]!.add(activity);
              }

              return ListView.builder(
                itemCount: activitiesByDate.length,
                itemBuilder: (BuildContext context, int index) {
                  String date = activitiesByDate.keys.elementAt(index);
                  List<DocumentSnapshot> activitiesForDate =
                      activitiesByDate[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          date,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: activitiesForDate.length,
                        itemBuilder: (BuildContext context, int index) {
                          var activity = activitiesForDate[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ActivityDetailsPage(activity.id),
                                ),
                              );
                            },
                            child: Card(
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    padding: EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Column(
                                          children: [
                                            FutureBuilder<String>(
                                              future: getSportImage(
                                                  activity['sportName']),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Error: ${snapshot.error}');
                                                } else {
                                                  return Image.network(
                                                    snapshot.data!,
                                                    width: 40,
                                                    height: 40,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                              activity['activityTime'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      padding: EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(activity['activityTitle'],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              )),
                                          Text(
                                              'Location: ${activity['activityLocation']}'),
                                          Text(
                                              'Fee: IDR ${_formatFee(activity['activityFee'])}'),
                                          if (activity['activityType'] ==
                                                  'Normal Activity' ||
                                              activity['activityType'] ==
                                                  'Sparring')
                                            Text(
                                                'Duration in hour: ${activity['activityDuration']}'),
                                          if (activity['activityType'] ==
                                              'Normal Activity')
                                            FutureBuilder<int>(
                                              future: getTotalParticipants(
                                                  activity.id),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Error: ${snapshot.error}');
                                                } else {
                                                  return Text(
                                                      'Quota: (${snapshot.data}/${activity['activityQuota']})');
                                                }
                                              },
                                            ),
                                          if (activity['activityType'] ==
                                                  'Tournament' ||
                                              activity['activityType'] ==
                                                  'Sparring')
                                            FutureBuilder<int>(
                                              future: getTotalTournamentBracket(
                                                  activity.id),
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return CircularProgressIndicator();
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Error: ${snapshot.error}');
                                                } else {
                                                  return Text(
                                                      'Quota: (${snapshot.data}/${activity['activityQuota']})');
                                                }
                                              },
                                            ),
                                          Text(
                                              'Activity Type: ${activity['activityType']}'),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityTypeChoosePage(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
