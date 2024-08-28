import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:quick_cab/modules/splash/views/pages/home_page.dart';
import 'package:quick_cab/modules/splash/views/pages/login_screen.dart';
import 'package:quick_cab/modules/splash/views/widgets/loading_dialog.dart';
import 'package:quick_cab/shared/methods/common_methods.dart';
import 'package:sign_in_button/sign_in_button.dart';


class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  TextEditingController userPhoneTextEditingController = TextEditingController();
  TextEditingController userNameTextEditingController = TextEditingController(); 
  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();

  signUpFormValidation()
  {
    if(userNameTextEditingController.text.trim().length < 3)
    {
      cMethods.displaySnackBar("Your name must be atleast 4 or more characters", context);
    }
    else if(userNameTextEditingController.text.trim().length > 15)
    {
      cMethods.displaySnackBar("Your name must be less than 15 characters", context);
    }
    else if(userPhoneTextEditingController.text.trim().length != 10)
    {
      cMethods.displaySnackBar("Invalid Number", context);
    }
    else if(!emailTextEditingController.text.contains("@"))
    {
      cMethods.displaySnackBar("Invalid Email", context);
    }
    else if(passwordTextEditingController.text.trim().length < 6)
    {
      cMethods.displaySnackBar("Your password must be atleast 6 or more characters", context);
    }
    else
    {
      registerNewUser();
    }
  }

  registerNewUser() async
  {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => LoadingDialog(messageText: "Registering your account....")
    );

    final User? userFirebase = 
    (
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
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

    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(userFirebase!.uid);
    Map userDataMap = 
    {
      "name":userNameTextEditingController.text.trim(),
      "email":emailTextEditingController.text.trim(),
      "phone":userPhoneTextEditingController.text.trim(),
      "id":userFirebase.uid,
      "blockStatus":"no",
    };
    usersRef.set(userDataMap);

    // ignore: use_build_context_synchronously
    Navigator.push(context, MaterialPageRoute(builder: (c) => const HomePage()));
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
    return  Scaffold(
      body: SingleChildScrollView(
        child: Container(
          decoration:const BoxDecoration(
                    
                    image: DecorationImage(
                      image: AssetImage('assets/images/background2.jpeg'),
                      fit: BoxFit.cover,
                    ),
                  ),
          child: Padding(
            padding:EdgeInsets.only(top:deviceSize.height/22,left:10,right:10,bottom:10),
            child: Center(
              child: Column(
                children: [
                  Container(
                    height:deviceSize.height/6,
                    child:
                    Image.asset(
                    "assets/images/IconT.png",  
                    ) 
                  ),
                  const SizedBox(height:25),
                  const Text(
                    "Create a User's Account",
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                  Padding(
                    padding:const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const SizedBox(height: 22),
                        TextField(
                          controller: userNameTextEditingController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: "User Name",
                            hintStyle: const TextStyle(
                            fontSize: 20,
                            color:Colors.white
                            ),
                            prefixIcon:const Icon(Icons.person),
                            prefixIconColor: Colors.black,
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
                        const SizedBox(height: 22),
                        TextField(
                          controller: userPhoneTextEditingController,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: "User Phone Number",
                            hintStyle: const TextStyle(
                            fontSize: 20,
                            color:Colors.white
                            ),
                            prefixIcon:const Icon(Icons.phone),
                            prefixIconColor: Colors.black,
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
                        const SizedBox(height: 22),                     
                        TextField(
                          controller: emailTextEditingController,
                          keyboardType: TextInputType.emailAddress,
                          decoration:InputDecoration(
                            hintText: "User Email",
                            hintStyle: const TextStyle(
                              fontSize: 20,
                              color:Colors.white
                            ),
                            prefixIcon:const Icon(Icons.email_rounded),
                            prefixIconColor: Colors.black,
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
                            prefixIcon:const Icon(Icons.key_rounded),
                            prefixIconColor: Colors.black,
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
                        SizedBox(height: deviceSize.height/20),
                        ElevatedButton(
                          onPressed: () 
                          {
                            signUpFormValidation();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40,vertical: 20)
                          ),
                           child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontSize:20,
                              color:Colors.white
                              ),
                           )
                           ),
                           SizedBox(height: deviceSize.height/20),
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
                            )
                            ),
                          ]),
                          SizedBox(height: deviceSize.height/20),
                          SignInButton(
                            Buttons.google, 
                            onPressed: (){},
                            text: "Sign Up With Google",
                            shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)
                            )
                          )
                      ],
                    ),
                    ),
                    SizedBox(height: deviceSize.height/50),
                    TextButton(
                      onPressed: () 
                      {
                        Navigator.push(context,MaterialPageRoute(builder: (c)=>const LoginScreen()));
                      },
                       child:const Text(
                        "Already have an Account? Login Here",
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
      ),
    );
  }
}