import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gg_sms_pool/countdown_timer_widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class NumberHistoryPage extends StatefulWidget {
  const NumberHistoryPage({Key? key}) : super(key: key);

  @override
  _NumberHistoryPageState createState() => _NumberHistoryPageState();
}

class _NumberHistoryPageState extends State<NumberHistoryPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Copied to clipboard")),
    );
  }

  void cancelSms(String orderId) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('https://api.smspool.net/sms/cancel'));
    request.fields.addAll(
        {'orderid': orderId, 'key': 'yFXHjau7PV6Dox8sA2YD8wD9Ak4kP5pC'});

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Cancelled Successfully'),
        backgroundColor: Colors.red,
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Unable to cancel'),
        backgroundColor: Colors.red,
      ));
      print(response.reasonPhrase);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Number History"),
      ),
      body: user == null
          ? const Center(
              child: Text("You need to log in to view your history."),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user!.uid)
                  .collection('purchased_numbers')
                  .orderBy('date', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No number history found."),
                  );
                }

                final purchasedNumbers = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: purchasedNumbers.length,
                  itemBuilder: (context, index) {
                    final data =
                        purchasedNumbers[index].data() as Map<String, dynamic>;
                    final number = data['number'] ?? 'Unknown';
                    final service = data['service'] ?? 'Unknown';
                    final orderId = data['orderId'] ?? 'Unknown';
                    final price = data['price'] ?? 'Unknown';
                    final smsCode =
                        data['sms'] ?? ''; // Fetch from Firestore if available
                    final status =
                        data['status'] ?? 1; // Default to 1 (pending)
                    final timestamp = data['date'] as Timestamp?;
                    final date = timestamp != null
                        ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                        : 'No date available';

                    return FutureBuilder<String?>(
                      future: smsCode.isEmpty
                          ? _fetchAndSaveSmsCode(orderId,
                              purchasedNumbers[index].reference, status)
                          : Future.value(
                              smsCode), // Use cached SMS if available
                      builder: (context, smsSnapshot) {
                        if (smsSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(10),
                            child: ListTile(
                              leading: CircularProgressIndicator(),
                              title: Text("Fetching SMS..."),
                            ),
                          );
                        }

                        final sms = smsSnapshot.data ?? 'No SMS available';
                        final statusMessage = _getStatusMessage(status);

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Number and Service Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  "+$number",
                                                  style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.copy),
                                                onPressed: () =>
                                                    _copyToClipboard(
                                                        context, number),
                                                tooltip: "Copy Number",
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Service: $service",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // SMS Code and Status Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              "SMS Code: $sms",
                                              style:
                                                  const TextStyle(fontSize: 16),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy),
                                            onPressed: () =>
                                                _copyToClipboard(context, sms),
                                            tooltip: "Copy SMS Code",
                                          ),
                                          // Refresh Icon
                                          if (status !=
                                              3) // Show refresh icon only if status is not complete
                                            IconButton(
                                              icon: const Icon(Icons.refresh),
                                              onPressed: () async {
                                                // Show a loading indicator during refresh
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        "Refreshing SMS status..."),
                                                    duration:
                                                        Duration(seconds: 2),
                                                  ),
                                                );

                                                // Call API to fetch the latest SMS code
                                                final updatedSms =
                                                    await _fetchAndSaveSmsCode(
                                                  orderId,
                                                  purchasedNumbers[index]
                                                      .reference,
                                                  status,
                                                );

                                                // Update UI after fetching SMS
                                                setState(() {
                                                  final data = purchasedNumbers[
                                                              index]
                                                          .data()
                                                      as Map<String, dynamic>?;
                                                  if (data != null &&
                                                      updatedSms != null) {
                                                    data['sms'] =
                                                        updatedSms; // Safely update the 'sms' value
                                                  }
                                                });
                                              },
                                              tooltip: "Refresh SMS Code",
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Chip(
                                      label: Text(
                                        statusMessage,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      backgroundColor: status == 1
                                          ? Colors.orangeAccent
                                          : status == 6
                                              ? Colors.grey
                                              : Colors.green,
                                    ),
                                  ],
                                ),

                                const Divider(),

                                // Countdown Timer
                                CountdownTimerWidget(startTime: date),
                                const SizedBox(height: 8),

                                // Purchase Date and Cancel Button
                                Text(
                                  "Purchased on: $date",
                                ),
                                Text("Price ₦$price"),
                                const SizedBox(height: 8),

                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      cancelSms(orderId);
                                    },
                                    child: const Text(
                                      "Cancel",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
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

  /// Fetch the SMS code from the API and save it to Firestore
  Future<String?> _fetchAndSaveSmsCode(
      String orderId, DocumentReference docRef, int status) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.smspool.net/sms/check'),
      );
      request.fields.addAll({
        'orderid': orderId,
        'key': 'yFXHjau7PV6Dox8sA2YD8wD9Ak4kP5pC',
      });

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = json.decode(responseBody);

        if (responseData['status'] == 3) {
          final smsCode = responseData['sms'] as String;

          // Save SMS to Firestore for caching
          await docRef.update({
            'sms': smsCode,
            'status': 3
          }); // Update the status to complete if successful

          return smsCode;
        } else if (responseData['status'] == 1) {
          return "SMS pending";
        } else if (responseData['status'] == 6) {
          return "Order refunded";
        } else {
          return "Unknown status";
        }
      } else {
        return "Failed to fetch SMS";
      }
    } catch (e) {
      print("Error fetching SMS: $e");
      return "Error";
    }
  }

  /// Get the status message based on the status code
  String _getStatusMessage(int status) {
    switch (status) {
      case 1:
        return "Pending";
      case 3:
        return "Completed";
      case 6:
        return "Refunded";
      default:
        return "Unknown";
    }
  }
}
