import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:quick_cab/appinfo/app_info.dart';
import 'package:quick_cab/firebase_options.dart';
import 'package:quick_cab/modules/splash/views/pages/splash_screen.dart';
import 'package:quick_cab/shared/methods/dependency_injection.dart';
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

  
  runApp(ChangeNotifierProvider(
    create: (context) => AppInfo(),
    child: GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black
      ),
      home:(const SplashScreen())),
  ));
    DependencyInjection.init();
}