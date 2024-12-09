import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task1/pages/auth/logout_widget.dart';

import '../../providers/user_provider.dart';
import '../auth/login_page.dart';
import 'chat_page.dart';

class ChatRoomsPage extends StatelessWidget {
  const ChatRoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        actions: [
          LogoutButton(
            onLogoutSuccess: () {
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => LoginPage())
              );
            },
            color: Colors.green,
            textColor: Colors.black,
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final channels = userProvider.channels;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Channels',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: channels.length,
                  itemBuilder: (context, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(channels[index]),
                        subtitle: const Text('Channel chat room'),
                        trailing: const Icon(Icons.chat_bubble_outline),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatPage(
                                channelId: channels[index],
                                otherUserName: channels[index],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
