import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:task1/repositories/channels/channels_repo_interface.dart';
import '../../providers/user_provider.dart';
import '../../repositories/channels/channels_remote_repo.dart';

class ChannelSubscriptionPage extends StatefulWidget {
  const ChannelSubscriptionPage({super.key});

  @override
  ChannelSubscriptionPageState createState() =>
      ChannelSubscriptionPageState();
}

class ChannelSubscriptionPageState extends State<ChannelSubscriptionPage> {
  final List<String> channels = ['Sports', 'News', 'Technology', 'Health'];
  final Set<String> subscribedChannels = {};
  final IChannelsRepo _channelsRepo = ChannelsRemoteRepo();
  late String? userId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  void _initializeUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
      _loadSubscribedChannels();
    } else {
      print('User is not logged in.');
    }
  }

  Future<void> _loadSubscribedChannels() async {
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> channels = await _channelsRepo.list(userId!);
      setState(() {
        subscribedChannels.clear();
        subscribedChannels.addAll(channels);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load subscribed channels: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void toggleSubscription(String channel) async {
    if (userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (subscribedChannels.contains(channel)) {
        await FirebaseMessaging.instance.unsubscribeFromTopic(channel);
        await _channelsRepo.remove(channel, userId!);
        setState(() {
          subscribedChannels.remove(channel);
        });
        // Update the UserProvider after unsubscribing
        Provider.of<UserProvider>(context, listen: false).removeChannel(channel);
      } else {
        await FirebaseMessaging.instance.subscribeToTopic(channel);
        await _channelsRepo.add(channel, userId!);
        setState(() {
          subscribedChannels.add(channel);
        });
        // Update the UserProvider after subscribing
        Provider.of<UserProvider>(context, listen: false).addChannel(channel);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to toggle subscription: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscribe to Channels'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
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
