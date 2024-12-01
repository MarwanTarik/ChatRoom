import 'package:flutter/cupertino.dart';

import '../repositories/channels/channels_repo_interface.dart';

class UserProvider with ChangeNotifier {
  IChannelsRepo _channelsRepo;
  String _currentUserId = '';
  List<String> _channels = [];
  bool _isLoading = false;

  UserProvider(this._channelsRepo, this._currentUserId);

  String get currentUserId => _currentUserId;
  List<String> get channels => List.unmodifiable(_channels); // Protect list immutability
  bool get isLoading => _isLoading;

  void updateDependencies(IChannelsRepo channelsRepo, String userId) {
    _channelsRepo = channelsRepo;
    _currentUserId = userId;

    if (userId.isNotEmpty) {
      loadChannels();
    }
  }

  Future<void> loadChannels() async {
    if (_currentUserId.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final fetchedChannels = await _channelsRepo.list(_currentUserId);
      _channels = List<String>.from(fetchedChannels); // Update local list
    } catch (e) {
      _channels = [];
      print('Error loading channels: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addChannel(String channel) async {
    try {
      await _channelsRepo.add(channel, _currentUserId);
      _channels.add(channel); // Immediately update local list
      notifyListeners(); // Notify listeners after adding
    } catch (e) {
      print('Error adding channel: $e');
      rethrow;
    }
  }

  Future<void> removeChannel(String channel) async {
    try {
      await _channelsRepo.remove(channel, _currentUserId);
      _channels.remove(channel); // Immediately update local list
      notifyListeners(); // Notify listeners after removing
    } catch (e) {
      print('Error removing channel: $e');
      rethrow;
    }
  }

  Future<void> refreshChannels() async {
    await loadChannels();
  }
}
