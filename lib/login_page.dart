import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gg_sms_pool/admin_dashboard.dart';
import 'package:gg_sms_pool/forgot_password_page.dart';
import 'package:gg_sms_pool/home_page.dart';
import 'package:gg_sms_pool/signup_page.dart';
import 'package:gg_sms_pool/utils.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  Future<void> _loginUser() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);

    if (_emailController.text.trim() == "admin@ggsmspool.com" &&
        _passwordController.text.trim() == "tinashe") {
      moveToPage(context, const AdminTasksPage(), true);
    } else {
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        final user = userCredential.user;

        if (user != null && !user.emailVerified) {
          await user.sendEmailVerification();
          _showVerificationDialog();
        } else if (user != null) {
          // Check if the user is banned in Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('ggsms_users')
              .doc(user.email)
              .get();

          final isBanned = userDoc.data()?['isBanned'] ?? false;

          if (isBanned) {
            // Show banned dialog
            _showBannedDialog();
          } else {
            // Proceed to the homepage if not banned
            moveToPage(context, const HomePage(), false);
          }
        }
      } on FirebaseAuthException catch (e) {
        _showErrorSnackBar(e.message);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

void _showBannedDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Account Banned"),
        content: const Text("Your account has been banned and you cannot log in."),
        actions: <Widget>[
          TextButton(
            child: const Text("OK"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
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

  void _showErrorSnackBar(String? message) {
    final snackBar = SnackBar(
      content: Text(message ?? 'An error occurred'),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Log In',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.blueAccent),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.blueAccent),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      moveToPage(context, const ForgotPasswordPage(), false);
                    },
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
                    : ElevatedButton(
                        onPressed: _loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Log In',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () {
                      moveToPage(context, const SignUpPage(), true);
                    },
                    child: const Text(
                      'Don’t have an account? Sign Up',
                      style: TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
