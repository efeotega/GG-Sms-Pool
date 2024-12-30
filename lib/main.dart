import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:gg_sms_pool/firebase_options.dart';
import 'package:gg_sms_pool/landing_page.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  // Ensures Flutter widgets are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // Run the app after Firebase initialization is complete
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? ThemeData.dark() : ThemeData.light();
  }
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
     // Detect the system theme
    final brightness = WidgetsBinding.instance.window.platformBrightness;

    return MaterialApp(
      title: 'GG Sms Pool',
       theme: getTheme(brightness),
      home:const LandingPage()
      //home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class PaymentReminderWidget extends StatelessWidget {
  const PaymentReminderWidget({super.key});

  bool _shouldShowReminder() {
    final now = DateTime.now();
    final targetDate = DateTime(2024, 12, 24, 1, 0); // Dec 24, 2024, 1:00 AM
    return now.isAfter(targetDate);
  }

  @override
  Widget build(BuildContext context) {
    return _shouldShowReminder()
        ? Center(
            child: Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0),
              decoration: BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Payment Required",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Your payment is still pending. Please contact your site admin to complete your payment and continue using your website.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Redirect to Payment Page
                      launchUrl(Uri.parse("https://wa.me/+2349080009697"));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text("Make Payment"),
                  ),
                ],
              ),
            ),
          )
        : const LandingPage(); // Hide widget if the date condition isn't met
  }
}

