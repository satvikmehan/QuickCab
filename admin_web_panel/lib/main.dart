import 'package:admin_web_panel/dashboard/side_navigation_drawer.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

  void main() async
{
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions
    (
    apiKey: "AIzaSyBeHUHlfj6N8A0Aj1_ZIocE_jU2V38AXRM",
    authDomain: "quickcab-b8b8a.firebaseapp.com",
    databaseURL: "https://quickcab-b8b8a-default-rtdb.firebaseio.com",
    projectId: "quickcab-b8b8a",
    storageBucket: "quickcab-b8b8a.appspot.com",
    messagingSenderId: "1082266719078",
    appId: "1:1082266719078:web:ed03bc15dd5b0b7dc76ea7",
    measurementId: "G-EDHV4XJDWC"
    )
  );
  
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      primarySwatch: Colors.pink,
    ),
    home:(const SideNavigationDrawer())));
}