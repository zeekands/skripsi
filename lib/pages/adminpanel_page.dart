import 'package:flutter/material.dart';
import 'package:sportifyapp/pages/sportmanagement_page.dart';
import 'package:sportifyapp/pages/usermanagement_page.dart';

import 'locationmanagement_page.dart';

class AdminPanelPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 230, 0, 0),
          title: Text('Admin Panel')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: double.infinity, // Set maximum width
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SportsManagementPage(),
                    ),
                  );
                },
                child: Text('Sports Management'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 230, 0, 0),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity, // Set maximum width
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationManagementPage(),
                    ),
                  );
                },
                child: Text('Location Management'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 230, 0, 0),
                ),
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: double.infinity, // Set maximum width
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserManagementPage(),
                    ),
                  );
                },
                child: Text('User Management'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 230, 0, 0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
