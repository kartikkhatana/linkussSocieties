import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:linkuss/bottombar.dart';
import 'package:linkuss/currentUser.dart';
import 'package:linkuss/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(Duration(seconds: 2), () async {
      if (FirebaseAuth.instance.currentUser != null) {
        final prefs = await SharedPreferences.getInstance();

        CurrentUser.name = prefs.getString("name") ?? "";
        CurrentUser.email = prefs.getString("email") ?? "";
        CurrentUser.college = prefs.getString("college") ?? "";

        Navigator.pop(context);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => BottomBar()));
      } else {
        Navigator.pop(context);
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginPage()));
      }
      // Navigator.pop(context);
      // Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => LoginPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          "LinkUSS",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
    );
  }
}
