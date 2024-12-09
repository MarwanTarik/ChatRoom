import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task1/entities/message.dart';
import 'package:task1/repositories/chat/chat_repo_interface.dart';
import 'package:task1/repositories/chat/chat_remote_repo.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatPage extends StatefulWidget {
  final String channelId;
  final String otherUserName;

  const ChatPage({
    super.key,
    required this.channelId,
    required this.otherUserName
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final IChatRepo _chatRepo = ChatRemoteRepo();
  List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeToChannel(widget.channelId);
  }

  Future<void> _fetchMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await _chatRepo.receive(widget.channelId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  Future<void> _sendMessage() async {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      final message = Message(
        currentUserId,
        null, // Firebase will generate the ID
        DateTime.now(),
        messageText,
        widget.channelId,
      );

      // Send message to Firestore
      await _chatRepo.send(message);

      // Send push notification to all subscribed users via your server
      await sendMessageToServer('New Message', messageText, widget.channelId);

      // Clear input and refresh messages
      _messageController.clear();
      await _fetchMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message: $e')),
      );
    }
  }

  Future<void> _subscribeToChannel(String channelId) async {
    await FirebaseMessaging.instance.subscribeToTopic(channelId);
  }

  // Function to send message to server
  Future<void> sendMessageToServer(String title, String body, String topic) async {
    final url = Uri.parse('http://10.0.2.2:3000/send-notification');
    final headers = {"Content-Type": "application/json"};

    // Prepare the message data
    final messageData = {
      "title": title,
      "body": body,
      "topic": topic,
    };

    // Send the request
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: json.encode(messageData),
      );

      if (response.statusCode == 200) {
        print('Message sent successfully');
      } else {
        print('Failed to send message');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                  'https://ui-avatars.com/api/?name=${widget.otherUserName}'),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[300]
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isMe = message.userId == FirebaseAuth.instance.currentUser?.uid;

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                        bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.black54
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
