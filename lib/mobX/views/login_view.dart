import 'package:bluetooth_test/extensions/if_debugging.dart';
import 'package:bluetooth_test/home_screen.dart';
import 'package:bluetooth_test/mobX/state/app_state.dart';
import 'package:bluetooth_test/news_service.dart';
import 'package:bluetooth_test/providers/news_change_notifier.dart';
import 'package:bluetooth_test/utilities.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

class LoginView extends HookWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emailController = useTextEditingController(text: "roj.shr1996@gmail.com".ifDebugging);
    final passwordController = useTextEditingController(text: "password".ifDebugging);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: "Email",
              ),
              keyboardAppearance: Brightness.dark,
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                hintText: "Password",
              ),
              obscureText: true,
              keyboardType: TextInputType.visiblePassword,
              keyboardAppearance: Brightness.dark,
            ),
            TextButton(
              onPressed: () {
                final email = emailController.text;
                final password = passwordController.text;

                context.read<AppState>().login(email: email, password: password);
              },
              child: const Text("Login"),
            ),
            TextButton(
              onPressed: () {
                context.read<AppState>().goto(AppScreen.register);
              },
              child: const Text("Not registered yet? Register here!"),
            ),
            OutlinedButton(
              onPressed: () {
                Utilities.openActivity(
                    context,
                    ChangeNotifierProvider(
                        create: (_) => NewsChangeNotifier(NewsService()), child: const HomeScreen()));
              },
              child: const Text("GET HOME SCREEN"),
            ),
          ],
        ),
      ),
    );
  }
}
