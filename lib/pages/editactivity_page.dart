import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditActivityPage extends StatefulWidget {
  final String activityId;

  EditActivityPage({required this.activityId});

  @override
  _EditActivityPageState createState() => _EditActivityPageState();
}

class _EditActivityPageState extends State<EditActivityPage> {
  // Add necessary controllers for your text fields
  TextEditingController titleController = TextEditingController();
  TextEditingController quotaController = TextEditingController();
  TextEditingController registrationStartController = TextEditingController();
  TextEditingController durationController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController feeController = TextEditingController();
  // Add more controllers as needed

  String activityType = '';
  String activityDescription = '';
  String activityDuration = '';
  String activityFee = '';
  String activityPrizepool = '';

  Future<void> editActivity() async {
    try {
      // Get the values from the controllers
      String title = titleController.text;
      String description = descriptionController.text;
      String duration = durationController.text;
      String fee = feeController.text;
      String quota = quotaController.text;
      String registrationStart = registrationStartController.text;

      // Create a map with the updated data
      Map<String, dynamic> updatedData = {
        'activityTitle': title,
        'activityDescription': description,
        'activityDuration': duration,
        'activityFee': fee,
      };

      // Include additional fields based on your requirements
      if (activityType == 'Normal Activity' || activityType == 'Tournament') {
        updatedData['activityQuota'] = int.tryParse(quota) ?? 0;
      }

      if (activityType == 'Tournament') {
        updatedData['registrationStart'] = registrationStart;
      }

      // Update the activity in Firestore
      await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activityId)
          .update(updatedData);

      // Navigate back after editing
      Navigator.pop(context);
    } catch (e) {
      // Handle errors, e.g., show an error message
      print('Error updating activity: $e');
      // You can also show an error message to the user if needed
      // For example, using a SnackBar:
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update activity. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch activity data when the page is initialized
    fetchActivityData();
  }

  Future<void> fetchActivityData() async {
    try {
      // Query the activities collection to get the data of the specific activity
      DocumentSnapshot activitySnapshot = await FirebaseFirestore.instance
          .collection('activities')
          .doc(widget.activityId)
          .get();

      // Extract data from the snapshot
      Map<String, dynamic> activityData =
          activitySnapshot.data() as Map<String, dynamic>;

      // Set the text field controllers with the retrieved data
      setState(() {
        titleController.text = activityData['activityTitle'] ?? '';
        quotaController.text = activityData['activityQuota']?.toString() ?? '';
        registrationStartController.text =
            activityData['registrationStart'] ?? '';
        activityType = activityData['activityType'] ?? '';
        descriptionController.text = activityData['activityDescription'] ?? '';
        durationController.text = activityData['activityDuration'] ?? '';
        feeController.text = activityData['activityFee'] ?? '';
      });
    } catch (e) {
      // Handle errors, e.g., show an error message
      print('Error fetching activity data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Activity'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: durationController,
                decoration: InputDecoration(
                  labelText: 'Duration',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(height: 16.0),
              TextField(
                controller: feeController,
                decoration: InputDecoration(
                  labelText: 'Fee',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black, width: 2.0),
                  ),
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              SizedBox(height: 16.0),
              if (activityType == 'Normal Activity' ||
                  activityType == 'Tournament')
                TextField(
                  controller: quotaController,
                  decoration: InputDecoration(
                    labelText: 'Quota',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                ),
              SizedBox(height: 16.0),
              if (activityType == 'Tournament')
                TextField(
                  controller: registrationStartController,
                  decoration: InputDecoration(
                    labelText: 'Registration Start',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black, width: 2.0),
                    ),
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                ),
              SizedBox(height: 16.0),
              // Add more text fields as needed

              ElevatedButton(
                onPressed: editActivity,
                child: Text('Update Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 230, 0, 0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
