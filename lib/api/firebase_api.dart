import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:task1/main.dart';

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance ;

  Future<void> initNotifications() async {
    await _firebaseMessaging.requestPermission();

    final FCMToken = await _firebaseMessaging.getToken() ;
    print('token: $FCMToken') ;

    initPushNotifications();
  }

  void handleMessage(RemoteMessage? message){
    if(message==null) return ;

    navigatorKey.currentState?.pushNamed(
      '/notification_screen',
      arguments: message,
    );
  }

  Future initPushNotifications() async {
    FirebaseMessaging.onMessage.listen(handleMessage);
    FirebaseMessaging.instance.getInitialMessage().then(handleMessage) ;
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }

}