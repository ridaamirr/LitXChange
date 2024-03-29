import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Image.asset(
          'assets/images/logo.png', // Path to your logo image
          height: 120, // Adjust height as needed
          width: 200, // Adjust width as needed
        ),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isNotEqualTo: currentUserUid)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final posts = snapshot.data!.docs;
          return ListView.separated(
            itemCount: posts.length,
            separatorBuilder: (BuildContext context, int index) => SizedBox(height: 8.0), // Add margin between posts
            itemBuilder: (context, index) {
              var post = posts[index];
              var date = post['date'].toDate();
              var postId = post['postId'];
              var formattedDate = DateFormat.yMMMMd().format(date);
              return FutureBuilder(
                future: _fetchUsername(post['userId']), // Fetch username
                builder: (context, AsyncSnapshot<String> usernameSnapshot) {
                  if (usernameSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (usernameSnapshot.hasError) {
                    return Text('Error: ${usernameSnapshot.error}');
                  } else {
                    String username =
                        usernameSnapshot.data ?? 'Unknown User';
                    String authorName =
                        post['authorName'] ?? 'Unknown Author'; // Fetch authorName from the post
                    String bookCondition =
                        post['condition'] ?? 'Unknown Condition'; // Fetch book condition from the post
                    return Container(
                      width: MediaQuery.of(context).size.width, // Set width to screen width
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor, // Use the same background color as the card
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              formattedDate,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ListTile(
                            title: Text(
                              '${post['bookName']} by $authorName', // Display author's name separately
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Condition: $bookCondition'),
                                Text(post['genre']),
                              ],
                            ),
                          ),
                          post['imageUrl'] != null
                              ? Image.network(
                            post['imageUrl'],
                            fit: BoxFit.cover,
                          )
                              : SizedBox.shrink(), // Placeholder for image if not available
                          SizedBox(height: 8.0),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  username,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.swap_horiz),
                                  onPressed: () {
                                    sendReq(context, postId);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }



Future<String> _fetchUsername(String userId) async {
    try {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userData['userName'] ?? 'Unknown User';
    } catch (error) {
      print("Error fetching username: $error");
      return 'Unknown User';
    }
  }

  void sendReq(BuildContext context,
      String postId) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String notificationId =
          FirebaseFirestore.instance.collection('notifications').doc().id;
      // Generate unique ID for notification
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'postId': postId,
        'notificationId': notificationId,
        'timestamp': DateTime.now(),
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Request Successful'),
          content: Text('Request sent successfully'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      print('Error saving notification: $error');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Request Failed'),
          content: Text('Unable to send request. Error: $error'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
