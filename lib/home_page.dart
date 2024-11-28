import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gg_sms_pool/landing_page.dart';
import 'package:gg_sms_pool/number_history_page.dart';
import 'package:gg_sms_pool/payment_history.dart';
import 'dart:html' as html;
import 'package:gg_sms_pool/buy_numbers_page.dart';
import 'package:gg_sms_pool/manual_payment_page.dart';
import 'package:gg_sms_pool/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = '';
  String balance = '0.00';
  String firstName = "John";
  String lastName = "Doe";
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  List<Map<String, dynamic>> paymentHistory = [];
  Future<void> saveStringToPrefs(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          userName = userDoc.data()?['firstName'] ?? 'User';
          balance = userDoc.data()?['balance']?.toString() ?? '0.00';
          firstName = userDoc.data()?['firstName']?.toString() ?? 'John';
          lastName = userDoc.data()?['lastName']?.toString() ?? 'Doe';
          saveStringToPrefs("firstName", firstName);
          saveStringToPrefs("lastName", lastName);
        });

        // Load payment history from 'payment_history' subcollection
        final paymentHistorySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('payment_history')
            .orderBy('date', descending: true)
            .get();

        setState(() {
          paymentHistory =
              paymentHistorySnapshot.docs.map((doc) => doc.data()).toList();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width:MediaQuery.of(context).size.width*0.6,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.blueAccent),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.phone, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'GG SMS Pool',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Hello, $userName',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.blueAccent),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.blueAccent),
              title: const Text('Buy Numbers'),
              onTap: () {
                Navigator.pop(context);
                moveToPage(context, const BuyNumbersPage(), false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blueAccent),
              title: const Text('Payment History'),
              onTap: () {
                Navigator.pop(context);
                moveToPage(context, const PaymentHistoryPage(), false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blueAccent),
              title: const Text('Number History'),
              onTap: () {
                Navigator.pop(context);
                moveToPage(context, const NumberHistoryPage(), false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings,
                  color: Colors.blueAccent),
              title: const Text('Contact Admin'),
              onTap: () async{
                Navigator.pop(context);
                 html.window.open("https://wa.me/+2349061968658", "_blank");
                //await launchUrl(Uri.parse("https://wa.me/+2349061968658"),mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.blueAccent),
              title: const Text('Logout'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                moveToPage(context, const LandingPage(), true);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.blueAccent),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Spacer(),
                   Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blue),
                      SizedBox(width: 5),
                      const Text(
                        'GG SMS Pool',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20
                        ),
                      ),
                      // Text(
                      //   balance,
                      //   style: const TextStyle(color: Colors.white, fontSize: 16),
                      // ),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $userName!',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Available Balance',
                            style:
                                TextStyle(fontSize: 18, color: Colors.black87),
                          ),
                          Text(
                            '₦$balance',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          InkWell(
                            onTap: () {
                              // Navigate to Buy Numbers Page
                              moveToPage(
                                  context, const BuyNumbersPage(), false);
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.shopping_cart,
                                    color: Colors.blueAccent),
                                SizedBox(width: 5),
                                Text(
                                  'Buy Numbers',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () {
                              moveToPage(context,
                                              const ManualPaymentPage(), false);
                              // Show a dialog for selecting payment method
                              // showDialog(
                              //   context: context,
                              //   builder: (BuildContext context) {
                              //     return AlertDialog(
                              //       title: const Text("Select Payment Method"),
                              //       content: const Text(
                              //           "Choose your preferred payment method."),
                              //       actions: [
                              //         // TextButton(
                              //         //   onPressed: () {
                              //         //     Navigator.pop(
                              //         //         context); // Close the dialog
                              //         //     // Navigate to Fund Account page with card payment
                              //         //     moveToPage(context,
                              //         //         const FundAccountPage(), false);
                              //         //   },
                              //         //   child: const Text("Card Payment"),
                              //         // ),
                              //         TextButton(
                              //           onPressed: () {
                              //             Navigator.pop(
                              //                 context); // Close the dialog
                              //             // Navigate to a manual payment page or show manual payment options
                              //             moveToPage(context,
                              //                 const ManualPaymentPage(), false);
                              //           },
                              //           child: const Text("Manual Payment"),
                              //         ),
                              //       ],
                              //     );
                              //   },
                              // );
                            },
                            child: const Row(
                              children: [
                                Icon(Icons.add, color: Colors.blueAccent),
                                SizedBox(width: 5),
                                Text(
                                  'Fund Account',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.blueAccent),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Payment History',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: paymentHistory.isEmpty
                    ? const Center(child: Text('No payment history'))
                    : ListView.builder(
                        itemCount: paymentHistory.length,
                        itemBuilder: (context, index) {
                          final historyItem = paymentHistory[index];
                          final amount = historyItem['amount'] ?? 0;
                          final date =
                              historyItem['date']?.toDate() ?? DateTime.now();
                          final type = historyItem['type'] ?? 'Unknown';

                          return ListTile(
                            leading: const Icon(Icons.attach_money,
                                color: Colors.green),
                            title: Text('₦$amount - $type'),
                            subtitle: Text(date.toLocal().toString()),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
