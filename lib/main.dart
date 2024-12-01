import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task1/pages/auth/auth_wrapper.dart';
import 'package:task1/providers/user_provider.dart';
import 'package:task1/repositories/channels/channels_remote_repo.dart';

import 'repositories/channels/channels_repo_interface.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide the Channels Repository
        Provider<IChannelsRepo>(
          create: (_) => ChannelsRemoteRepo(),
        ),
        // Provide the UserProvider
        ChangeNotifierProxyProvider<IChannelsRepo, UserProvider>(
          create: (context) => UserProvider(
            context.read<IChannelsRepo>(),
            '', // Empty string initially, will be set after authentication
          ),
          update: (context, channelsRepo, userProvider) {
            // Get current user ID directly from FirebaseAuth
            final user = FirebaseAuth.instance.currentUser;
            final userId = user?.uid ?? '';

            return userProvider!
              ..updateDependencies(
                  channelsRepo,
                  userId
              );
          },
        ),
      ],
      child: MaterialApp(
        title: 'Chat App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}