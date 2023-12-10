import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserManagementPage extends StatelessWidget {
  Future<void> updateUserType(String userId, int userType) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'user_type': userType});
  }

  Future<void> updateUserTypeTo1(String userId) async {
    await updateUserType(userId, 1);
  }

  Future<void> updateUserTypeTo0(String userId) async {
    await updateUserType(userId, 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('User Management'),
          backgroundColor: Color.fromARGB(255, 230, 0, 0)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasData) {
            return ListView(
              children: snapshot.data!.docs.map((DocumentSnapshot document) {
                Map<String, dynamic> data =
                    document.data() as Map<String, dynamic>;
                String userId = document.id;
                String userName = data['name'];
                int userType = data['user_type'];

                return ListTile(
                  title: Text(userName),
                  subtitle: Text('User Type: $userType'),
                  trailing: userType == 0
                      ? IconButton(
                          icon: Icon(Icons.arrow_upward),
                          onPressed: () => updateUserTypeTo1(userId),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            SizedBox(width: 8.0),
                            IconButton(
                              icon: Icon(Icons.arrow_downward),
                              onPressed: () => updateUserTypeTo0(userId),
                            ),
                          ],
                        ),
                );
              }).toList(),
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
