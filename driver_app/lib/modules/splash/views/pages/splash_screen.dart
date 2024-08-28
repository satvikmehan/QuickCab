import 'dart:async';
import 'package:driver_app/modules/splash/views/pages/dashboard.dart';
import 'package:driver_app/modules/splash/views/pages/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool isAnim = false;
  void _setAnimationTimer(){
    Timer(const Duration(seconds: 3), (){
      setState(() {
        isAnim = true;
      });
    });
  }

  void _moveToLogin()
  {
    Timer(const Duration(seconds: 5),
    ()
    {
      Navigator.of(context).push(MaterialPageRoute(builder: (_){return FirebaseAuth.instance.currentUser == null? const LoginScreen() : const Dashboard();}));
    }
    );
  }
  @override
  void initState() {
    super.initState();
    _setAnimationTimer();
    _moveToLogin();
  }
  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    width: isAnim ? 0.0 : deviceSize.width,
                    height: isAnim ? 0.0 : deviceSize.height,
                    duration: const Duration(seconds: 2),
                    padding: const EdgeInsets.all(10),
                    child:Image.asset("assets/images/LogoT.png")
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}