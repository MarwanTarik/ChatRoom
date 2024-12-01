import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:task1/api/firebase_api.dart';
import 'package:task1/firebase_options.dart';
import 'package:task1/pages/authwrapper.dart';
import 'package:task1/pages/notification_page.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized() ;
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform) ;
  await FirebaseApi().initNotifications();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget{
  const MyApp({super.key});
  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(),
      navigatorKey: navigatorKey,
      routes: {
        '/notification_screen': (context) => const NotificationPage(),
      },
    );
  }
}
