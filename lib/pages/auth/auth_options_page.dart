import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'signup_page.dart';

class AuthOptionsPage extends StatelessWidget {
  const AuthOptionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueAccent, Colors.lightBlue],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 30.0),
                  child: Image.asset(
                    'assets/logo.png', // Replace with your app logo
                    height: 120,
                    width: 120,
                  ),
                ),
                _buildAuthButton(
                  context: context,
                  text: 'Login with Email',
                  icon: Icons.email,
                  onPressed: () => _navigateToLogin(context, LoginMethod.email),
                  color: Colors.blue,
                ),
                const SizedBox(height: 15),
                _buildAuthButton(
                  context: context,
                  text: 'Login with Phone',
                  icon: Icons.phone,
                  onPressed: () => _navigateToLogin(context, LoginMethod.phone),
                  color: Colors.green,
                ),
                const SizedBox(height: 15),
                _buildAuthButton(
                  context: context,
                  text: 'Login with Google',
                  icon: Icons.g_mobiledata,
                  onPressed: () => _signInWithGoogle(context),
                  color: Colors.red,
                ),
                const SizedBox(height: 15),
                _buildAuthButton(
                  context: context,
                  text: 'Sign Up with Email',
                  icon: Icons.person_add,
                  onPressed: () => _navigateToSignUp(context, SignUpMethod.email),
                  color: Colors.purple,
                ),
                const SizedBox(height: 15),
                _buildAuthButton(
                  context: context,
                  text: 'Sign Up with Phone',
                  icon: Icons.phone_enabled,
                  onPressed: () => _navigateToSignUp(context, SignUpMethod.phone),
                  color: Colors.orange,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 24),
      label: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: onPressed,
    );
  }

  void _navigateToLogin(BuildContext context, LoginMethod method) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoginPage(initialLoginMethod: method),
      ),
    );
  }

  void _navigateToSignUp(BuildContext context, SignUpMethod? method) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SignUpPage(initialSignUpMethod: method),
      ),
    );
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      // Trigger the Google Sign-In process
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser != null) {
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the credential
        final UserCredential userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

        // Store user details in Firestore
        if (userCredential.user != null) {
          await _storeUserDetails(userCredential.user!);
        }
      }
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google Sign-In failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _storeUserDetails(User user) async {
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'providerId': user.providerData[0].providerId,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

// Enums to replace boolean flags
enum LoginMethod { email, phone, google }
enum SignUpMethod { email, phone, google }
