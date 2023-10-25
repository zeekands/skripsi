import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityDetailsPage extends StatelessWidget {
  final String activityID;

  ActivityDetailsPage(this.activityID);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Activity Details'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      backgroundColor: Color.fromARGB(255, 230, 0, 0),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('activities')
            .doc(activityID)
            .snapshots(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          var activity = snapshot.data;

          if (activity == null || !activity.exists) {
            return Center(child: Text('Activity not found'));
          }

          return Container(
            width: double.infinity, // Set width to maximum available
            padding: EdgeInsets.all(16.0),
            margin: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 3,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      alignment: Alignment.topLeft, // Center text horizontally
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Activity Name:'),
                          SizedBox(height: 10),
                          Text('Sport: '),
                          SizedBox(height: 10),
                          Text('Host: '),
                          SizedBox(height: 10),
                          Text('Location: '),
                          SizedBox(height: 10),
                          Text('Date: '),
                          SizedBox(height: 10),
                          Text('Time: '),
                          SizedBox(height: 10),
                          Text('Fee: '),
                          SizedBox(height: 10),
                          Text('Description: '),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 10.0, horizontal: 10.0),
                      child: Container(
                        alignment:
                            Alignment.topLeft, // Center text horizontally
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${activity['activityTitle']}'),
                            SizedBox(height: 10),
                            Text('${activity['sportName']}'),
                            SizedBox(height: 10),
                            Text('${activity['user_email']}'),
                            SizedBox(height: 10),
                            Text('${activity['activityLocation']}'),
                            SizedBox(height: 10),
                            Text('${activity['activityDate']}'),
                            SizedBox(height: 10),
                            Text('${activity['activityTime']}'),
                            SizedBox(height: 10),
                            Text('${activity['activityFee']}'),
                            SizedBox(height: 10),
                            Text('${activity['activityDescription']}'),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 16.0), // Add some space
                Text(
                  'Participants:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                StreamBuilder(
                  stream: FirebaseFirestore.instance
                      .collection('participants')
                      .where('activity_id', isEqualTo: activityID)
                      .snapshots(),
                  builder: (
                    BuildContext context,
                    AsyncSnapshot<QuerySnapshot> snapshot,
                  ) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    }

                    var participants = snapshot.data!.docs;

                    if (participants.isEmpty) {
                      return Text('No participants found for this activity.');
                    }

                    return Column(
                      children: participants
                          .map((participant) => Text(participant['user_email']))
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
