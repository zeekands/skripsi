import 'package:flutter/material.dart';

import 'create_activity.dart';

class ActivityTypeChoosePage extends StatelessWidget {
  Widget _buildActivityButton(
      String label, String activityType, BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreateActivityPage(activityType: activityType),
          ),
        );
      },
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        textStyle: TextStyle(fontSize: 20),
        primary: Colors.white,
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        side: BorderSide(color: Color.fromARGB(255, 230, 0, 0)),
      ),
      child: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Activity Type'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildActivityButton('Normal Activity', 'Normal Activity', context),
            SizedBox(height: 20),
            _buildActivityButton('Tournament', 'Tournament', context),
            SizedBox(height: 20),
            _buildActivityButton('Sparring', 'Sparring', context),
          ],
        ),
      ),
    );
  }
}
