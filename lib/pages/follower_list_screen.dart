import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowerListScreen extends StatelessWidget {
  final String supplierId;

  const FollowerListScreen({Key? key, required this.supplierId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Followers"),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/flutter_bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
      StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('followers')
            .doc(supplierId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No followers found.", style: TextStyle(fontSize: 16, color: Colors.white)));
          }

          var followerIds = List<String>.from(snapshot.data!['followers']);

          if (followerIds.isEmpty) {
            return const Center(child: Text("No followers found."));
          }

          return ListView.builder(
            itemCount: followerIds.length,
            itemBuilder: (context, index) {
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(followerIds[index])
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      leading: CircleAvatar(),
                      title: Text("Loading...", style: TextStyle(color: Colors.white)),
                    );
                  }
                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    return const ListTile(
                      leading: CircleAvatar(),
                      title: Text("Unknown User", style: TextStyle(color: Colors.white)),
                    );
                  }

                  var user = userSnapshot.data!;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user['name'][0]),
                    ),
                    title: Text(user['name'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text(user['email'], style: const TextStyle(color: Colors.white70)),
                  );
                },
              );
            },
          );
        },
      ),
        ]
      )
    );
  }
}