import 'package:flutter/material.dart';

// ignore: must_be_immutable
class LoadingDialog extends StatelessWidget 
{
  String messageText;

  LoadingDialog({super.key,required this.messageText});

  @override
  Widget build(BuildContext context) {
    Size deviceSize = MediaQuery.of(context).size;
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius:BorderRadius.circular(12),
        ),
        backgroundColor: Colors.black87,
        child: ConstrainedBox(
          constraints: BoxConstraints(
          maxHeight: deviceSize.height * 0.8,
          maxWidth: deviceSize.width * 0.9,
        ),
          child: Container(
            margin: const EdgeInsets.only(top: 15,left: 11,right: 11,bottom: 15),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child:  Padding(
              padding:const EdgeInsets.all(15),
              child:
              SingleChildScrollView(child: 
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 5),
                  const CircularProgressIndicator(
                    valueColor:AlwaysStoppedAnimation<Color>(Colors.white)
                    ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      messageText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white
                      ),
                    ),
                  )
                ],
              ),)
              ),
            ),
        ),
    );
  }
}