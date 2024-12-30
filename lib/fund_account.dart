import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FundAccountPage extends StatefulWidget {
  const FundAccountPage({super.key});

  @override
  State<FundAccountPage> createState() => _FundAccountPageState();
}

class _FundAccountPageState extends State<FundAccountPage> {
  final amountController = TextEditingController();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool isLoading=false;

  @override
  void initState() {
    amountController.addListener(() {
      setState(() {});
    });
    super.initState();
  }

  String generateRef() {
    final randomCode = Random().nextInt(3234234);
    return 'ref-$randomCode';
  }

  Future<void> _addPaymentToHistory(double amount) async {
    if (currentUser == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    final paymentHistory = userDoc.collection('payment_history');

    await paymentHistory.add({
      'amount': amount,
      'date': Timestamp.now(),
      'type': 'auto', // Or 'card' if you want to differentiate payment types
    });
  }

  Future<void> _updateUserBalance(double amount) async {
    if (currentUser == null) return;

    final userDoc =
        FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
    final userSnapshot = await userDoc.get();

    if (userSnapshot.exists) {
      double currentBalance =
          (userSnapshot.data()?['balance'] ?? 0.0).toDouble();
      double newBalance = currentBalance + amount;

      await userDoc.update({'balance': newBalance});
    } else {
      await userDoc.set({'balance': amount});
    }
  }
Future<String> getStringFromPrefs(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  if(prefs.getString(key)==null){
    return"";
  }
  return prefs.getString(key)!;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  "Fund Account",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Amount (₦)',
                ),
              ),
              const Spacer(),
              isLoading?const Center(child: CircularProgressIndicator()):
              TextButton(
                onPressed: () async {
                  final ref = generateRef();
                  final amount = int.tryParse(amountController.text) ?? 0;

                  if (amount <= 0 || currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please enter a valid amount.')),
                    );
                    return;
                  }

                  try {
                    // await FlutterPaystackPlus.openPaystackPopup(
                    //   publicKey: "pk_test_d3ab0038989181231f820d0f817df1f54cf54462", // Replace with your public key
                    //   context: context,
                    //   secretKey: "sk_test_53aa776d52a713e79fa97683c8e07a1d4050ec07", // Only for mobile
                    //   currency: 'NGN',
                    //   customerEmail: currentUser!.email!,
                    //   amount: (amount * 100).toString(), // Convert amount to kobo
                    //   reference: ref,
                    //   callBackUrl: "[GET IT FROM YOUR PAYSTACK DASHBOARD]",
                    //   onClosed: () {
                    //      ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('Payment Failed')),
                    // );
                    //   },
                    //   onSuccess: () async {
                    //      ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text('Payment Successful')),
                    // );

                    // // Update balance in Firestore
                    // await _updateUserBalance(amount.toDouble());
                    // //add to user payment history
                    //  await _addPaymentToHistory(amount.toDouble());
                    //  Navigator.of(context).pop();
                    //   },
                    // );
                    // await PaystackPayManager(
                    //   context: context,
                    //   secretKey:
                    //       'sk_live_cb44456a850c7da2ea56e9e7de9c9ba06d471f14',
                    //   reference:
                    //       "ggsmspool$ref",
                    //   amount: amount,
                    //   country: 'Nigeria',
                    //   currency: 'NGN',
                    //   email: FirebaseAuth.instance.currentUser!.email!,
                    //   firstName:  await getStringFromPrefs("firstName"),
                    //   lastName: await getStringFromPrefs("lastName"),
                    //   companyAssetImage: null,
                    //   metadata: {},
                    //   onSuccessful: (t) async {
                    //     setState(() {
                    //       isLoading=true;
                    //     });
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //       const SnackBar(content: Text('Payment Successful')),
                    //     );

                    //     // Update balance in Firestore
                    //     await _updateUserBalance(amount.toDouble());
                    //     //add to user payment history
                    //     await _addPaymentToHistory(amount.toDouble());
                    //     moveToPage(context, const HomePage(), true);
                    //   },
                    //   onPending: (t) {},
                    //   onFailed: (t) {
                    //     ScaffoldMessenger.of(context).showSnackBar(
                    //         const SnackBar(content: Text('Payment Failed')));
                    //   },
                    //   onCancelled: (t) {
                    //      ScaffoldMessenger.of(context).showSnackBar(
                    //         const SnackBar(content: Text('Payment Cancelled')));
                    //   },
                    // ).initialize();
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blueAccent),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Pay${amountController.text.isEmpty ? '' : ' ₦${amountController.text}'} with Paystack',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
