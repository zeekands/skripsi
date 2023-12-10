import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'activity_detail.dart';
import 'activity_type.dart';

class ActivityListPage extends StatefulWidget {
  final DateTime selectedDate;
  TimeOfDay selectedTime;

  ActivityListPage({
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  _ActivityListPageState createState() => _ActivityListPageState();
}

class _ActivityListPageState extends State<ActivityListPage> {
  Timer? _timer;
  String? userEmail = FirebaseAuth.instance.currentUser?.email;
  TimeOfDay timevalue = TimeOfDay.now();
  String? city = '';

  void createTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        // Update the time or perform any other desired actions
        timevalue = TimeOfDay.now();

        print("Updated time timer: ${timevalue}");
      });
    });
  }

  Future<String?> getUserLocation() async {
    try {
      // Get the current user's email
      String? userEmail = FirebaseAuth.instance.currentUser?.email;

      if (userEmail != null) {
        // Reference to the users collection
        CollectionReference users =
            FirebaseFirestore.instance.collection('users');

        // Query the users collection based on the document ID
        QuerySnapshot querySnapshot =
            await users.where(FieldPath.documentId, isEqualTo: userEmail).get();

        // Check if there is a matching document
        if (querySnapshot.docs.isNotEmpty) {
          // Get the first document (assuming there is only one match)
          var userDocument = querySnapshot.docs.first;

          // Access the 'city' field from the document
          city = userDocument['city'];

          // Return the city
          return city;
        } else {
          // If no matching document is found
          print("null1");
          return null;
        }
      } else {
        print("null2");
        // If user email is null
        return null;
      }
    } catch (e) {
      // Handle any errors that might occur during the process
      print("Error getting user location: $e");
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Create the timer when the widget is initialized
    createTimer();
    _init();
  }

  Future<void> _init() async {
    await getUserLocation();
    print(city);
    setState(() {});
  }

  @override
  void dispose() {
    // Cancel the timer to prevent memory leaks when the widget is disposed
    _timer?.cancel();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(userEmail)
              .get(),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasData) {
                Map<String, dynamic>? userData =
                    snapshot.data?.data() as Map<String, dynamic>?;

                if (userData != null) {
                  String userName = userData['name'] ?? 'N/A';
                  String imageUrl = userData['profileImageUrl'] ?? '';
                  return Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : AssetImage('assets/images/defaultprofile.png')
                                as ImageProvider,
                      ),
                      SizedBox(width: 10),
                      Text(userName)
                    ],
                  );
                }
              }
            }

            return Text('User Name');
          },
        ),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .where('activityDateValue',
                isGreaterThanOrEqualTo: int.parse(
                    DateFormat('yyyyMMdd').format(widget.selectedDate)))
            .where('activityStatus', isEqualTo: 'Waiting')
            .where('activityCity', isEqualTo: city)
            .orderBy('activityDateValue')
            .orderBy('activityTimeValue')
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
                      if (activity['activityDate'] ==
                          DateFormat('dd-MM-yyyy').format(DateTime.now())) {
                        int activityTimeValue = activity['activityTimeValue'];
                        int currentTimeValue =
                            (timevalue.hour * 100) + timevalue.minute;
                        print('tes$currentTimeValue');

                        // Hide activities where the time is equal to or earlier than the current time
                        if (currentTimeValue >= activityTimeValue) {
                          return SizedBox
                              .shrink(); // Returns an empty widget, effectively hiding it
                        }
                      }

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
                                      SizedBox(height: 5),
                                      Text(
                                          'Location: ${activity['activityLocation']}'),
                                      SizedBox(height: 5),
                                      Text(
                                          'Fee: IDR ${_formatFee(activity['activityFee'])}'),
                                      SizedBox(height: 5),
                                      if (activity['activityType'] ==
                                              'Normal Activity' ||
                                          activity['activityType'] ==
                                              'Sparring')
                                        Text(
                                            'Duration in hour: ${activity['activityDuration']}'),
                                      if (activity['activityType'] ==
                                              'Normal Activity' ||
                                          activity['activityType'] ==
                                              'Sparring')
                                        SizedBox(height: 5),
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
                                      SizedBox(height: 5),
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
