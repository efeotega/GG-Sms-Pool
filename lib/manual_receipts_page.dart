import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReceiptReviewPage extends StatefulWidget {
  const ReceiptReviewPage({super.key});

  @override
  State<ReceiptReviewPage> createState() => _ReceiptReviewPageState();
}

class _ReceiptReviewPageState extends State<ReceiptReviewPage> {
  final TextEditingController _amountController = TextEditingController();

  // Fetches all receipts from Firestore
  Stream<QuerySnapshot> _fetchReceipts() {
    return FirebaseFirestore.instance.collection('receipts').snapshots();
  }

  // Fetch user details based on their email
  Future<Map<String, dynamic>?> _fetchUserDetails(String userEmail) async {
    final userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: userEmail)
        .limit(1)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      return userSnapshot.docs.first.data();
    }
    return null;
  }

  // Handle accepting the payment by updating user's balance
  Future<void> _acceptPayment(String userEmail, double amount,String receiptId) async {
  final usersRef = FirebaseFirestore.instance.collection('users');
  final querySnapshot = await usersRef.where('email', isEqualTo: userEmail).get();

  if (querySnapshot.docs.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("User does not exist.")),
    );
    return;
  }

  final userDoc = querySnapshot.docs.first; // Assuming emails are unique, take the first match
  final userRef = usersRef.doc(userDoc.id); // Get the document reference for the user

  await FirebaseFirestore.instance.runTransaction((transaction) async {
    final userSnapshot = await transaction.get(userRef);

    if (!userSnapshot.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User does not exist.")),
      );
      return;
    }

    final currentBalance = (userSnapshot['balance'] ?? 0.0) as double;
    transaction.update(userRef, {'balance': currentBalance + amount});

    // Record the payment in the paymentHistory subcollection
    final historyRef = userRef.collection('payment_history').doc();
    transaction.set(historyRef, {
      'amount': amount,
      'date': FieldValue.serverTimestamp(),
      'type': 'manual',
    });
  });
   FirebaseFirestore.instance
                                      .collection('receipts')
                                      .doc(receiptId)
                                      .delete();

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Accepted.")),
  );
}


  // Show dialog for admin to enter the amount to add to the user's balance
  void _showAmountDialog(String userEmail, String userName,String receiptId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter transfer amount for $userName"),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter amount in ₦"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                final amount = double.tryParse(_amountController.text);
                if (amount != null && amount > 0) {
                  _acceptPayment(userEmail, amount,receiptId);
                  Navigator.of(context).pop();
                  _amountController.clear();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid amount.")),
                  );
                }
              },
              child: const Text("Add Amount"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchReceipts(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final receipts = snapshot.data!.docs;

          if (receipts.isEmpty) {
            return const Center(child: Text("No receipts found."));
          }

          return ListView.builder(
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final receipt = receipts[index];
              final userEmail = receipt['userEmail'];
              final imageUrl = receipt['imageUrl'];

              return FutureBuilder<Map<String, dynamic>?>(
                future: _fetchUserDetails(userEmail),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      title: Text("Loading user details..."),
                    );
                  }

                  final userDetails = userSnapshot.data!;
                  final userEmail = userDetails['email'];
                  final userName =
                      '${userDetails['firstName']} ${userDetails['lastName']}';

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            "Uploaded by: $userName",
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                              onTap: () {
                                _showFullScreenImage(context, imageUrl);
                              },
                              child: Image.network(imageUrl, height: 150)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  
                                 
                                  _showAmountDialog(userEmail, userName,receipt.id);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: const Text("Accept"),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  FirebaseFirestore.instance
                                      .collection('receipts')
                                      .doc(receipt.id)
                                      .delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Payment rejected.")),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                ),
                                child: const Text("Reject"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(0),
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        );
      },
    );
  }
}
