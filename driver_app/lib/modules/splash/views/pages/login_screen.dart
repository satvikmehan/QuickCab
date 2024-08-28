import 'package:driver_app/modules/splash/views/pages/dashboard.dart';
import 'package:driver_app/modules/splash/views/pages/signup_screen.dart';
import 'package:driver_app/modules/splash/views/widgets/loading_dialog.dart';
import 'package:driver_app/shared/methods/common_methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> { 
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();



  signInFormValidation()
  {
    if(!emailTextEditingController.text.contains("@"))
    {
      cMethods.displaySnackBar("Invalid Email", context);
    }
    else if(passwordTextEditingController.text.trim().length < 6)
    {
      cMethods.displaySnackBar("Your password must be atleast 6 or more characters", context);
    }
    else
    {
      signInUser();
    }

  }

  signInUser() async
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Authenticating, Please Wait....")
    );

    final User? userFirebase = 
    (
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailTextEditingController.text.trim(), 
        password: passwordTextEditingController.text.trim(),
        ).catchError((errorMsg)
        // ignore: body_might_complete_normally_catch_error
        {
          Navigator.pop(context);
          cMethods.displaySnackBar(errorMsg.toString(), context);
        }
        )
    ).user;

    if(!context.mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.pop(context);

    if(userFirebase != null)
    {
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase.uid);
      usersRef.once().then((snap)
      {
        if(snap.snapshot.value != null)
        {
          if((snap.snapshot.value as Map)["blockStatus"] == "no")
          {
            //userName = (snap.snapshot.value as Map)["name"];
            Navigator.push(context, MaterialPageRoute(builder: (c) => const Dashboard()));
          }
          else
          {
            FirebaseAuth.instance.signOut();
            cMethods.displaySnackBar("You are blocked. Contact admin: quickcab0108@gmail.com", context);
          }

        }
        else
        {
          FirebaseAuth.instance.signOut();
          cMethods.displaySnackBar("Your Record do not exist as a Driver", context);
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding:EdgeInsets.only(top:deviceSize.height/10,left:10,right:10,bottom:10),
          child: Center(
            child: Column(
              children: [
                Image.asset(
                  "assets/images/Car.png",          
                ),
                const SizedBox(height:25),
                const Text(
                  "Login as a Driver",
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold
                  ),
                ),
                Padding(
                  padding:const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      const SizedBox(height: 22),                     
                      TextField(
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Your Email",
                          labelStyle: TextStyle(
                            fontSize: 25,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15
                        ),
                      ),
                      const SizedBox(height: 22),
                      TextField(
                        controller: passwordTextEditingController,
                        obscureText: true,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Your Password",
                          labelStyle: TextStyle(
                            fontSize: 25,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15
                        ),
                      ),
                      const SizedBox(height: 75),
                      ElevatedButton(
                        onPressed: () 
                        {
                          signInFormValidation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 7, 3, 84),
                          padding: const EdgeInsets.symmetric(horizontal: 50,vertical: 20)
                        ),
                         child: const Text(
                          "Login",
                          style: TextStyle(fontSize:20,color:Colors.white),
                         )
                         ),
                    ],
                  ),
                  ),
                  SizedBox(height: deviceSize.height/10),
                  TextButton(
                    onPressed: () 
                    {
                      Navigator.push(context,MaterialPageRoute(builder: (c)=>const SignupScreen()));
                    },
                     child:const Text(
                      "Don't have an Account? Register Here",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                     )
                     )
              ],
            ),
          ),
        ),
      ),
    );
  }
}