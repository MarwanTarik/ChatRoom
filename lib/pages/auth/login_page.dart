import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../home/main_navigation_page.dart';
import 'signup_page.dart';
import 'auth_options_page.dart';

class LoginPage extends StatefulWidget {
  final LoginMethod? initialLoginMethod;

  const LoginPage({Key? key, this.initialLoginMethod}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  late LoginMethod _currentLoginMethod;

  @override
  void initState() {
    super.initState();
    _currentLoginMethod = widget.initialLoginMethod ?? LoginMethod.email;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    _setLoadingState(true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      _showSuccessSnackBar('Login Successful');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainNavigationPage()), // Replace current page with MainNavigationPage
      );
    } on FirebaseAuthException catch (e) {
      _showErrorSnackBar(e.message ?? 'Login failed');
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _loginWithPhoneNumber() async {
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

  Future<void> _loginWithGoogle() async {
    _setLoadingState(true);

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
        await FirebaseAuth.instance.signInWithCredential(credential);
        _showSuccessSnackBar('Google Sign-In Successful');

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => MainNavigationPage()), // Replace current page with MainNavigationPage
        );
      }
    } catch (e) {
      _showErrorSnackBar('Google Sign-In failed: ${e.toString()}');
    } finally {
      _setLoadingState(false);
    }
  }

  Future<void> _signInWithPhoneCredential(PhoneAuthCredential credential) async {
    try {
      await FirebaseAuth.instance.signInWithCredential(credential);
      _showSuccessSnackBar('Phone Login Successful');
    } catch (e) {
      _showErrorSnackBar('Login failed');
    }
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
          decoration: const InputDecoration(
            hintText: 'SMS Code',
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Verify'),
            onPressed: () async {
              Navigator.of(context).pop();
              PhoneAuthCredential credential = PhoneAuthProvider.credential(
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _setLoadingState(bool isLoading) {
    setState(() {
      _isLoading = isLoading;
    });
  }

  String _getLoginMethodText() {
    switch (_currentLoginMethod) {
      case LoginMethod.email:
        return 'Email';
      case LoginMethod.phone:
        return 'Phone';
      case LoginMethod.google:
        return 'Google';
    }
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
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue, width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Login method selection buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOptionButton(
                    context: context,
                    text: 'Email',
                    isSelected: _currentLoginMethod == LoginMethod.email,
                    onTap: () {
                      setState(() {
                        _currentLoginMethod = LoginMethod.email;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildOptionButton(
                    context: context,
                    text: 'Phone',
                    isSelected: _currentLoginMethod == LoginMethod.phone,
                    onTap: () {
                      setState(() {
                        _currentLoginMethod = LoginMethod.phone;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildOptionButton(
                    context: context,
                    text: 'Google',
                    isSelected: _currentLoginMethod == LoginMethod.google,
                    onTap: () {
                      setState(() {
                        _currentLoginMethod = LoginMethod.google;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Conditional login fields
              if (_currentLoginMethod == LoginMethod.email)
                Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        // Basic email validation
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                )
              else if (_currentLoginMethod == LoginMethod.phone)
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    hintText: 'Enter phone number with country code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    // Basic phone number validation (adjust regex as needed)
                    final phoneRegex = RegExp(r'^[+]\d{10,14}$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Please enter a valid phone number with country code';
                    }
                    return null;
                  },
                )
              else
                const SizedBox.shrink(), // Google login doesn't need input fields

              const SizedBox(height: 24),

              // Login button
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  switch (_currentLoginMethod) {
                    case LoginMethod.email:
                      _loginWithEmail();
                      break;
                    case LoginMethod.phone:
                      _loginWithPhoneNumber();
                      break;
                    case LoginMethod.google:
                      _loginWithGoogle();
                      break;
                  }
                },
                child: Text('Login with ${_getLoginMethodText()}'),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignUpPage(initialSignUpMethod: null,)),
                  );
                },
                child: const Text('Don\'t have an account? Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}