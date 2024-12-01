import 'dart:async';

interface class IChannelsRepo {
  Future add(String channel, String userId) async {}

  Future remove(String channel, String userId) async {}

  Future<List<String>> list(String userId) async {return [];}
}