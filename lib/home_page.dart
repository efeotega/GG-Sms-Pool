import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gg_sms_pool/us_numbers_page.dart';
import 'package:gg_sms_pool/buy_numbers_smspool_page.dart';
import 'package:gg_sms_pool/landing_page.dart';
import 'package:gg_sms_pool/login_page.dart';
import 'package:gg_sms_pool/number_history_page.dart';
import 'package:gg_sms_pool/payment_history.dart';
import 'dart:html' as html;
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
  int totalDeposited = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    calculateTotalDeposited();
    checkIfUserBanned();
    listenToUserBalance(FirebaseAuth.instance.currentUser!.email!);
  }

  Future<void> checkIfUserBanned() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      FirebaseAuth.instance.signOut();
      moveToPage(context, const LoginPage(), true);
    }
    final userDoc = await FirebaseFirestore.instance
        .collection('ggsms_users')
        .doc(user!.email)
        .get();
    if (!userDoc.exists) {
      FirebaseAuth.instance.signOut();
      moveToPage(context, const LoginPage(), true);
    }

    if (!user.emailVerified) {
      await user.sendEmailVerification();
      _showVerificationDialog();
    } else {
      // Check if the user is banned in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('ggsms_users')
          .doc(user.email)
          .get();
      if (!userDoc.exists) {
        FirebaseAuth.instance.signOut();
        moveToPage(context, const LoginPage(), true);
      }

      final isBanned = userDoc.data()?['isBanned'] ?? false;

      if (isBanned) {
        // Show banned dialog
        _showBannedDialog();
      }
    }
  }

  void _showBannedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Account Banned"),
          content:
              const Text("Your account has been banned and you cannot log in."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                //move back to login page and logout
                FirebaseAuth.instance.signOut();
                moveToPage(context, const LandingPage(), true);
              },
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> paymentHistory = [];
  Future<void> saveStringToPrefs(String key, String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void calculateTotalDeposited() {
    setState(() {
      totalDeposited = paymentHistory.fold<int>(
        0,
        (sum, historyItem) => sum + ((historyItem['amount'] ?? 0) as int),
      );
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('ggsms_users')
          .doc(user.email)
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
            .collection('ggsms_users')
            .doc(user.email)
            .collection('ggsms_payment_history')
            .orderBy('date', descending: true)
            .get();

        setState(() {
          paymentHistory =
              paymentHistorySnapshot.docs.map((doc) => doc.data()).toList();
        });
        calculateTotalDeposited();
      }
    }
  }

  StreamSubscription<DocumentSnapshot>? _balanceSubscription;

  void listenToUserBalance(String userEmail) {
    // Reference to the user's document in Firestore
    final userDocRef =
        FirebaseFirestore.instance.collection('ggsms_users').doc(userEmail);

    // Cancel existing listener if any
    _balanceSubscription?.cancel();

    // Start listening for changes in the user's document
    _balanceSubscription = userDocRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null && data.containsKey('balance')) {
          final balance = data['balance'];
          print('User balance updated: $balance');

          // You can also update the state to reflect the balance in the UI
          setState(() {
            this.balance = balance.toString();
          });
        } else {
          print('Balance field does not exist in user document');
        }
      } else {
        print('User document does not exist');
      }
    }, onError: (error) {
      print('Error listening to balance: $error');
    });
  }

  @override
  void dispose() {
    stopListeningToUserBalance();
    super.dispose();
  }

  void stopListeningToUserBalance() {
    _balanceSubscription?.cancel();
    _balanceSubscription = null;
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Verification Required'),
        content: const Text(
          'A verification email has been sent to your email address. '
          'Please verify your email to proceed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );
  }

  void _showNumberOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Server'),
          content: const Text('Choose the type of numbers you want to buy:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                moveToPage(
                  context,
                  const USNumbersPage(),
                  false,
                ); // Navigate to the US Numbers page
              },
              child: const Text('US Numbers'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                moveToPage(
                  context,
                  const BuyNumbersPageSmsPool(),
                  false,
                ); // Navigate to the Other Numbers page
              },
              child: const Text('Other Numbers'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.blueAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        width: MediaQuery.of(context).size.width *
            0.7, // Slightly wider for better usability
        child: Column(
          children: [
            // Drawer Header
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blueAccent, Colors.lightBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.white, size: 30),
                      const SizedBox(width: 10),
                      const Text(
                        'GG SMS Pool',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hello, $userName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home,
                    text: 'Home',
                    onTap: () => Navigator.pop(context),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.phone,
                    text: 'Buy Numbers',
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Select Server'),
                            content: const Text(
                                'Choose the type of numbers you want to buy:'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                  moveToPage(
                                      context, const USNumbersPage(), false);
                                },
                                child: const Text('US Numbers'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the dialog
                                  moveToPage(context,
                                      const BuyNumbersPageSmsPool(), false);
                                },
                                child: const Text('Other Countries'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.history,
                    text: 'Payment History',
                    onTap: () {
                      Navigator.pop(context);
                      moveToPage(context, const PaymentHistoryPage(), false);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.history,
                    text: 'Number History',
                    onTap: () {
                      Navigator.pop(context);
                      moveToPage(context, const NumberHistoryPage(), false);
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.admin_panel_settings,
                    text: 'Contact Admin',
                    onTap: () {
                      Navigator.pop(context);
                      html.window
                          .open("https://wa.me/+2349061968658", "_blank");
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout,
                    text: 'Logout',
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      moveToPage(context, const LandingPage(), true);
                    },
                  ),
                ],
              ),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.blueAccent),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  const Text(
                    'GG SMS Pool',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.blue,
                    ),
                  ),
                  const Icon(Icons.phone, color: Colors.blue),
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
                          color: Colors.blueAccent,
                        ),
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
                              color: Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildAction(
                            context,
                            icon: Icons.shopping_cart,
                            label: 'Buy Numbers',
                            onTap: () => _showNumberOptions(context),
                          ),
                          _buildAction(
                            context,
                            icon: Icons.add,
                            label: 'Fund Account',
                            onTap: () => moveToPage(
                                context, const ManualPaymentPage(), false),
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
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text("Total Deposited: ₦$totalDeposited"),
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
