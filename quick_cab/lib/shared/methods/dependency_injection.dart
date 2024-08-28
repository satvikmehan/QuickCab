import 'package:get/get.dart';
import 'package:quick_cab/shared/methods/network.dart';

class DependencyInjection
{
  static void init()
  {
    Get.put<Network>(Network(),permanent:true);
  }
}