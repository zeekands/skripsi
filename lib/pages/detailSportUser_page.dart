import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'activity_detail.dart';

class DetailSportUserPage extends StatelessWidget {
  final String? userEmail;
  final String? sportName;

  List<String> activityIds = [];

  DetailSportUserPage({required this.userEmail, required this.sportName});

  Future<List<Map<String, dynamic>>> getCommendationsData(
      String? userEmail, String? sportName) async {
    var commendationsData = await FirebaseFirestore.instance
        .collection('commendations')
        .where('toUser', isEqualTo: userEmail)
        .where('activitySport', isEqualTo: sportName)
        .get();

    List<Map<String, dynamic>> commendations = [];

    for (var doc in commendationsData.docs) {
      var commendationData = doc.data() as Map<String, dynamic>;
      var activitySport = commendationData['activitySport'] as String?;

      // Check if the commendation is for the specified sport
      if (activitySport != null && activitySport == sportName) {
        commendations.add(commendationData);
      }
    }

    return commendations;
  }

  Future<List<String>> getActivityID(
      String? userEmail, String? sportName) async {
    try {
      var participantSnapshot = await FirebaseFirestore.instance
          .collection('participants')
          .where('user_email', isEqualTo: userEmail)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      var activityIds = participantSnapshot.docs
          .map((doc) => doc['activity_id'].toString())
          .toList();

      // Fetch activity IDs from 'activities' collection based on sportName
      var activitiesSnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where(FieldPath.documentId, whereIn: activityIds)
          .where('sportName', isEqualTo: sportName)
          .where('activityStatus', isEqualTo: 'Completed')
          .get();

      // Extract filtered activity IDs
      var filteredActivityIds =
          activitiesSnapshot.docs.map((doc) => doc.id).toList();
      print(filteredActivityIds);

      return filteredActivityIds;
    } catch (e) {
      print('Error fetching completed activity: $e');
      return [];
    }
  }

