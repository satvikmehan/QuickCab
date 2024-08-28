import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Network extends GetxController
{
  final Connectivity _connectivity = Connectivity();

  @override
  void onInit() 
  {
    super.onInit();
    _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  void _updateConnectionStatus(List<ConnectivityResult>connectivityResult)
  {
    if(connectivityResult.contains(ConnectivityResult.none))
    {
      Get.rawSnackbar(
        messageText: const Text(
          "Please Check Your Internet Connection and Try Again!!!",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15
          ),
        ),
        isDismissible: false,
        duration: const Duration(days: 1),
        backgroundColor: Colors.grey,
        icon: const Icon(Icons.wifi_off,color: Colors.white,size: 25,),
        margin: EdgeInsets.zero,
        snackStyle: SnackStyle.GROUNDED
      );
    }
    else
    {
      if(Get.isSnackbarOpen)
      {
        Get.closeCurrentSnackbar();
      }
    }
    
  }

}