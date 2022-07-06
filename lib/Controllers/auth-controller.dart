import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:food_ex/views/verify_phone.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/refresh_token.dart';
import '/models/reg_api.dart';
import '/models/login_api.dart';
import '/screens/main_screen.dart';
import '/services/api-list.dart';
import '/services/server.dart';
import '/services/user-service.dart';
import '/services/validators.dart';
import 'package:get/get.dart';

import 'global-controller.dart';

class AuthController extends GetxController {
  UserService userService = UserService();
  Validators _validators = Validators();
  Server server = Server();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordConfirmationController =
      TextEditingController();
  bool obscureText = true;
  bool loader = false;
  var code = "".obs;

  GoogleSignIn _googleSignIn = GoogleSignIn();
  late GoogleSignInAccount _userObj;
  var verificationId = "";
  StreamController<ErrorAnimationType>? errorController;

  @override
  void dispose() {
    errorController?.close();
    super.dispose();
  }

  void onChangeSmsCode(String text) {
    code.value = text;
  }

  changeVisibility() {
    obscureText = !obscureText;
    Future.delayed(Duration(milliseconds: 10), () {
      update();
    });
  }


  loginOnTap({BuildContext? context, String? email, String? pass}) async {
  // loginOnTap({BuildContext? context, String? phone}) async {
    print('email');
    loader = true;
    Future.delayed(Duration(milliseconds: 10), () {
      update();
    });
    var emailValidator = _validators.validateEmail(value: email);
    var passValidator = _validators.validatePassword(value: pass);
    // var phoneValidator = _validators.validatePhone(value: phone);
    if (emailValidator == null && passValidator == null) {
    // if (phoneValidator == null) {
      Map body = {'email': email, 'password': pass};
      // Map body = {'mobile': phone};
      String jsonBody = json.encode(body);
      server
          .postRequest(endPoint: APIList.login, body: jsonBody)
          .then((response) {
        if (response != null && response.statusCode == 200) {
          updateFcmSubscribe(email);
          final jsonResponse = json.decode(response.body);
          var loginData = LoginApi.fromJson(jsonResponse);
          var bearerToken = 'Bearer ' + "${loginData.token}";
          userService.saveBoolean(key: 'is-user', value: true);
          userService.saveString(key: 'token', value: loginData.token);
          userService.saveString(
              key: 'user-id', value: loginData.data!.id.toString());
          userService.saveString(
              key: 'email', value: loginData.data!.email.toString());
          userService.saveString(
              key: 'username', value: loginData.data!.username.toString());
          userService.saveString(
              key: 'image', value: loginData.data!.image.toString());
          userService.saveString(
              key: 'name', value: loginData.data!.name.toString());
          userService.saveString(
              key: 'phone', value: loginData.data!.phone.toString());
          userService.saveString(
              key: 'status', value: loginData.data!.status.toString());
          Server.initClass(token: bearerToken);
          Get.put(GlobalController()).initController();
          emailController.clear();
          passwordController.clear();
          loader = false;
          Future.delayed(Duration(milliseconds: 10), () {
            update();
          });
          Get.off(() => MainScreen());
        } else {
          loader = false;
          Future.delayed(Duration(milliseconds: 10), () {
            update();
          });
          Get.rawSnackbar(
              message: 'Please enter valid email address and password');
        }
      });
    } else {
      loader = false;
      Future.delayed(Duration(milliseconds: 10), () {
        update();
      });
      Get.rawSnackbar(message: 'Please enter phone number');
    }
  }

