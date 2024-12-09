import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_options_page.dart';

class SignUpPage extends StatefulWidget {
  final SignUpMethod? initialSignUpMethod; // Change type from `bool?` to `SignUpMethod?`

  const SignUpPage({Key? key, required this.initialSignUpMethod}) : super(key: key);

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  late SignUpMethod _currentSignUpMethod;

  @override
  void initState() {
    super.initState();
    _currentSignUpMethod = widget.initialSignUpMethod ?? SignUpMethod.email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorSnackBar('Passwords do not match');
      return;
    }

    _setLoadingState(true);

    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      await _storeUserDetails(userCredential.user!.uid, email: _emailController.text.trim());
      _showSuccessSnackBar('Sign-Up Successful');
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Sign-Up failed');
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _signUpWithPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoadingState(true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithPhoneCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showErrorSnackBar(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _showSMSCodeDialog(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _signUpWithGoogle() async {
    _setLoadingState(true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _storeUserDetails(userCredential.user!.uid, email: userCredential.user!.email);

      _showSuccessSnackBar('Google Sign-Up Successful');
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Google Sign-Up failed: ${e.toString()}');
      print(e.toString());
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      await _storeUserDetails(userCredential.user!.uid, phoneNumber: _phoneController.text.trim());
      _showSuccessSnackBar('Phone Sign-Up Successful');
      Navigator.of(context).pop();
    } catch (e) {
      _showErrorSnackBar('Sign-Up failed');
    }
  }

  Future<void> _storeUserDetails(String userId, {String? email, String? phoneNumber}) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'email': email,
      'phoneNumber': phoneNumber,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _showSMSCodeDialog(String verificationId) {
    final smsCodeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Enter SMS Code'),
        content: TextField(
          controller: smsCodeController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'SMS Code'),
        ),
        actions: [
          TextButton(
            child: const Text('Verify'),
            onPressed: () async {
              Navigator.of(context).pop();
              final credential = PhoneAuthProvider.credential(
                verificationId: verificationId,
                smsCode: smsCodeController.text,
              );
              await _signInWithPhoneCredential(credential);
            },
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _setLoadingState(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  String _getSignUpMethodText() {
    switch (_currentSignUpMethod) {
      case SignUpMethod.email:
        return 'Email';
      case SignUpMethod.phone:
        return 'Phone';
      case SignUpMethod.google:
        return 'Google';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOptionButton(
                    context: context,
                    text: 'Email',
                    isSelected: _currentSignUpMethod == SignUpMethod.email,
                    onTap: () => setState(() => _currentSignUpMethod = SignUpMethod.email),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionButton(
                    context: context,
                    text: 'Phone',
                    isSelected: _currentSignUpMethod == SignUpMethod.phone,
                    onTap: () => setState(() => _currentSignUpMethod = SignUpMethod.phone),
                  ),
                  const SizedBox(width: 8),
                  _buildOptionButton(
                    context: context,
                    text: 'Google',
                    isSelected: _currentSignUpMethod == SignUpMethod.google,
                    onTap: _signUpWithGoogle,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_currentSignUpMethod == SignUpMethod.email)
                Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
                      obscureText: true,
                    ),
                  ],
                )
              else if (_currentSignUpMethod == SignUpMethod.phone)
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter phone number with country code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _currentSignUpMethod == SignUpMethod.email
                    ? _signUpWithEmail
                    : _signUpWithPhoneNumber,
                child: Text('Sign Up with ${_getSignUpMethodText()}'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue : Colors.grey[200],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}