import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:golden_ticket_enterprise/secret.dart';
import 'package:golden_ticket_enterprise/styles/colors.dart';
import 'package:golden_ticket_enterprise/models/http_request.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // This widget is the root of your application.

  @override
  void initState(){
    super.initState();
    var box = Hive.box<HiveSession>('sessionBox');
    var userSession = box.get('user');
    if (userSession != null) {
      print("User session found: ${userSession.user.username}");
      // Get the passed User data
      final HiveSession? session = box.get('user')!;
      User data = User.fromJson(session!.user.toJson());
      context.go('/hub', extra: data);
    }
  }
  void _login() async {
    String username = usernameController.text;
    String password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please enter both fields")));
      return;
    }


    var url = Uri.http(kBaseURL, kLogin);

    var response = await http.requestJson(
        url,
        method: http.RequestMethod.post,
        body: {
          'username': usernameController.text,
          'password': passwordController.text
        }
    );

    if (response['status'] == 200) {
      User data = User.fromJson(response['body']['user']);
      var box = Hive.box<HiveSession>('sessionBox');
      box.put('user', HiveSession.fromJson(response['body']));
      context.go('/hub', extra: data);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: ${response['message']}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: kSurface,
        appBar: AppBar(
          // TRY THIS: Try changing the color here to a specific color (to
          // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
          // change color while the other colors stay the same.
          backgroundColor: kPrimary,
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text("Login"),
        ),
        body: Center(
          child: Card(
            elevation: 8,
            color: kPrimaryContainer,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: 320, // Adjust width for web responsiveness
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Login",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 20),
                    TextField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        labelText: "Username",
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      onSubmitted: (val) => _login(),
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => _login(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                      ),
                      child: Text("Login", style: TextStyle(fontSize: 16, color: kSurface)),
                    ),
                    SizedBox(height: 10),
                    TextButton(
                      onPressed: () {
                        print("Navigate to Forgot Password");
                      },
                      child: Text("Forgot Password?",
                          style: TextStyle(color: Colors.blue)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ) // This trailing comma makes auto-formatting nicer for build methods.
        );
  }
}