  //firebase verification of phone number
  VerifyWithPhone({BuildContext? context,String? phone}) async {
    loader = true;
    var phoneValidator = _validators.validatePhone(value: phone);

    try {
      if (phoneValidator == null) {
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: "+91${phone}",
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            loader = false;
            if (e.code == 'invalid-phone-number') {
              // Get.bottomSheet(ErrorAlert(
              //   message: "Phone number is not valid".tr,
              //   onClose: () {
              //     Get.back();
              //   },
              // ));
              Fluttertoast.showToast(msg: "Phone number is not valid".tr);
            }
          },
          codeSent: (String vId, int? resendToken) {
            loader = false;
            verificationId = vId;
            // Get.toNamed("/verifyPhone",
            //     arguments: {
            //       "phone": phone,
            //       "flagVerify": "0"
            //     });

            Get.to(() => VerifyPhonePage(flagVerify: "0", phone: phone));
            //from signIn
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );
      }else{
        loader = false;
        Future.delayed(Duration(milliseconds: 10), () {
          update();
        });
        Get.rawSnackbar(message: 'Please enter phone number');
      }
    }catch(e){
      print(e);
    }
  }

  //for signup
  VerifyWithPhoneSignUp({BuildContext? context,String? phone,String? email,String? name,String? userName,
    String? password,String? cnfPass}) async {
    loader = true;
    var email_validator = _validators.validateEmail(value: email);
    var pass_validator = _validators.validatePassword(value: password);
    var phone_validator = _validators.validatePhone(value: phone);

    try {
      if(email_validator!=null){
        loader = false;
        Future.delayed(Duration(milliseconds: 10), () {
          update();
        });
        Get.rawSnackbar(message: 'Please enter valid email id');
      }
      else if(phone_validator!=null){
        loader = false;
        Future.delayed(Duration(milliseconds: 10), () {
          update();
        });
        Get.rawSnackbar(message: 'Please enter valid Phone Number');
      }
      else if(pass_validator!=null){
        loader = false;
        Future.delayed(Duration(milliseconds: 10), () {
          update();
        });
        Get.rawSnackbar(message: 'Please enter Password');
      }else{
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: "+91${phone}",
          verificationCompleted: (PhoneAuthCredential credential) {},
          verificationFailed: (FirebaseAuthException e) {
            loader = false;
            if (e.code == 'invalid-phone-number') {
              // Get.bottomSheet(ErrorAlert(
              //   message: "Phone number is not valid".tr,
              //   onClose: () {
              //     Get.back();
              //   },
              // ));
              Fluttertoast.showToast(msg: "Phone number is not valid".tr);
            }
          },
          codeSent: (String vId, int? resendToken) {
            loader = false;
            verificationId = vId;
            // Get.toNamed("/verifyPhone",
            //     arguments: {
            //       "phone": phone,
            //       "flagVerify": "0"
            //     });

            Get.to(() => VerifyPhonePage(flagVerify: "1", phone: phone,
              email: email,
              password: password,
              name: name,
              userName: userName,
              cnfPass: cnfPass,));
            //from signIn
          },
          codeAutoRetrievalTimeout: (String verificationId) {},
        );

      }

    }catch(e){
      print(e);
    }

  }

  refreshToken() async {
    server.getRequest(endPoint: APIList.refreshToken).then((response) {
      print(response);
      if (response != null && response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        var refreshData = RefreshToken.fromJson(jsonResponse);
        print(refreshData);
        var newToken = 'Bearer ' + "${refreshData.token}";
        userService.saveBoolean(key: 'is-user', value: true);
        userService.saveString(key: 'token', value: refreshData.token);
        Server.initClass(token: newToken);
        Get.put(GlobalController()).initController();
        Get.off(() => MainScreen());
        return true;
      } else {
        return false;
      }
    });
  }

  signupOnTap(
      {BuildContext? context,
      String? email,
      String? password,
      String? confirmPassword,
      String? phoneNumber,
      String? name}) async {
    loader = true;
    Future.delayed(Duration(milliseconds: 10), () {
      update();
    });
    var emailValidator = _validators.validateEmail(value: email);
    var passValidator = _validators.validatePassword(value: password);
    if (emailValidator == null && passValidator == null) {
      var fcmToken=FirebaseMessaging.instance.getToken();
      Map body = {
        'name': nameController.text,
        'username': usernameController.text,
        'email': email,
        'phone': phoneNumber,
        'password': password,
        'password_confirmation': confirmPassword,
        'role': 2,
        'device_token':fcmToken.toString()
      };
      String jsonBody = json.encode(body);
      server
          .postRequest(endPoint: APIList.register, body: jsonBody)
          .then((response) {
        if (response != null && response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          var regData = RegApi.fromJson(jsonResponse);
          var bearerToken = 'Bearer ' + "${regData.token}";
          Get.off(() => MainScreen());
          userService.saveBoolean(key: 'is-user', value: true);
          userService.saveString(key: 'token', value: regData.token);
          userService.saveString(
              key: 'user-id', value: regData.data!.id.toString());
          userService.saveString(
              key: 'email', value: regData.data!.email.toString());
          userService.saveString(
              key: 'username', value: regData.data!.username.toString());
          userService.saveString(
              key: 'image', value: regData.data!.image.toString());
          userService.saveString(
              key: 'name', value: regData.data!.name.toString());
          userService.saveString(
              key: 'phone', value: regData.data!.phone.toString());
          userService.saveString(
              key: 'status', value: regData.data!.status.toString());
          Server.initClass(token: bearerToken);
          Get.put(GlobalController()).initController();
          emailController.clear();
          passwordController.clear();
          nameController.clear();
          usernameController.clear();
          phoneController.clear();
          loader = false;
          Future.delayed(Duration(milliseconds: 10), () {
            update();
          });
          Get.off(() => MainScreen());
        } else {
          loader = false;
          Future.delayed(Duration(milliseconds: 10), () {
            update();
          });
          Get.rawSnackbar(message: 'Please enter valid input');
        }
      });
    }
  }

  updateFcmSubscribe(email) async {
    SharedPreferences storage = await SharedPreferences.getInstance();
    var deviceToken = storage.getString('deviceToken');
    Map body = {
      "device_token": deviceToken,
      "topic": email,
    };
    String jsonBody = json.encode(body);
    server
        .postRequest(endPoint: APIList.fcmSubscribe, body: jsonBody)
        .then((response) {
      if (response != null && response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('responseBody===========>');
        print(jsonResponse);
      }
    });
  }

  loginFB() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
          permissions: [
            'public_profile',
            'email'
          ]); // by default we request the email and the public profile

      if (result.status == LoginStatus.success) {
        // you are logged
        final AccessToken accessToken = result.accessToken!;
        final userData = await FacebookAuth.i.getUserData();
        print(userData);
        socialLogin(userData['name'].toString(), userData['email'].toString(),
            'facebook', userData['id']);
        print(userData['name']);
      }
    } catch (e) {
      print(e);
    }
  }

  loginGoogle() async {
    try {
      _userObj = (await _googleSignIn.signIn())!;
      print(_userObj);
      socialLogin(_userObj.displayName?.toString(), _userObj.email.toString(),
          'google', _userObj.id.toString());
    } catch (e) {
      print(e);
    }
  }

  socialLogin(String? name, String? email, String? provider, providerID) async {
    Map body = {
      'name': name,
      'email': email,
      'provider': provider,
      'provider_id': providerID,
      'role': 2
    };
    String jsonBody = json.encode(body);
    server
        .postRequest(endPoint: APIList.socialLogin, body: jsonBody)
        .then((response) {
      final jsonResponse = json.decode(response.body);
      print(jsonResponse);
      if (response != null && response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        var regData = RegApi.fromJson(jsonResponse);
        var bearerToken = 'Bearer ' + "${regData.token}";
        userService.saveBoolean(key: 'is-user', value: true);
        userService.saveString(key: 'token', value: regData.token);
        userService.saveString(
            key: 'user-id', value: regData.data!.id.toString());
        userService.saveString(
            key: 'email', value: regData.data!.email.toString());
        updateFcmSubscribe(regData.data!.email.toString());

        userService.saveString(
            key: 'username', value: regData.data!.username.toString());
        userService.saveString(
            key: 'image', value: regData.data!.image.toString());
        userService.saveString(
            key: 'name', value: regData.data!.name.toString());
        userService.saveString(
            key: 'phone', value: regData.data!.phone.toString());
        userService.saveString(
            key: 'status', value: regData.data!.status.toString());
        Server.initClass(token: bearerToken);
        Get.put(GlobalController()).initController();
        Get.off(() => MainScreen());
      }

      else {
        Get.rawSnackbar(message: 'Please enter valid input');
      }
    });
  }
}
