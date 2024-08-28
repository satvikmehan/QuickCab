import 'package:driver_app/firebase_options.dart';
import 'package:driver_app/modules/splash/views/pages/splash_screen.dart';
import 'package:driver_app/shared/methods/dependency_injection.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
Future<void> main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);

  await Permission.locationWhenInUse.isDenied.then((valueOfPermission)
  {
    if(valueOfPermission){
      Permission.locationWhenInUse.request();
    }
  });

  await Permission.notification.isDenied.then((valueOfPermission)
  {
    if(valueOfPermission){
      Permission.notification.request();
    }
  });

  
  runApp(GetMaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: Colors.black
    ),
    home:(const SplashScreen())));
    DependencyInjection.init();
}