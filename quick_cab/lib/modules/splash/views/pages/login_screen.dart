import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quick_cab/gloabal/global_var.dart';
import 'package:quick_cab/modules/splash/views/pages/home_page.dart';
import 'package:quick_cab/modules/splash/views/pages/signup_screen.dart';
import 'package:quick_cab/modules/splash/views/widgets/loading_dialog.dart';
import 'package:quick_cab/shared/methods/common_methods.dart';
import 'package:sign_in_button/sign_in_button.dart';

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
      builder: (BuildContext context) => LoadingDialog(messageText: "Authenticating, Please Wait...")
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
      DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase.uid);
      await usersRef.once().then((snap)
      {
        if(snap.snapshot.value != null)
        {
          if((snap.snapshot.value as Map)["blockStatus"] == "no")
          {
            userName = (snap.snapshot.value as Map)["name"];
            userPhone = (snap.snapshot.value as Map)["phone"];
            Navigator.push(context, MaterialPageRoute(builder: (c) => const HomePage()));
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
          cMethods.displaySnackBar("Your Record do not exist as a User", context);
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: const BorderSide(
        width: 1,
      ),
      borderRadius: BorderRadius.circular(50),
    );
    Size deviceSize = MediaQuery.of(context).size;
    return Scaffold(
      body:SingleChildScrollView(
        child: Container(
            decoration:const BoxDecoration(
                    
                    image: DecorationImage(
                      image: AssetImage('assets/images/background1.jpeg'),
                      fit: BoxFit.cover,
                    ),
                  ),
            child: Padding(
            padding:EdgeInsets.only(top:deviceSize.height/10,left:10,right:10,bottom:10),
            child: Center(
              child: Column(
                children: [
                  Container(
                    height: deviceSize.height/6,
                    child:Image.asset(
                    "assets/images/IconT.png", 
                    )
                  ),
                  const SizedBox(height:25),
                  const Text(
                    "Login as a User",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
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
                          decoration: InputDecoration(
                            hintText: "User Email",
                            hintStyle: const TextStyle(
                            fontSize: 20,
                            color:Colors.white
                            ),
                            prefixIcon:Icon(Icons.email_rounded),
                            prefixIconColor: Colors.black,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            focusedBorder: border,
                            enabledBorder: border,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 22),
                        TextField(
                          controller: passwordTextEditingController,
                          obscureText: true,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: "User Password",
                            hintStyle: const TextStyle(
                              fontSize: 20,
                              color:Colors.white
                            ),
                            prefixIcon: const Icon(Icons.key_rounded),
                            prefixIconColor:Colors.black,
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.5),
                            focusedBorder: border,
                            enabledBorder: border,
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20
                          ),
                        ),
                        SizedBox(height: deviceSize.height/20,),
                        ElevatedButton(
                          onPressed: () 
                          {
                            signInFormValidation();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:Colors.black.withOpacity(0.6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 50,vertical: 20)
                          ),
                           child: const Text(
                            "Login",
                            style: TextStyle(
                              fontSize:20,
                              color:Colors.white
                              ),
                           )
                           ),
                           SizedBox(height: deviceSize.height/20,),
                           const Row(
                            children: 
                           [
                            Expanded(
                              child: Divider(
                              thickness: 5,
                              color: Colors.black,
                              indent: 10,
                              endIndent: 10,
                            )),
                            Text("OR", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,color: Colors.grey),),
                            Expanded(
                              child: Divider(
                              thickness: 5,
                              color: Colors.black,
                              indent: 10,
                              endIndent: 10,
                            )),
                          ]),
                          SizedBox(height: deviceSize.height/20),
                          SignInButton(
                            Buttons.google, 
                            onPressed: (){},
                            text: "Log In With Google",
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                            )
                          )
                          ]
                    ),
                    ),
                    SizedBox(height: deviceSize.height/50),
                    TextButton(
                      onPressed: () 
                      {
                        Navigator.push(context,MaterialPageRoute(builder: (c)=>const SignupScreen()));
                      },
                       child:const Text(
                        "Don't have an Account? Register Here",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                       )
                       )
                ],
              ),
            ),
          ),),
      )
    );
  }
}