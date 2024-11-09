import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersPage extends StatefulWidget {
  const ManageUsersPage({super.key});

  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to ban/unban a user
  Future<void> toggleBanStatus(String userId, bool? isCurrentlyBanned) async {
  // Set to `false` if `isCurrentlyBanned` is null
  final currentStatus = isCurrentlyBanned ?? false;

  await _firestore.collection('users').doc(userId).update({
    'isBanned': !currentStatus,
  });
}


  // Fetch all users from Firestore
  Stream<QuerySnapshot> getUsersStream() {
    return _firestore.collection('users').snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Manage Users'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No users found.'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userId = user.id;
              final userName = user['firstName']+" "+user['lastName'];
              final userEmail = user['email'];
              final balance = user['balance'];
              final isBanned = user['isBanned'] ?? false;

              return ListTile(
                title: Text(userName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(userEmail),
                    Text("balance: $balance"),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () {
                    toggleBanStatus(userId, isBanned);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isBanned ? Colors.red : Colors.green,
                  ),
                  child: Text(isBanned ? 'Unban' : 'Ban'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
