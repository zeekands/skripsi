import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'activity_detail.dart';
import 'activity_type.dart';

class ActivityListPage extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;

  ActivityListPage({
    required this.selectedDate,
    required this.selectedTime,
  });

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

  Future<int> getTotalParticipants(String activityId) async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference participants =
          FirebaseFirestore.instance.collection('participants');

      // Query Firestore to get the number of participants for the provided activity ID
      QuerySnapshot snapshot =
          await participants.where('activity_id', isEqualTo: activityId).get();

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

  Timer? _timer;
  String? userEmail = FirebaseAuth.instance.currentUser?.email;
  TimeOfDay timevalue = TimeOfDay.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, $userEmail'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .where('activityDateValue',
                isGreaterThanOrEqualTo:
                    int.parse(DateFormat('yyyyMMdd').format(selectedDate)))
            .where('activityStatus', isEqualTo: 'Waiting')
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          print(
              "Selected Date: ${DateFormat('dd-MM-yyyy').format(selectedDate)}");
          int timeAsInteger = (selectedTime.hour * 100) + selectedTime.minute;
          print("time now : ${timeAsInteger}");
          print("time value : ${timevalue}");
          print("Activities count: ${snapshot.data!.docs.length}");

          var activities = snapshot.data!.docs;

          if (activities.isEmpty) {
            return Center(
              child: Text('No activities for now...'),
            );
          }

          activities.sort((a, b) {
            DateTime dateA = DateFormat('dd-MM-yyyy').parse(a['activityDate']);
            DateTime dateB = DateFormat('dd-MM-yyyy').parse(b['activityDate']);

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
                                width:
                                    60, // Set a fixed width for the time container
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
                                      Text('Fee: ${activity['activityFee']}'),
                                      if (activity['activityType'] ==
                                              'Normal Activity' ||
                                          activity['activityType'] ==
                                              'Sparring')
                                        Text(
                                            'Duration in hour: ${activity['activityDuration']}'),
                                      if (activity['activityType'] ==
                                          'Normal Activity')
                                        FutureBuilder<int>(
                                          future:
                                              getTotalParticipants(activity.id),
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
