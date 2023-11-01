import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportifyapp/pages/editprofile_page.dart';

import 'addprofileSport.dart';
import 'adminpanel_page.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    void signUserOut() {
      FirebaseAuth.instance.signOut();
    }

    Future<List<String>> getCommendationImageUrls() async {
      // List of commendation image file names
      List<String> commendationImageFileNames = [
        'skillfull.png',
        'teamplayer.png',
        'sportmanship.png',
        'friendly.png',
      ];

      List<String> urls = [];

      for (var fileName in commendationImageFileNames) {
        Reference ref =
            FirebaseStorage.instance.ref().child('commendations/$fileName');
        String url = await ref.getDownloadURL();
        urls.add(url);
      }

      return urls;
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .snapshots(),
      builder:
          (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.active &&
            snapshot.hasData) {
          Map<String, dynamic>? userData =
              snapshot.data!.data() as Map<String, dynamic>?;

          if (userData != null) {
            String? name = userData['name'];
            String? age = userData['age'];
            String? gender = userData['gender'];
            String? bio = userData['bio'];
            int? userType = userData['user_type'];

            return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text('Profile'),
                  actions: [
                    IconButton(
                      icon:
                          Icon(Icons.edit), // You can choose any icon you want
                      onPressed: () {
                        // Handle the edit button press
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditProfilePage(user: user),
                          ),
                        );
                      },
                      color: Colors.grey, // Set the icon color
                    ),
                    IconTheme(
                      data: IconThemeData(color: Colors.grey),
                      child: PopupMenuButton<String>(
                        onSelected: (choice) {
                          if (choice == 'edit_profile') {
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        EditProfilePage(user: user),
                                  ),
                                );
                              },
                              child: Text('Edit Profile'),
                            );
                          } else if (choice == 'admin_panel' && userType == 1) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AdminPanelPage(),
                              ),
                            );
                          } else if (choice == 'logout') {
                            FirebaseAuth.instance.signOut();
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return [
                            if (userType == 1)
                              PopupMenuItem<String>(
                                value: 'admin_panel',
                                child: Text('Admin Panel'),
                              ),
                            PopupMenuItem<String>(
                              value: 'edit_profile',
                              child: Text('Edit Profile'),
                            ),
                            PopupMenuItem<String>(
                              value: 'logout',
                              child: Text('Logout'),
                            ),
                          ];
                        },
                      ),
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Handle the click event here
                          print('Clicked on CircleAvatar');
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: PopupMenuButton<int>(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 1,
                                  child: Text('Upload Image'),
                                ),
                                PopupMenuItem(
                                  value: 2,
                                  child: Text('Delete Image'),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 1) {
                                  // Handle Upload Image option
                                  print('Upload Image');
                                } else if (value == 2) {
                                  // Handle Delete Image option
                                  print('Delete Image');
                                }
                              },
                              child: CircleAvatar(
                                radius: 64,
                                backgroundImage: NetworkImage(
                                  'https://t4.ftcdn.net/jpg/00/64/67/63/360_F_64676383_LdbmhiNM6Ypzb3FM4PPuFP9rHe7ri8Ju.jpg',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$name',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '$age',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '$gender',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 5),
                            Text(
                              '$bio',
                              style: TextStyle(fontSize: 18),
                            ),
                            SizedBox(height: 5),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 3.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  commendationImage(
                                      'skillfull.png', 'Skillfull', 0),
                                  commendationImage(
                                      'friendly.png', 'Positive', 0),
                                  commendationImage(
                                      'teamplayer.png', 'Teamwork', 0),
                                  commendationImage(
                                      'sportmanship.png', 'Sportsmanship', 0),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SPORTS',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                                child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddSportPage(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: 'Add Sport',
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 230, 0, 0),
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                      Card(
                        color: Colors.transparent,
                        elevation: 0,
                        child: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('skilllevel')
                                .where('email', isEqualTo: user!.email)
                                .snapshots(),
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else {
                                var data = snapshot.data!.docs;
                                if (data.isNotEmpty) {
                                  return Column(
                                    children: data.map((doc) {
                                      var selfRating = doc['selfRating'];
                                      var selfRatingSport = doc['sportName'];
                                      return FutureBuilder<QuerySnapshot>(
                                        future: FirebaseFirestore.instance
                                            .collection('sports')
                                            .where('sport_name',
                                                isEqualTo: selfRatingSport)
                                            .get(),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<QuerySnapshot>
                                                snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return CircularProgressIndicator();
                                          } else if (snapshot.hasError) {
                                            return Text(
                                                'Error: ${snapshot.error}');
                                          } else {
                                            var sportData =
                                                snapshot.data!.docs[0].data()
                                                    as Map<String, dynamic>?;
                                            if (sportData != null) {
                                              var sportImage =
                                                  sportData['sport_image'];
                                              return Card(
                                                margin: EdgeInsets.all(16.0),
                                                child: Padding(
                                                  padding: EdgeInsets.all(16.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Container(
                                                            width: 50,
                                                            height: 50,
                                                            child:
                                                                Image.network(
                                                                    sportImage),
                                                          ),
                                                          SizedBox(width: 5),
                                                          Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .start,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                selfRatingSport,
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold, // Makes the text bold
                                                                  fontSize:
                                                                      20, // Adjust the font size as needed
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 2),
                                                              Text(selfRating),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            } else {
                                              return Text(
                                                  'Sport data not found');
                                            }
                                          }
                                        },
                                      );
                                    }).toList(),
                                  );
                                } else {
                                  return Text('Self Rating not available');
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ));
          }
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget commendationImage(String imageName, String name, int number) {
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
            Text('$number'),
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
}


// class TabbedSportsContent extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     User? user = FirebaseAuth.instance.currentUser;

//     return StreamBuilder<QuerySnapshot>(
//       stream: FirebaseFirestore.instance.collection('sports').snapshots(),
//       builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else {
//           List<QueryDocumentSnapshot> sportsList = snapshot.data!.docs;
//           List<Tab> tabs = [];
//           List<Widget> tabContents = [];

//           for (var sportDoc in sportsList) {
//             String sportName = sportDoc['sport_name'];
//             String sportImage = sportDoc['sport_image'];
//             tabs.add(Tab(icon: Image.network(sportImage)));
//             tabContents.add(TabContent(sportName: sportName));
//           }

//           return DefaultTabController(
//             length: tabs.length,
//             child: Column(
//               children: [
//                 Container(
//                   margin: const EdgeInsets.all(4.0),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(50),
//                     border: Border.all(color: Colors.black, width: 1),
//                   ),
//                   child: TabBar(
//                     isScrollable: true,
//                     indicator: BoxDecoration(
//                         borderRadius: BorderRadius.circular(50),
//                         color: Color.fromARGB(255, 230, 0, 0)),
//                     tabs: tabs.map((tab) {
//                       return Tab(
//                         icon: Container(
//                           // decoration: BoxDecoration(
//                           //   borderRadius: BorderRadius.circular(50),
//                           //   border:
//                           //       Border.all(color: Colors.redAccent, width: 1),
//                           // ),
//                           child: tab.icon,
//                         ),
//                       );
//                     }).toList(),
//                     // labelColor: Colors.white,
//                     // indicatorColor: Colors.white,
//                   ),
//                 ),
//                 Expanded(
//                   child: TabBarView(
//                     children: tabContents,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }
//       },
//     );
//   }
// }

// class TabContent extends StatelessWidget {
//   final String sportName;

//   TabContent({required this.sportName});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder(
//       future: FirebaseFirestore.instance
//           .collection('sports')
//           .where('sport_name', isEqualTo: sportName)
//           .get(),
//       builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//         if (snapshot.connectionState == ConnectionState.waiting) {
//           return Center(child: CircularProgressIndicator());
//         } else if (snapshot.hasError) {
//           return Center(child: Text('Error: ${snapshot.error}'));
//         } else if (snapshot.data!.docs.isNotEmpty) {
//           var data = snapshot.data!.docs[0].data() as Map<String, dynamic>?;
//           var sportName = data?['sport_name'];
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: <Widget>[
//                 Text(
//                   'Skill Level ' + sportName + ' : Beginner' ??
//                       'Sport Name Unavailable',
//                   style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           );
//         } else {
//           return Center(child: Text('Sport Not Found'));
//         }
//       },
//     );
//   }
// }
