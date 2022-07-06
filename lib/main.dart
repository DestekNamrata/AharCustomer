import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/widgets/authentication.dart';
import 'package:get/get.dart';
import 'Controllers/global-controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(FoodEx());
}

class FoodEx extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    Get.put(GlobalController()).onInit();
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AHAR',
      theme: ThemeData(),
      home: Authentication(),
    );
  }
}
