import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sportifyapp/pages/activitylist_page.dart';
import 'package:sportifyapp/pages/inbox_page.dart';
import 'package:sportifyapp/pages/myactivity_page.dart';
import 'package:sportifyapp/pages/profile_page.dart';
import 'package:sportifyapp/pages/team_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 255, 102, 0),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 2;
  var updateTime; // Set the default tab to Home

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  var mToken = '';

  Future<void> firebasePermission() async {
    await Firebase.initializeApp();

    await FirebaseMessaging.instance.getInitialMessage();

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      getToken();
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      getToken();
    } else {}
    //FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    await FirebaseMessaging.instance.subscribeToTopic("topic");
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  Future<void> getToken() async {
    await FirebaseMessaging.instance.getToken().then((token) {
      log("token : $token");
      mToken = token ?? '';
    });
  }

  Future<void> _backgroundHandler(RemoteMessage message) async {
    print("Handling a background message: ${message.messageId}");
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

  @override
  void initState() {
    super.initState();
    firebasePermission();
  }

  final List<Widget> _pages = [
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
        selectedItemColor: const Color.fromARGB(255, 230, 0, 0),
        items: const [
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

  const PlaceholderWidget(this.color, this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
