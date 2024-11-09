import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FinanceHistoryPage extends StatefulWidget {
  const FinanceHistoryPage({super.key});

  @override
  _FinanceHistoryPageState createState() => _FinanceHistoryPageState();
}

class _FinanceHistoryPageState extends State<FinanceHistoryPage> {
  double totalAmount = 0.0;
  List<Map<String, dynamic>> paymentData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllPayments();
  }

  Future<void> fetchAllPayments() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> tempData = [];
    double tempTotalAmount = 0.0;

    try {
      // Fetch all users
      final usersSnapshot = await firestore.collection('users').get();

      // Loop through each user to fetch payment history
      for (var userDoc in usersSnapshot.docs) {
        final userId = userDoc.id;
        final userFirstName = userDoc.data()['firstName'] ?? '';
        final userLastName = userDoc.data()['lastName'] ?? '';
        final userName = '$userFirstName $userLastName';

        // Fetch the payment history for this user
        final paymentsSnapshot = await firestore
            .collection('users')
            .doc(userId)
            .collection('payment_history')
            .get();

        for (var paymentDoc in paymentsSnapshot.docs) {
          final paymentData = paymentDoc.data();
          final double amount = (paymentData['amount'] ?? 0.0).toDouble();
          final Timestamp timestamp = paymentData['date'];
          final String formattedDate = DateFormat.yMMMd().add_jm().format(timestamp.toDate());
          final String type = paymentData['type'] ?? 'Unknown';

          // Add this payment to the list
          tempData.add({
            'name': userName,
            'amount': amount,
            'date': formattedDate,
            'type': type,
          });

          // Add to total
          tempTotalAmount += amount;
        }
      }

      setState(() {
        paymentData = tempData;
        totalAmount = tempTotalAmount;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Handle errors here, e.g., show a SnackBar or dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total Amount: ₦${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: paymentData.length,
                    itemBuilder: (context, index) {
                      final payment = paymentData[index];
                      return ListTile(
                        title: Text(
                          payment['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Amount: ₦${payment['amount']}\n'
                          'Date: ${payment['date']}\n'
                          'Type: ${payment['type']}',
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
