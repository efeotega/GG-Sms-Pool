import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentHistoryPage extends StatefulWidget {
  const PaymentHistoryPage({super.key});

  @override
  _PaymentHistoryPageState createState() => _PaymentHistoryPageState();
}

class _PaymentHistoryPageState extends State<PaymentHistoryPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> paymentHistory = [];
  bool isLoading = true; // State variable for loading

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
  }

  Future<void> _fetchPaymentHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('ggsms_users').doc(user.email).get();

      if (userDoc.exists) {
        // Load payment history from 'payment_history' subcollection
        final paymentHistorySnapshot = await FirebaseFirestore.instance
            .collection('ggsms_users')
            .doc(user.email)
            .collection('ggsms_payment_history')
            .orderBy('date', descending: true)
            .get();

        setState(() {
          paymentHistory = paymentHistorySnapshot.docs.map((doc) => doc.data()).toList();
          isLoading = false; // Set loading to false after data is fetched
        });
      } else {
        setState(() {
          isLoading = false; // Handle case where user document does not exist
        });
      }
    } else {
      setState(() {
        isLoading = false; // Handle case where there is no current user
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading // Check if data is still loading
            ? const Center(child: CircularProgressIndicator()) // Show loading indicator
            : paymentHistory.isEmpty
                ? const Center(child: Text('No payment history'))
                : ListView.builder(
                    itemCount: paymentHistory.length,
                    itemBuilder: (context, index) {
                      final historyItem = paymentHistory[index];
                      final amount = historyItem['amount'] ?? 0;
                      final date = historyItem['date']?.toDate() ?? DateTime.now();
                      final type = historyItem['type'] ?? 'Unknown';

                      return ListTile(
                        leading: const Icon(Icons.attach_money, color: Colors.green),
                        title: Text('₦$amount - $type'),
                        subtitle: Text(date.toLocal().toString()),
                      );
                    },
                  ),
      ),
    );
  }
}
