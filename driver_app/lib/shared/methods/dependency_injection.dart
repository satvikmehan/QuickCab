import 'package:driver_app/shared/methods/network.dart';
import 'package:get/get.dart';

class DependencyInjection
{
  static void init()
  {
    Get.put<Network>(Network(),permanent:true);
  }
}