import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gg_sms_pool/countdown_timer_widget.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class NumberHistoryPage extends StatefulWidget {
  const NumberHistoryPage({super.key});

  @override
  _NumberHistoryPageState createState() => _NumberHistoryPageState();
}

class _NumberHistoryPageState extends State<NumberHistoryPage> {
  String apiKey = "X8PiPQWlxSKYSNcOOWBwYOaze6hgkZ";
  final User? user = FirebaseAuth.instance.currentUser;
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Copied to clipboard")),
    );
  }

  Future<String> generateCode({
    required String server,
    required String orderId,
    required int status,
    required List<QueryDocumentSnapshot<Object?>> purchasedNumbers,
    required int index,
  }) async {
    final updatedSms = await _fetchAndSaveSmsCode(
      server,
      orderId,
      purchasedNumbers[index].reference,
      status,
    );
    return updatedSms ?? "";
  }

  Stream<String> _getCodeStream({
    required String server,
    required String orderId,
    required int status,
    required List<QueryDocumentSnapshot<Object?>> purchasedNumbers,
    required int index,
  }) async* {
    try {
      String result = await generateCode(
        server: server,
        orderId: orderId,
        status: status,
        purchasedNumbers: purchasedNumbers,
        index: index,
      );

      yield result; // Emit the initial result

      // Continue emitting every 5 seconds only if the result is "SMS pending"
      while (result == "SMS pending") {
        await Future.delayed(const Duration(seconds: 5));

        result = await generateCode(
          server: server,
          orderId: orderId,
          status: status,
          purchasedNumbers: purchasedNumbers,
          index: index,
        );

        yield result;
      }
    } catch (e) {
      yield "Error: $e";
    }
  }

  Future<bool> refundBalance(String amount) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User is not logged in.");
        return false;
      }

      // Fetch the user's current balance
      final userDocRef =
          FirebaseFirestore.instance.collection('ggsms_users').doc(user.email);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        print("User document not found.");
        return false;
      }

      // Get the user's current balance
      final int currentBalance = userDoc.data()?['balance'] ?? 0;

      // Calculate the new balance
      final int newBalance = currentBalance + int.parse(amount);

      // Update the balance in Firestore
      await userDocRef.update({'balance': newBalance});

      print("Balance refunded successfully. New balance: $newBalance");
      return true;
    } catch (e) {
      print("Error refunding balance: $e");
      return false;
    }
  }

  Future<void> _updateStatusToVoid(String orderId, String amount) async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("User is not logged in.");
        return;
      }

      // Get the document reference for the specific purchased number
      final docRef = FirebaseFirestore.instance
          .collection('ggsms_users')
          .doc(user.email)
          .collection('purchased_numbers')
          .where('orderId', isEqualTo: orderId)
          .limit(1);

      final snapshot = await docRef.get();

      if (snapshot.docs.isNotEmpty) {
        final DocumentReference purchasedNumberRef =
            snapshot.docs.first.reference;

        // Update the status field to "void"
        await purchasedNumberRef.update({'status': 99});
        await refundBalance(amount);
        setState(() {});
      } else {
        print("OrderId not found in the database.");
      }
    } catch (e) {
      print("Error updating status to void: $e");
    }
  }

  Future<void> cancelSms(String orderId, String amount, String server) async {
    if (server == "smspool") {
      var request = http.MultipartRequest(
          'POST', Uri.parse('https://api.smspool.net/sms/cancel'));
      request.fields.addAll(
          {'orderid': orderId, 'key': 'yFXHjau7PV6Dox8sA2YD8wD9Ak4kP5pC'});

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cancelled Successfully'),
          backgroundColor: Colors.green,
        ));
        await _updateStatusToVoid(orderId, amount);
      } else {
        print(response.statusCode);
        if(response.reasonPhrase==""&&response.statusCode==404){
          await _updateStatusToVoid(orderId, amount);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Cancelled Successfully'),
          backgroundColor: Colors.green,
        ));
        return;
        }
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to cancel request.'),
          backgroundColor: Colors.red,
        ));
      }
    } else if (server == "smsbus") {
      final token = "c5027c1a4b3c4dbe96442be795c8d5b3";
      // Prepare the URL for the GET request
      final url = Uri.parse(
          'https://sms-bus.com/api/control/cancel?token=$token&request_id=$orderId');

      try {
        final response = await http.get(url);

        if (response.statusCode == 200) {
          // Convert the response body to a string
          String responseBody = response.body;
          print("Response: $responseBody");

          // Parse the response body as JSON
          final jsonResponse = jsonDecode(responseBody);

          // Check if the response indicates success
          if (jsonResponse['code'] == 200) {
            print("Request successfully canceled.");

            // You can show a dialog or message indicating success
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Request canceled successfully.'),
              backgroundColor: Colors.green,
            ));
            await _updateStatusToVoid(orderId, amount);
          } else {
            // Handle failure

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Failed to cancel request.'),
              backgroundColor: Colors.red,
            ));
          }
        } else {
          // Handle error response
          String responseBody = await response.body;
          print("Error response: $responseBody");

          final jsonResponse = jsonDecode(responseBody);
          if (jsonResponse.containsKey('message')) {
            String message = jsonResponse['message'];
            print("Error message: $message");
          }

          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to cancel the request.'),
            backgroundColor: Colors.red,
          ));
        }
      } catch (e) {
        print("Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('An error occurred while canceling the request.'),
          backgroundColor: Colors.red,
        ));
      }
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
                  .collection('ggsms_users')
                  .doc(user!.email)
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
                    Color backgroundColor = Colors.black;
                    final data =
                        purchasedNumbers[index].data() as Map<String, dynamic>;
                    final number = data['number'] ?? 'Unknown';
                    final service = data['service'] ?? 'Unknown';
                    final orderId = data['orderId'] ?? 'Unknown';
                    final price = data['price'] ?? 'Unknown';
                    final server = data['server'] ?? 'smspool';
                    final smsCode =
                        data['sms'] ?? ''; // Fetch from Firestore if available
                    final status =
                        data['status'] ?? 1; // Default to 1 (pending)
                    final timestamp = data['date'] as Timestamp?;
                    final date = timestamp != null
                        ? DateFormat.yMMMd().add_jm().format(timestamp.toDate())
                        : 'No date available';

                    if (status == 1) {
                      backgroundColor = Colors.orangeAccent;
                    }
                    if (status == 99) {
                      backgroundColor = Colors.grey;
                    }
                    if (status == 3) {
                      backgroundColor = Colors.green;
                    }
                    if (server == "smspool" && status == 99) {
                      return SizedBox.shrink();
                    } else {
                      return FutureBuilder<String?>(
                        future: smsCode.isEmpty
                            ? _fetchAndSaveSmsCode(server, orderId,
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
                                              "$service",
                                              style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold
                                              ),
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
                                            status == 99
                                                ? const Expanded(
                                                    child: Text(
                                                      "SMS Code: cancelled",
                                                      style: TextStyle(
                                                          fontSize: 16),
                                                    ),
                                                  )
                                                : Expanded(
                                                    child:
                                                        StreamBuilder<String>(
                                                      stream: _getCodeStream(
                                                          server: server,
                                                          orderId: orderId,
                                                          status: status,
                                                          purchasedNumbers:
                                                              purchasedNumbers,
                                                          index: index),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot.hasData) {
                                                          return Text(
                                                            "Sms code: ${snapshot.data!}",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        16),
                                                          );
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Text(
                                                            'Error: ${snapshot.error}',
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .red),
                                                          );
                                                        }
                                                        return const Center(
                                                            child:
                                                                CircularProgressIndicator());
                                                      },
                                                    ),
                                                  ),
                                            IconButton(
                                              icon: const Icon(Icons.copy),
                                              onPressed: () => _copyToClipboard(
                                                  context, sms),
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
                                                    server,
                                                    orderId,
                                                    purchasedNumbers[index]
                                                        .reference,
                                                    status,
                                                  );

                                                  // Update UI after fetching SMS
                                                  setState(() {
                                                    final data =
                                                        purchasedNumbers[index]
                                                                .data()
                                                            as Map<String,
                                                                dynamic>?;
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
                                        backgroundColor: backgroundColor,
                                      ),
                                    ],
                                  ),

                                  const Divider(),

                                  // Countdown Timer
                                  CountdownTimerWidget(
                                    startTime: date,
                                    minutes: server == "daisysms" ? 7 : 20,
                                  ),
                                  const SizedBox(height: 8),

                                  // Purchase Date and Cancel Button
                                  Text(
                                    "Purchased on: $date",
                                  ),
                                  Text("Price ₦$price"),
                                  const SizedBox(height: 8),

                                  status != 3 && status != 99
                                      ? Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () async {
                                              if (hasFiveMinutesElapsed(date)) {
                                                cancelSms(
                                                    orderId, price, server);
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                        const SnackBar(
                                                  content: Text(
                                                      "Please wait five minutes to elapse before cancelling your order"),
                                                  backgroundColor: Colors.red,
                                                ));
                                              }
                                            },
                                            child: const Text(
                                              "Cancel",
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        )
                                      : Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        "Order already processed")),
                                              );
                                            },
                                            child: const Text(
                                              "Cancel",
                                              style:
                                                  TextStyle(color: Colors.grey),
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                  },
                );
              },
            ),
    );
  }

  Future<String> getSmsBusCode(String requestId) async {
    // Assuming you have a valid token
    final token = "c5027c1a4b3c4dbe96442be795c8d5b3"; // Replace with your token

    // Prepare the URL for the GET request
    final url = Uri.parse(
        'https://sms-bus.com/api/control/get/sms?token=$token&request_id=$requestId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Convert the response body to a string
        String responseBody = response.body;
        print("Response: $responseBody");

        // Parse the response body as JSON
        final jsonResponse = jsonDecode(responseBody);

        // Check if the "data" field exists
        if (jsonResponse['code'] == 200 && jsonResponse['data'] != null) {
          String smsCode = jsonResponse['data'];
          print("SMS Code: $smsCode");

          return smsCode;
        } else {
          print("Error fetching SMS code: ${jsonResponse['message']}");
          return "Error";
        }
      } else {
        // Handle error response
        String responseBody = await response.body;
        print("Error response: $responseBody");

        final jsonResponse = jsonDecode(responseBody);
        if (jsonResponse.containsKey('message')) {
          String message = jsonResponse['message'];
          int code = jsonResponse['code'];
          if (code == 50101) {
            return "SMS pending";
          }
          print("Error message: $message");
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to fetch SMS code.'),
          backgroundColor: Colors.red,
        ));
        return "Error";
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('An error occurred while fetching the SMS code.'),
        backgroundColor: Colors.red,
      ));
      return "Error";
    }
  }

  /// Fetch the SMS code from the API and save it to Firestore
  Future<String?> _fetchAndSaveSmsCode(String server, String orderId,
      DocumentReference docRef, int status) async {
    if (server == "smsbus") {
      String sms = await getSmsBusCode(orderId);
      return sms;
    } else if (server == "smspool") {
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
    } else {
      return "";
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
      case 99:
        return "Cancelled";
      default:
        return "Unknown";
    }
  }

  bool hasFiveMinutesElapsed(String dateString) {
    try {
      // Replace non-breaking spaces with regular spaces
      final sanitizedDate = dateString.replaceAll('\u202F', ' ');

      // Parse the input date string
      final dateTime =
          DateFormat("MMM d, yyyy h:mm a").parse(sanitizedDate).toLocal();

      // Check if 5 minutes have elapsed
      return DateTime.now().difference(dateTime).inMinutes >= 5;
    } catch (e) {
      print("Error parsing date: $e");
      return false; // Return false if parsing fails
    }
  }
}
