import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'screens/login.dart';
import 'screens/tasks_list.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Girly To-Do App 💖',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFFFF0F5),
        fontFamily: 'Poppins',
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Color(0xFFFFF0F5),
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF758F)),
              ),
            );
          }
          if (snapshot.hasData) {
            return const TasksListScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
