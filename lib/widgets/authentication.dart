import 'dart:async';
import 'package:flutter/material.dart';
import '/Controllers/auth-controller.dart';
import '/services/user-service.dart';
import '/utils/image.dart';
import '/utils/theme_colors.dart';
import '/views/sign_In.dart';
import 'package:get/get.dart';

class Authentication extends StatefulWidget {
  Authentication({Key? key}) : super(key: key);

  @override
  State<Authentication> createState() => _AuthenticationState();
}

class _AuthenticationState extends State<Authentication> {
  UserService userService = UserService();

  AuthController _authController = AuthController();
  var mainHeight, mainWidth;

  @override
  void initState() {
    Timer(
      Duration(seconds: 5),
      () => {
        logInCheck(),
      },
    );
    super.initState();
  }

  logInCheck() async {
    var isUser = await userService.getBool();
    if (isUser == false) {
      await _authController.refreshToken();
    } else {
      Get.off(() => LoginPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    mainHeight = MediaQuery.of(context).size.height;
    mainWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        height: mainHeight,
        width: mainWidth,
        color: ThemeColors.baseThemeColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(Images.appLogo, height: 230, width: 230),
              SizedBox(height: 10),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
