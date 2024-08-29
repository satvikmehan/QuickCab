import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quick_cab/modules/splash/views/pages/home_page.dart';
import 'package:quick_cab/modules/splash/views/pages/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  void _moveToLogin()
  {
    Timer(const Duration(seconds: 2),
    ()
    {
      Navigator.of(context).push(MaterialPageRoute(builder: (_){return FirebaseAuth.instance.currentUser == null? const LoginScreen() : const HomePage();}));
    }
    );
  }
  @override
  void initState() {
    super.initState();
    //_moveToLogin();
  }
  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body:  Stack(
          children: [
            Container(
        decoration:const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
                  Column(
                    children: [
                      Container(
                        width: deviceSize.width,
                        height: deviceSize.height/2,
                        padding: EdgeInsets.only(top:deviceSize.width/100,bottom:deviceSize.width/100,left:deviceSize.width/30,right:deviceSize.width/30),
                        child:Image.asset("assets/images/title.png"),
                      ),
                      
                      SizedBox(height: deviceSize.height/3),
                      Container(
                         width: deviceSize.width,
                        height: deviceSize.height/8,
                        padding: EdgeInsets.only(top:deviceSize.width/100,bottom:deviceSize.width/100,left:deviceSize.width/15,right:deviceSize.width/15),
                        child:Image.asset("assets/images/By.png")
                      ),
                      SizedBox(height: deviceSize.height/27),
                      const LinearProgressIndicator(
                        color: Colors.white,
                      )
                    ],
                  ),
          ],
        ),
    );
  }
}