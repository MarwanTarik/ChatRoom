import 'package:task1/entities/message.dart';

interface class IRepo {
  Future<void> send(Message message) async {}

  Future<List<Message>> receive(String channel) async {
    return [];
  }
}