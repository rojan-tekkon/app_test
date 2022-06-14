import 'package:bluetooth_test/firebase_options.dart';
import 'package:bluetooth_test/home_screen.dart';
import 'package:bluetooth_test/mobX/provider/auth_provider.dart';
import 'package:bluetooth_test/mobX/provider/reminders_provider.dart';
import 'package:bluetooth_test/mobX/state/app_state.dart';
import 'package:bluetooth_test/news_service.dart';
import 'package:bluetooth_test/providers/news_change_notifier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    Provider(
      create: (_) => AppState(
        authProvider: FirebaseAuthProvider(),
        remindersProvider: FirestoreRemindersProvider(),
      )..initialize(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, theme: ThemeData(primarySwatch: Colors.blue),
      home: ChangeNotifierProvider(
        create: (_) => NewsChangeNotifier(NewsService()),
        child: const HomeScreen(),
      ),

      // ReactionBuilder(
      //   builder: (context) {
      //     return autorun((_) {
      //       final isLoading = context.read<AppState>().isLoading;
      //       if (isLoading) {
      //         LoadingScreen.instance().show(context: context, text: "Loading...");
      //       } else {
      //         LoadingScreen.instance().hide();
      //       }

      //       final authError = context.read<AppState>().authError;
      //       if (authError != null) {
      //         showAuthError(authError: authError, context: context);
      //       }
      //     });
      //   },
      //   child: Observer(builder: (context) {
      //     switch (context.read<AppState>().currentScreen) {
      //       case AppScreen.login:
      //         return const LoginView();
      //       case AppScreen.register:
      //         return const RegisterView();
      //       case AppScreen.reminders:
      //         return const RemindersView();
      //     }
      //   }),
      // ),
    );
  }
}
