import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'activity_detail.dart';

class CreateActivityPage extends StatefulWidget {
  final String activityType;

  CreateActivityPage({required this.activityType});

  @override
  _CreateActivityPageState createState() => _CreateActivityPageState();
}

class _CreateActivityPageState extends State<CreateActivityPage> {
  String? selectedSport;
  TextEditingController activityTitleController = TextEditingController();
  TextEditingController activityLocationController = TextEditingController();
  TextEditingController activityTimeController = TextEditingController();
  TextEditingController activityDateController = TextEditingController();
  TextEditingController activityDescriptionController = TextEditingController();
  TextEditingController activityFeeController = TextEditingController();
  TextEditingController activityDurationController = TextEditingController();
  TextEditingController activityQuotaController = TextEditingController();
  TextEditingController registrationStartController = TextEditingController();
  TextEditingController registrationEndController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();
  String? userEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  Future<void> showStatusDialog(String status) async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Status'),
          content: Text(status),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
      });
    }
  }

  void addActivity() async {
    try {
      // Get a reference to the Firestore collection
      CollectionReference activities =
          FirebaseFirestore.instance.collection('activities');

      // Get the next available integer ID
      int nextActivityID = await getNextActivityID();
      int nextParticipantID = await getNextParticipantID();

      String? userTeamCategory;

      if (widget.activityType == 'Sparring') {
        userTeamCategory = await getTeamCategory();

        if (userTeamCategory != widget.activityType) {
          await showStatusDialog(
              'You must be in a team with the same category to create a Sparring activity.');
          return;
        }
      }

      // Add a new document with the custom ID
      await activities.doc(nextActivityID.toString()).set({
        'activityType': widget.activityType,
        'sportName': selectedSport,
        'activityTitle': activityTitleController.text,
        'activityLocation': activityLocationController.text,
        'activityTime': '${selectedTime.hour}:${selectedTime.minute}',
        'activityDate': DateFormat('dd-MM-yyyy').format(selectedDate),
        'activityFee': activityFeeController.text,
        'activityDescription': activityDescriptionController.text,
        'user_email': userEmail,
        if (widget.activityType == 'Normal Activity' ||
            widget.activityType == 'Tournament')
          'activityQuota': int.parse(activityQuotaController.text),
        if (widget.activityType == 'Tournament')
          'registrationStart': registrationStartController.text,
        if (widget.activityType == 'Tournament')
          'registrationEnd': registrationEndController.text,
        if (widget.activityType == "Normal Activity") // Add this condition
          'activityisPrivate': isPrivate,
        if (widget.activityType == "Tournament" ||
            widget.activityType == "Sparring")
          'activityisPrivate': true,
        if (widget.activityType == "Normal Activity" ||
            widget.activityType == "Sparring")
          'activityDuration': activityDurationController.text,
        'activityStatus': 'Waiting',
      });

      if (widget.activityType == 'Normal Activity')
        addParticipant(nextActivityID.toString(), userEmail!);

      await updateLatestActivityID(nextActivityID);

      await showStatusDialog('Activity created successfully!');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ActivityDetailsPage(nextActivityID.toString()),
        ),
      );
    } catch (e) {
      // Handle errors here
      print('Error adding activity: $e');
      await showStatusDialog('Error creating activity');
    }
  }

  Future<void> addParticipant(String activityID, String userEmail) async {
    try {
      // Get a reference to the participants collection
      CollectionReference participants =
          FirebaseFirestore.instance.collection('participants');

      // Get the next participant ID
      int participantID = await getNextParticipantID();

      // Add the participant
      await participants.doc(participantID.toString()).set({
        'activity_id': activityID,
        'user_email': userEmail,
        'status': 'Confirmed', // You can set an initial status if needed
      });

      await updateLatestParticipantID(participantID);
    } catch (e) {
      // Handle errors here
      print('Error adding participant: $e');
    }
  }

  Future<int> getNextParticipantID() async {
    // Assuming you have a separate collection for managing IDs
    CollectionReference idCollection =
        FirebaseFirestore.instance.collection('latest_participant_id');
    DocumentSnapshot snapshot = await idCollection.doc('latest_id').get();
    int latestID = snapshot.exists ? snapshot['id'] : 0;
    print(latestID);
    return latestID + 1;
  }

  Future<int> getNextActivityID() async {
    // Assuming you have a separate collection for managing IDs
    CollectionReference idCollection =
        FirebaseFirestore.instance.collection('latest_activities_id');
    DocumentSnapshot snapshot = await idCollection.doc('latest_id').get();
    int latestID = snapshot.exists ? snapshot['id'] : 0;
    print(latestID);
    return latestID + 1;
  }

  Future<void> updateLatestActivityID(int latestID) async {
    CollectionReference idCollection =
        FirebaseFirestore.instance.collection('latest_activities_id');
    await idCollection.doc('latest_id').set({'id': latestID});
  }

  Future<void> updateLatestParticipantID(int latestID) async {
    CollectionReference idCollection =
        FirebaseFirestore.instance.collection('latest_participant_id');
    await idCollection.doc('latest_id').set({'id': latestID});
  }

  Future<String?> getTeamCategory() async {
    var userEmail = FirebaseAuth.instance.currentUser?.email;

    if (userEmail != null) {
      var userTeamSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .where('team_creator_email', isEqualTo: userEmail)
          .get();

      if (userTeamSnapshot.docs.isNotEmpty) {
        return userTeamSnapshot.docs.first['team_sport'];
      }
    }

    return null;
  }

  Future<bool> canCreateActivity() async {
    var teamCategory = await getTeamCategory();
    return teamCategory == 'Sparring';
  }

  bool isPrivate = false;

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Activity'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity Type: ${widget.activityType}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('sports').snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Loading indicator
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
                  value: selectedSport,
                  items: items,
                  onChanged: (value) {
                    setState(() {
                      selectedSport = value;
                    });
                  },
                  decoration: InputDecoration(labelText: 'Sport Name'),
                );
              },
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Activity Title'),
              controller: activityTitleController,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Activity Location'),
              controller: activityLocationController,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Time Start'),
              style: TextStyle(fontSize: 20),
              onTap: () => _selectTime(context),
              controller: TextEditingController(
                text:
                    "${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}",
              ),
              readOnly: true,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Date Start'),
              style: TextStyle(fontSize: 20),
              onTap: () => _selectDate(context),
              controller: TextEditingController(
                text:
                    "${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.year}",
              ),
              readOnly: true,
            ),
            TextFormField(
              decoration:
                  InputDecoration(labelText: 'Activity Fee(per person)'),
              controller: activityFeeController,
            ),
            if (widget.activityType == 'Normal Activity' ||
                widget.activityType == 'Sparring')
              TextFormField(
                decoration:
                    InputDecoration(labelText: 'Activity Duration in hour'),
                controller: activityDurationController,
              ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Activity Description'),
              controller: activityDescriptionController,
            ),
            if (widget.activityType == 'Normal Activity' ||
                widget.activityType == 'Tournament')
              TextFormField(
                decoration: InputDecoration(labelText: 'Activity Quota'),
                controller: activityQuotaController,
              ),
            if (widget.activityType == 'Tournament')
              TextFormField(
                decoration: InputDecoration(
                    labelText: 'Registration Start (Date & Time)'),
                controller: registrationStartController,
              ),
            if (widget.activityType == 'Tournament')
              TextFormField(
                decoration: InputDecoration(
                    labelText: 'Registration End (Date & Time)'),
                controller: registrationEndController,
              ),
            SizedBox(height: 20),
            if (widget.activityType == 'Normal Activity') // Add this condition
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20),
                  Text(
                    'Privacy:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  RadioListTile(
                    value: false,
                    groupValue: isPrivate,
                    onChanged: (value) {
                      setState(() {
                        isPrivate = false;
                      });
                    },
                    title: Text('Anyone can join'),
                  ),
                  RadioListTile(
                    value: true,
                    groupValue: isPrivate,
                    onChanged: (value) {
                      setState(() {
                        isPrivate = true;
                      });
                    },
                    title: Text('Private'),
                  ),
                ],
              ),
            ElevatedButton(
              onPressed: () {
                addActivity(); // Handle the submission of the form here
                // You can access the entered values using the controllers
              },
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
