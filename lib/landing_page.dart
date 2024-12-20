import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:gg_sms_pool/home_page.dart';
import 'package:gg_sms_pool/login_page.dart';
import 'package:gg_sms_pool/utils.dart';
import 'dart:html' as html;

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  _LandingPageState createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildAppBar(),
      ),
      key: _scaffoldKey,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section
            _buildTopSection(),
            const SizedBox(height: 40),
            
            // Features Section
            _buildFeaturesSection(),
            const SizedBox(height: 40),
             Image.asset("assets/pic1.jpg"),
            // Testimonials Section
            _buildTestimonialsSection(),
            const SizedBox(height: 40),
            
            // CTA Section
            _buildCTASection(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // App Bar with Hamburger Menu
  Widget _buildAppBar() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App Icon and Name on the Left
          Row(
            children: [
              Icon(Icons.phone, color: Colors.blue),
              SizedBox(width: 10),
              Text(
                'GG SMS Pool',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Side Menu (Drawer)
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.phone, color: Colors.blue),
                SizedBox(height: 10),
                Text(
                  'GG SMS Pool',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Instant non-VOIP numbers',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home, color: Colors.blue),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.featured_play_list, color: Colors.blue),
            title: const Text('Features'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.feedback, color: Colors.blue),
            title: const Text('Testimonials'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.contact_support, color: Colors.blue),
            title: const Text('Support'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // Top Section
  Widget _buildTopSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue, Colors.blueAccent], // Keep gradient for top section
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'GG SMS Pool',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Keep text color for title
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'At GGSMSPool, we pride ourselves on providing the highest quality SMS verifications for your SMS verification needs. We make sure to only provide non-VoIP phone numbers in order to work with any service.\nNo Price Fluctuation\nOur numbers start at 2 cents each, and our prices never fluctuate, even during high demand!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, color: Colors.white), // Keep text color for description
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
            final user=  FirebaseAuth.instance.currentUser;
            if(user!=null){
              moveToPage(context, const HomePage(), true);
            }
            else{
              
              moveToPage(context, const LoginPage(), false);
            }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Unified button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(
                color: Colors.white, // Keep text color for button
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Features Section
  Widget _buildFeaturesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Features',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildFeatureTile(
            icon: Icons.phone_android,
            title: 'Non-VOIP Numbers',
            description: 'Instant access to non-VOIP numbers for verification and privacy.',
          ),
          _buildFeatureTile(
            icon: Icons.message,
            title: 'Receive Texts Seamlessly',
            description: 'Get your messages instantly in one place.',
          ),
          _buildFeatureTile(
            icon: Icons.lock,
            title: 'Privacy Guaranteed',
            description: 'Your data and messages are secure and private.',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({required IconData icon, required String title, required String description}) {
    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.blue, // Unified color for feature tiles
        child: Icon(icon, color: Colors.white, size: 30),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      subtitle: Text(description, style: const TextStyle(fontSize: 16)),
    );
  }

  // Testimonials Section
  Widget _buildTestimonialsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Text(
            'What Our Users Say',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildTestimonial(
            avatar: 'assets/user2.jpg', // Replace with user avatar asset
            name: 'Jessica K.',
            text: 'GG SMS Pool makes it super easy to get verification numbers without hassle. Love it!',
          ),
          _buildTestimonial(
            avatar: 'assets/user1.jpg',
            name: 'David L.',
            text: 'The privacy and ease of use are unbeatable. Highly recommend GG SMS Pool!',
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonial({required String avatar, required String name, required String text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(avatar),
            radius: 30,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(text, style: const TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Call to Action Section
  Widget _buildCTASection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'Ready to get started?',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            'Sign up today and receive SMS with GG SMS Pool!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18), // Default text color
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              moveToPage(context, const LoginPage(), true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Unified button color
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontSize: 18, color: Colors.white), // Keep text color for button
            ),
          ),
          const SizedBox(height: 30,),
          RichText(
          text: TextSpan(
            children: [
              const TextSpan(
                text: 'This site was developed by ',
                style: TextStyle(color: Colors.amber)
              ),
              TextSpan(
                text: 'Efe Otega',
                style: const TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()..onTap = _launchURL,
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
   Future<void> _launchURL() async {
     html.window.open("https://efeotegadev.web.app", "_blank");
      //await launchUrl(Uri.parse("https://efeotegadev.web.app"),mode: LaunchMode.externalApplication);
    
  }
}
