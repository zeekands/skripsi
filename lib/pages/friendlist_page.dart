import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sportifyapp/pages/otheruserProfile_page.dart';

class FriendListPage extends StatelessWidget {
  final String? userEmail;

  const FriendListPage({Key? key, required this.userEmail}) : super(key: key);

  Future<List<String>> getFriendsList(String? userEmail) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      if (userDoc.exists) {
        List<dynamic> friendsList = userDoc['friends'] ?? [];
        return List<String>.from(friendsList);
      } else {
        return [];
      }
    } catch (e) {
      print('Error getting friends list: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend List'),
        backgroundColor: Color.fromARGB(255, 230, 0, 0),
        elevation: 0, // Set elevation to 0 to remove the shadow
      ),
      body: FutureBuilder<List<String>>(
        future: getFriendsList(userEmail),
        builder: (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            List<String> friendsList = snapshot.data ?? [];

            if (friendsList.isEmpty) {
              return Center(child: Text('No friends found.'));
            }

            return ListView.builder(
              padding: EdgeInsets.only(top: 0), // Add this line
              itemCount: friendsList.length,
              itemBuilder: (BuildContext context, int index) {
                String friendEmail = friendsList[index];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendEmail)
                      .get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (userSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${userSnapshot.error}'));
                    } else if (!userSnapshot.hasData ||
                        !userSnapshot.data!.exists) {
                      // Handle the case where user data is not available
                      return Card(
                        child: ListTile(
                          title: Text(friendEmail),
                          subtitle: Text('User data not available'),
                        ),
                      );
                    } else {
                      // Extract user data
                      Map<String, dynamic> userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      String profileImageUrl =
                          userData['profileImageUrl'] ?? '';
                      String userName = userData['name'] ?? 'Unknown';
                      String userAge = userData['age'] ?? 'Unknown';

                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => OtherUserProfilePage(
                                userData: userData,
                                userEmail: friendEmail,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : AssetImage(
                                              'assets/images/defaultprofile.png')
                                          as ImageProvider,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            title: Text(userName),
                            subtitle: Text(userAge),
                            // You can add more details or actions related to each friend
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
