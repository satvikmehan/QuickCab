import 'dart:io';
import 'package:driver_app/modules/splash/views/pages/dashboard.dart';
import 'package:driver_app/modules/splash/views/pages/login_screen.dart';
import 'package:driver_app/modules/splash/views/widgets/loading_dialog.dart';
import 'package:driver_app/shared/methods/common_methods.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

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
  TextEditingController vehicleModelTextEditingController = TextEditingController(); 
  TextEditingController vehicleColorTextEditingController = TextEditingController();
  TextEditingController vehicleNumberTextEditingController = TextEditingController();
  CommonMethods cMethods = CommonMethods();
  XFile? imageFile;
  String urlOfUploadedImage = "";

  check()
  {
   if(imageFile != null)
   {
    signUpFormValidation(); 
   }
   else
   {
    cMethods.displaySnackBar("Please choose an image first", context);
   }
  }


  signUpFormValidation()
  {
    if(userNameTextEditingController.text.trim().length < 4)
    {
      cMethods.displaySnackBar("Your name must be atleast 4 or more characters", context);
    }
    else if(userPhoneTextEditingController.text.trim().length != 10)
    {
      cMethods.displaySnackBar("Invalid Number", context);
    }
    else if(!emailTextEditingController.text.contains("@"))
    {
      cMethods.displaySnackBar("Invalid Email", context);
    }
    else if(vehicleModelTextEditingController.text.trim().length < 6)
    {
      cMethods.displaySnackBar("Your password must be atleast 6 or more characters", context);
    }
    else if(passwordTextEditingController.text.trim().isEmpty)
    {
      cMethods.displaySnackBar("Please write your car model", context);
    }
    else if(vehicleColorTextEditingController.text.trim().isEmpty)
    {
      cMethods.displaySnackBar("Please write your car color", context);
    }
    else if(vehicleNumberTextEditingController.text.trim().isEmpty)
    {
      cMethods.displaySnackBar("Please write your car number", context);
    }
    else
    {
      uploadImageToStorage();
    }
  }

  uploadImageToStorage() async
  {
    String imageIDName = DateTime.now().millisecondsSinceEpoch.toString();
    Reference referenceImage = FirebaseStorage.instance.ref().child("Images").child(imageIDName);

    SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

    UploadTask uploadTask = referenceImage.putFile(File(imageFile!.path),metadata);
    TaskSnapshot snapshot = await uploadTask;
    urlOfUploadedImage = await snapshot.ref.getDownloadURL();

    setState(() 
    {
      urlOfUploadedImage;
    }
    );

    registerNewDriver();
  }

  registerNewDriver() async
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

    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("drivers").child(userFirebase!.uid);

    Map driverCarInfo = 
    {
      "carColor": vehicleColorTextEditingController.text.trim(),
      "carModel": vehicleModelTextEditingController.text.trim(),
      "carNumber": vehicleNumberTextEditingController.text.trim()
    };


    Map driverDataMap = 
    {
      "photo":urlOfUploadedImage,
      "car_details":driverCarInfo,
      "name":userNameTextEditingController.text.trim(),
      "email":emailTextEditingController.text.trim(),
      "phone":userPhoneTextEditingController.text.trim(),
      "id":userFirebase.uid,
      "blockStatus":"no",
    };
    usersRef.set(driverDataMap);

    // ignore: use_build_context_synchronously
    Navigator.push(context, MaterialPageRoute(builder: (c) => const Dashboard()));
  }

  chooseImageFromGallery() async
  {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(pickedFile != null){
      setState(() {
        imageFile = pickedFile;
      });
    } 

  }


  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    return  Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding:EdgeInsets.only(top:deviceSize.height/10,left:10,right:10,bottom:10),
          child: Center(
            child: Column(
              children: [

                imageFile == null?
                const CircleAvatar(
                  radius: 86,
                  backgroundImage: AssetImage(
                    "assets/images/avatar.png"
                  ),
                ): 
                Container
                (
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                  image: DecorationImage(
                    fit: BoxFit.fitHeight,
                    image: FileImage(
                      File(
                        imageFile!.path
                      )
                    )
                   )
                  )
                ),
                const SizedBox(height:25),
                GestureDetector(
                  onTap: ()
                  {
                    chooseImageFromGallery();
                  },
                  child: const Text(
                    "Choose Image",
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ),
                Padding(
                  padding:const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      TextField(
                        controller: userNameTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Name",
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
                        controller: userPhoneTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
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
                        controller: emailTextEditingController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: "Email",
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
                          labelText: "Password",
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
                        controller: vehicleModelTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Vehicle Model",
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
                        controller: vehicleColorTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Vehicle Color",
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
                        controller: vehicleNumberTextEditingController,
                        keyboardType: TextInputType.text,
                        decoration: const InputDecoration(
                          labelText: "Vehicle Number",
                          labelStyle: TextStyle(
                            fontSize: 25,
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 15
                        ),
                      ),
                      const SizedBox(height: 45),
                      ElevatedButton(
                        onPressed: () 
                        {
                          check();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 7, 3, 84),
                          padding: const EdgeInsets.symmetric(horizontal: 50,vertical: 20)
                        ),
                         child: const Text(
                          "Sign Up",
                          style: TextStyle(fontSize:20,color:Colors.white),
                         )
                         ),
                    ],
                  ),
                  ),
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
    );
  }
}