  Future<int> getActivityCompleteCount(
      String? userEmail, String? sportName) async {
    try {
      // print(userEmail);
      // print(sportName);
      // var participantSnapshot = await FirebaseFirestore.instance
      //     .collection('participants')
      //     .where('user_email', isEqualTo: userEmail)
      //     .where('status', isEqualTo: 'Confirmed')
      //     .get();

      // // Get the list of activity IDs
      // var activityIds = participantSnapshot.docs
      //     .map((doc) => doc['activity_id'].toString())
      //     .toList();

      // print('a$activityIds');
      // Query activities collection to count completed activities
      var activityCompleteSnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .where('sportName', isEqualTo: sportName)
          .where('activityType', isEqualTo: 'Normal Activity')
          .where('activityStatus', isEqualTo: 'Completed')
          .get();

      print('b$activityCompleteSnapshot');

      // Return the count of completed activities
      return activityCompleteSnapshot.size;
    } catch (e) {
      // Handle any errors that occurred during the process
      print('Error getting activity completion count: $e');
      return 0;
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
      QuerySnapshot snapshot =
          await brackets.where('activity_id', isEqualTo: activityId).get();

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
                  return Text(userName);
                }
              }
            }

            return Text('User Name');
          },
        ),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('skilllevel')
              .where('email', isEqualTo: userEmail)
              .where('sportName', isEqualTo: sportName)
              .get(),
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot> skillSnapshot) {
            if (skillSnapshot.connectionState == ConnectionState.done) {
              if (skillSnapshot.hasData &&
                  skillSnapshot.data!.docs.isNotEmpty) {
                Map<String, dynamic> skillData =
                    skillSnapshot.data!.docs[0].data() as Map<String, dynamic>;

                if (skillData.isNotEmpty) {
                  String selfRatingSport = skillData['sportName'] ?? '0.0';
                  String selfRating = skillData['selfRating'] ?? '0.0';

                  // Additional query to get sport_image
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('sports')
                        .where('sport_name', isEqualTo: selfRatingSport)
                        .get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<QuerySnapshot> sportSnapshot) {
                      if (sportSnapshot.connectionState ==
                          ConnectionState.done) {
                        if (sportSnapshot.hasData &&
                            sportSnapshot.data!.docs.isNotEmpty) {
                          Map<String, dynamic> sportData =
                              sportSnapshot.data!.docs[0].data()
                                  as Map<String, dynamic>;

                          if (sportData.isNotEmpty) {
                            String sportImage = sportData['sport_image'] ??
                                ''; // Set your sportImage URL here

                            return Card(
                              margin: EdgeInsets.all(16.0),
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            child: Image.network(sportImage),
                                          ),
                                          Text(
                                            selfRatingSport,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FutureBuilder<List<Map<String, dynamic>>>(
                                      future: getCommendationsData(
                                          userEmail, selfRatingSport),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<
                                                  List<Map<String, dynamic>>>
                                              commendationSnapshot) {
                                        if (commendationSnapshot
                                                .connectionState ==
                                            ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (commendationSnapshot
                                            .hasError) {
                                          return Text(
                                              'Error: ${commendationSnapshot.error}');
                                        } else {
                                          List<Map<String, dynamic>>
                                              commendations =
                                              commendationSnapshot.data!;
                                          int totalCommendation1 = 0;
                                          int totalCommendation2 = 0;
                                          int totalCommendation3 = 0;
                                          int totalCommendation4 = 0;

                                          for (var commendationData
                                              in commendations) {
                                            totalCommendation1 +=
                                                commendationData[
                                                            'commendation1']
                                                        as int? ??
                                                    0;
                                            totalCommendation2 +=
                                                commendationData[
                                                            'commendation2']
                                                        as int? ??
                                                    0;
                                            totalCommendation3 +=
                                                commendationData[
                                                            'commendation3']
                                                        as int? ??
                                                    0;
                                            totalCommendation4 +=
                                                commendationData[
                                                            'commendation4']
                                                        as int? ??
                                                    0;
                                          }

                                          int count = commendations.length;

                                          // Calculate the average commendation for each type
                                          double averageCommendation1 =
                                              count > 0
                                                  ? totalCommendation1 / count
                                                  : 0.0;
                                          double averageCommendation2 =
                                              count > 0
                                                  ? totalCommendation2 / count
                                                  : 0.0;
                                          double averageCommendation3 =
                                              count > 0
                                                  ? totalCommendation3 / count
                                                  : 0.0;
                                          double averageCommendation4 =
                                              count > 0
                                                  ? totalCommendation4 / count
                                                  : 0.0;

                                          // You can use these averages as needed
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              commendationImage(
                                                  'skillfull.png',
                                                  'Skillfull',
                                                  averageCommendation1),
                                              commendationImage(
                                                  'friendly.png',
                                                  'Positive',
                                                  averageCommendation2),
                                              commendationImage(
                                                  'teamplayer.png',
                                                  'Teamwork',
                                                  averageCommendation3),
                                              commendationImage(
                                                  'sportmanship.png',
                                                  'Sportsmanship',
                                                  averageCommendation4),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Self Rating : ",
                                            style: TextStyle(
                                              fontSize:
                                                  18, // Adjust the font size as needed
                                            ),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            selfRating,
                                            style: TextStyle(
                                              fontSize:
                                                  24, // Adjust the font size as needed
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    FutureBuilder<List<String>>(
                                      future:
                                          getActivityID(userEmail, sportName),
                                      builder: (BuildContext context,
                                          AsyncSnapshot<List<String>>
                                              activityIdSnapshot) {
                                        if (activityIdSnapshot
                                                .connectionState ==
                                            ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (activityIdSnapshot
                                            .hasError) {
                                          return Text(
                                              'Error: ${activityIdSnapshot.error}');
                                        } else {
                                          List<String> activityIds =
                                              activityIdSnapshot.data ?? [];

                                          // Use the activityCompleteCount as needed in your widget tree
                                          return Column(
                                            children: [
                                              Center(
                                                child: Text(
                                                  'Activity Completed: ${activityIds.length}',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              // Display activity IDs in a Column of Cards
                                              Column(
                                                children: activityIds
                                                    .map((activityId) {
                                                  return FutureBuilder<
                                                      DocumentSnapshot>(
                                                    future: FirebaseFirestore
                                                        .instance
                                                        .collection(
                                                            'activities')
                                                        .doc(activityId)
                                                        .get(),
                                                    builder: (BuildContext
                                                            context,
                                                        AsyncSnapshot<
                                                                DocumentSnapshot>
                                                            activitySnapshot) {
                                                      if (activitySnapshot
                                                              .connectionState ==
                                                          ConnectionState
                                                              .waiting) {
                                                        return CircularProgressIndicator();
                                                      } else if (activitySnapshot
                                                          .hasError) {
                                                        return Text(
                                                            'Error: ${activitySnapshot.error}');
                                                      } else {
                                                        var activityData =
                                                            activitySnapshot
                                                                    .data
                                                                    ?.data()
                                                                as Map<String,
                                                                    dynamic>?;
                                                        if (activityData !=
                                                            null) {
                                                          // Wrap the Card with GestureDetector for making it clickable
                                                          return GestureDetector(
                                                            onTap: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) =>
                                                                      ActivityDetailsPage(
                                                                          activityId),
                                                                ),
                                                              );
                                                            },
                                                            child: Card(
                                                              child: ListTile(
                                                                title: Text(
                                                                    'Title: ${activityData['activityTitle']}'),
                                                                subtitle: Text(
                                                                    'Date: ${activityData['activityDate']}'), // Add more details if needed
                                                              ),
                                                            ),
                                                          );
                                                        } else {
                                                          return Text(
                                                              'Activity data not found');
                                                        }
                                                      }
                                                    },
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        }
                      }

                      return Text('Sport data not found');
                    },
                  );
                }
              }
            }

            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

Widget commendationImage(String imageName, String name, double number) {
  return Column(
    children: [
      Image.asset(
        'assets/images/$imageName',
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
          return Container(
            width: 80,
            height: 80,
            color: Colors.red,
            margin: EdgeInsets.all(5),
          );
        },
      ),
      Row(
        children: [
          Text('${number.toStringAsFixed(1)}'),
          Image.asset(
            'assets/images/star.png',
            width: 20,
            height: 20,
          ),
        ],
      ),
      Text(name),
    ],
  );
}
