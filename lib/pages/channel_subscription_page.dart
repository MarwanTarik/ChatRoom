import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelSubscriptionPage extends StatefulWidget {
  const ChannelSubscriptionPage({super.key});

  @override
  ChannelSubscriptionPageState createState() =>
      ChannelSubscriptionPageState();
}

class ChannelSubscriptionPageState extends State<ChannelSubscriptionPage> {
  final List<String> channels = ['Sports', 'News', 'Technology', 'Health'];
  final Set<String> subscribedChannels = {};
  late String? userId;

  @override
  void initState() {
    super.initState();
    _loadSubscribedChannels();

    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        setState(() {
          userId = user.uid;
        });
        _loadSubscribedChannels();
      } else {
        print('User is not logged in.');
      }
    });
  }

  Future<void> _loadSubscribedChannels() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['subscribedChannels'] is List) {
        setState(() {
          subscribedChannels.addAll(List<String>.from(data['subscribedChannels']));
        });
      }
    }
  }

  Future<void> _saveSubscribedChannels() async {
    print(userId);
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'subscribedChannels': subscribedChannels.toList(),
    }, SetOptions(merge: true));
  }

  void toggleSubscription(String channel) async {
    if (subscribedChannels.contains(channel)) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(channel);
      setState(() {
        subscribedChannels.remove(channel);
      });
    } else {
      await FirebaseMessaging.instance.subscribeToTopic(channel);
      setState(() {
        subscribedChannels.add(channel);
      });
    }
    await _saveSubscribedChannels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe to Channels'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          final isSubscribed = subscribedChannels.contains(channel);

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(
                channel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSubscribed ? Colors.teal : Colors.black,
                ),
              ),
              trailing: Switch(
                value: isSubscribed,
                onChanged: (value) => toggleSubscription(channel),
                activeColor: Colors.teal,
              ),
            ),
          );
        },
      ),
    );
  }
}
