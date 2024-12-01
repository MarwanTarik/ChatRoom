import 'package:firebase_auth/firebase_auth.dart';
import 'package:task1/entities/message.dart';
import 'package:task1/repositories/repo_interface.dart';
import 'package:firebase_database/firebase_database.dart';

class ChatRepo implements IRepo {
  late final DatabaseReference ref;

  ChatRepo() {
    ref = FirebaseDatabase.instance.ref();
  }

  @override
  Future<void> send(Message message) async {
    if (message.userId == null) {
      throw Exception("UnAuthorized");
    }

    final userMessagesRef = ref.child('messages').child(message.channel).child(message.userId!);

    await userMessagesRef.push().set({
      'message': message.text,
      'timestamp': message.timestamp.toIso8601String(), // Convert to ISO 8601 string
    });
  }

  @override
  Future<List<Message>> receive(String channel) async {
    final usersMessagesRef = ref.child('messages').child(channel);
    final snapshot = await usersMessagesRef.get();

    if (snapshot.exists) {
      final messages = Map<String, dynamic>.from(snapshot.value as Map);

      final List<Message> messagesList = [];

      messages.forEach((userId, userMessages) {
        final userMessagesMap = Map<String, dynamic>.from(userMessages);

        userMessagesMap.forEach((messageId, messageData) {
          var newMessage = Message(
              userId,
              messageId,
              DateTime.parse(messageData['timestamp']),
              messageData['message'],
              channel
          );

          messagesList.add(newMessage);
        });
      });

      messagesList.sort((a, b) {
        return (a.timestamp).compareTo(b.timestamp);
      });

      return messagesList;
    }
    return [];
  }
}