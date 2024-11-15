import 'package:flutter/material.dart';
import 'package:paystack_manager_package/paystack_pay_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PaystackPayManager payManager;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //payManager = buildPaystackPayManager(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paystack Payment"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            //initiate payment button
            MaterialButton(
              onPressed: () async {
                buildPaystackPayManager(context);
              },
              child: const Text(
                "Pay",
              ),
            ),
          ],
        ),
      ),
    );
  }

  buildPaystackPayManager(BuildContext context) {
    return PaystackPayManager(
      context: context,
      secretKey: 'sk_test_62f08d71c2bfb74012b186335c8cc2f9f41a51a3',
      reference: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: 100,
      country: 'Nigeria',
      currency: 'NGN',
      email: 'sam@gmail.com',
      firstName: 'sam',
      lastName: 'dave',
      companyAssetImage: null,
      metadata: {},
      onSuccessful: (t) {},
      onPending: (t) {},
      onFailed: (t) {},
      onCancelled: (t) {},
    ).initialize();
  }
}