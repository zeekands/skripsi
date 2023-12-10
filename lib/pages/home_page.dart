import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportifyapp/pages/activitylist_page.dart';
import 'package:sportifyapp/pages/inbox_page.dart';
import 'package:sportifyapp/pages/myactivity_page.dart';
import 'package:sportifyapp/pages/profile_page.dart';
import 'package:sportifyapp/pages/team_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 255, 102, 0),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;
  var updateTime; // Set the default tab to Home

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  // var ctr = 1;

  // createTimer() {
  //   final timer = Timer(
  //     const Duration(minutes: 1),
  //     () {
  //       updateTime = TimeOfDay.now();
  //       // Navigate to your favorite place
  //       print(updateTime);
  //       createTimer();
  //     },
  //   );
  // }

  // @override
  // void initState() {
  //   super.initState();
  //   print("Inside wx");
  //   createTimer();
  //   try {
  //     print("abc");

  //     /*
  //     print("abc");
  //     if (timer.isActive) {
  //       print("active");
  //     } else {
  //       print("not active");
  //     }*/
  //   } catch (err) {
  //     print("error");
  //     print(err);
  //   }
  // }

  List<Widget> _pages = [
    MyActivityPage(),
    TeamPage(),
    ActivityListPage(
        selectedDate: DateTime.now(), selectedTime: TimeOfDay.now()),
    InboxPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color.fromARGB(255, 230, 0, 0),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'My Activity',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Team',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inbox),
            label: 'Inbox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class PlaceholderWidget extends StatelessWidget {
  final Color color;
  final String title;

  PlaceholderWidget(this.color, this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
