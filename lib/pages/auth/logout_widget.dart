import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LogoutButton extends StatelessWidget {
  final VoidCallback? onLogoutSuccess;
  final Color? color;
  final Color? textColor;

  const LogoutButton({
    Key? key,
    this.onLogoutSuccess,
    this.color,
    this.textColor,
  }) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();

      // Optional callback for custom navigation or actions
      onLogoutSuccess?.call();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _logout(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? Colors.red,
        foregroundColor: textColor ?? Colors.white,
      ),
      child: Text('Logout'),
    );
  }
}

// Optional: Full logout dialog for more control
class LogoutDialog extends StatelessWidget {
  const LogoutDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Logout'),
      content: Text('Are you sure you want to logout?'),
      actions: [
        TextButton(
          child: Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: Text('Logout'),
          onPressed: () {
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}