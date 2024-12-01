import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task1/repositories/channels/channels_repo_interface.dart';

class ChannelsRemoteRepo implements IChannelsRepo {
  final List<String> subscribedChannels = [];

  @override
  Future add(String channel, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'subscribedChannels': FieldValue.arrayUnion([channel])
      });
    } catch (e) {
      print('Error adding channel: $e');
    }
  }


  @override
  Future<List<String>> list(String userId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (snapshot.exists) {
      final data = snapshot.data();
      if (data != null && data['subscribedChannels'] is List) {
          subscribedChannels.addAll(List<String>.from(data['subscribedChannels']));
      }
    }
    return subscribedChannels;
  }

  @override
  Future remove(String channel, String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'subscribedChannels': FieldValue.arrayRemove([channel])
      });
    } catch (e) {
      print('Error removing channel: $e');
    }
  }
}