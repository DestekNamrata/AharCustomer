import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '/models/pay_stack.dart';
import '/models/razor_pay.dart';
import '/services/paystack_service.dart';
import '/services/razorpay_service.dart';
import '/utils/font_size.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '/Controllers/cart_controller.dart';
import '/Controllers/checkout_controller.dart';
import '/Controllers/global-controller.dart';
import '/services/validators.dart';
import '/utils/theme_colors.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:toggle_switch/toggle_switch.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  var mainHeight, mainWidth;
  final _formKey = GlobalKey<FormState>();
  Validators validators = Validators();
  List<String>? paymentMethod = ["Cash on delivery", "Online payment"];
  List<String>? orderMethod = ["Delivery", "Pickup"];
  List<String> paymentOptions = ["Stripe", "RazorPay", "PayStack"];
  String dropdownValue = 'Stripe';
  int orderPaymentSelect = 0, orderTypeSelect = 0;
  String? city;
  String? latitude;
  String? longitude;
  bool isClicked = true;
  CheckoutController checkoutController = CheckoutController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  final settingController = Get.put(GlobalController());
  RazorPay? razorPay;
  RazorPayService? razorPayService;
  PayStack? payStack;
  PaystackService? payStackService;

  @override
  void initState() {
    checkoutController.onInit();
    final stripesecret = settingController.stripeSecret;
    final stripekey = settingController.stripeKey;
    print(stripekey);
    print(stripesecret);
    Stripe.publishableKey = stripekey!;
    Stripe.instance.applySettings();
    setInitialLocation();
    super.initState();
  }

  Future<Position> _getGeoLocationPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  void setInitialLocation() async {
    Position position = await _getGeoLocationPosition();
    latitude = position.latitude.toString();
    longitude = position.longitude.toString();
    print(position.latitude);
    print(position.longitude);
  }

  Map<String, dynamic>? paymentIntentData;

  @override
  Widget build(BuildContext context) {
    mainHeight = MediaQuery.of(context).size.height;
    mainWidth = MediaQuery.of(context).size.width;
    final cartController = Get.put(CartController());
    final stripesecret = settingController.stripeSecret;
    final currencyName = settingController.currencyName;
    final paystacKey = settingController.paystacKey;
    final razorpayKey = settingController.razorpayKey;
    final razorpaySecret = settingController.razorpaySecret;

    return Scaffold(
      bottomNavigationBar: GetBuilder<CartController>(
        init: CartController(),
        builder: (cert) => Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            height: mainHeight / 4,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          child: Text(
                        'Sub Total',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )),
                      Container(
                          child: Text(
                        "${Get.find<GlobalController>().currency!}" +
                            "${cert.totalCartValue}",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      )),
                    ],
                  ),
                ),
                //SizedBox(height: 5,),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                          child: Text(
                        'Delivery Fee',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      )),
                      Container(
                          child: Text(
                        "${Get.find<GlobalController>().currency!}" +
                            "${cert.deliveryCharge}",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      )),
                    ],
                  ),
                ),
                //SizedBox(height: 5,),

                Divider(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        child: Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                          child: Text(
                        "${Get.find<GlobalController>().currency!}" +
                            "${cert.totalCartValue + cert.deliveryCharge!}",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      )),
                    ],
                  ),
                ), // SizedBox(height: 10,),

                //proceed button
                Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  width: mainWidth,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: ThemeColors.baseThemeColor, // background
                      onPrimary: Colors.white, // foreground
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // <-- Radius
                      ),
                    ),
                    onPressed: isClicked
                        ? () async {
                            setState(() {
                              isClicked = false;
                            });
                            var total =
                                cert.totalCartValue + cert.deliveryCharge!;
                            if (orderPaymentSelect == 0) {
                              checkoutController.postOrder(
                                  phoneController.text.trim(),
                                  addressController.text.trim(),
                                  false,
                                  '1',
                                  latitude,
                                  longitude,
                                  orderTypeSelect,
                                  '5');
                            } else if (orderPaymentSelect == 1) {
                              switch (dropdownValue) {
                                case "Stripe":
                                  await makePayment(
                                      stripesecret!,
                                      currencyName,
                                      total,
                                      checkoutController.name,
                                      orderTypeSelect);
                                  break;

                                case "PayStack":
                                  PaystackService(
                                    context: context,
                                    payStackKey: paystacKey,
                                    email: checkoutController.email,
                                    phoneNumber: checkoutController.phone,
                                    address: checkoutController.address,
                                    latitude: latitude,
                                    longitude: longitude,
                                    orderTypeSelect: orderTypeSelect,
                                    price: total.toInt(),
                                  ).chargeCardAndMakePayment();
                                  break;

                                case "RazorPay":
                                  // calculateAmount(total.toString());
                                  razorPay = RazorPay(
                                      razorpaySecret: razorpaySecret,
                                      razorpayKey: razorpayKey,
                                      email: checkoutController.email,
                                      phone: checkoutController.phone,
                                      description: checkoutController.username,
                                      amount: total.toInt(),
                                      name: checkoutController.name,
                                      latitude: latitude,
                                      longitude: latitude,
                                      orderTypeSelect: orderTypeSelect,
                                      adress: checkoutController.address);
                                  razorPayService = RazorPayService(razorPay);
                                  razorPayService!.init();
                                  razorPayService!.openCheckout();

                                  break;
                              }
                            }
                          }
                        : null,
                    child: Text(
                      'Proceed',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              ],
            )),
      ),
      appBar: AppBar(
        backgroundColor: ThemeColors.baseThemeColor,
        title: Text(
          'Checkout Page',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<CheckoutController>(
          init: CheckoutController(),
          builder: (checkout) => Container(
                height: mainHeight,
                width: mainWidth,
                color: Colors.white,
                padding: EdgeInsets.only(top: 20, left: 20, right: 20),
                child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: phoneController
                              ..text =
                                  checkout.phone == null ? '' : checkout.phone!
                              ..selection = TextSelection.collapsed(
                                  offset: phoneController.text.length),
                            obscureText: false,
                            textAlign: TextAlign.start,
                            keyboardType: TextInputType.phone,
                            style: TextStyle(
                              fontSize: 18,
                              height: 0.8,
                            ),
                            decoration: InputDecoration(
                              hintStyle:
                                  TextStyle(color: Colors.grey, fontSize: 16),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.grey)),
                              hintText: 'Enter your phone number',
                            ),
                            validator: (value) {
                              if (value!.isEmpty) {
                                return 'Enter Your Phone';
                              }
                              return null;
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: checkout.address == null
                                ? TextFormField(
                                    controller: addressController,
                                    obscureText: false,
                                    //initialValue: widget.userdata['name'],
                                    textAlign: TextAlign.start,
                                    keyboardType: TextInputType.text,
                                    style: TextStyle(
                                      fontSize: 18,
                                      height: 0.8,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Enter your address',
                                      hintStyle: TextStyle(
                                          fontSize: 15, color: Colors.grey),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade700),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade700),
                                      ),
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.grey.shade700),
                                      ),
                                    ),
                                    validator: (value) {
                                      checkout.address = value!.trim();
                                    },
                                    onChanged: (value) {
                                      checkout.address = value;
                                    },
                                  )
                                : TextFormField(
                                    textAlign: TextAlign.start,
                                    controller: addressController
                                      ..text = checkout.address!
                                      ..selection = TextSelection.collapsed(
                                          offset:
                                              addressController.text.length),
                                    minLines: 2,
                                    maxLines: 5,
                                    keyboardType: TextInputType.multiline,
                                    decoration: InputDecoration(
                                      hintText: 'Enter your address',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.grey),
                                      ),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.all(
                                              Radius.circular(10))),
                                    ),
                                  ),
                          ),
                          Text('Payment Type',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),
                          _choosePaymentMedthod(),
                          SizedBox(height: 20),

                          //online payment type dropdown

                          (orderPaymentSelect == 1)
                              ?
                              //dropdown online payment type
                              Container(
                                  height: 55,
                                  width: MediaQuery.of(context).size.width * .9,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(3)),
                                    color: Color(0xFFF2F2F2),
                                  ),
                                  child: ButtonTheme(
                                    alignedDropdown: true,
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: dropdownValue,
                                        isExpanded: true,
                                        icon: Icon(Icons.keyboard_arrow_down),
                                        iconEnabledColor:
                                            ThemeColors.baseThemeColor,
                                        items: paymentOptions
                                            .map<DropdownMenuItem<String>>(
                                                (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                        onChanged: (newValue) {
                                          setState(() {
                                            dropdownValue = newValue!;
                                            isClicked = true;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                )
                              : Container(),

                          SizedBox(height: 20),

                          //order summery
                          Text('Order Summery',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          SizedBox(height: 20),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            itemCount: cartController.cart.length,
                            itemBuilder: (context, itemIndex) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: EdgeInsets.only(
                                        left: 15, right: 15, bottom: 2),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 2),
                                    child: ListTile(
                                      leading: CachedNetworkImage(
                                        imageUrl: cartController
                                            .cart[itemIndex].imgUrl!,
                                        imageBuilder: (ctx, imageProvider) =>
                                            Container(
                                          height: mainWidth / 5,
                                          width: mainWidth / 5,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.fill),
                                          ),
                                        ),
                                        placeholder: (context, url) =>
                                            Shimmer.fromColors(
                                          child: Container(
                                            height: mainWidth / 5,
                                            width: mainWidth / 5,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              image: DecorationImage(
                                                image: AssetImage(
                                                    "assets/images/farmhouse.jpg"),
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                          ),
                                          baseColor: Colors.grey[300]!,
                                          highlightColor: Colors.grey[400]!,
                                        ),
                                        errorWidget: (context, url, error) =>
                                            Icon(Icons.error),
                                      ),
                                      title: Text(
                                        "${cartController.cart[itemIndex].name}",
                                        style: TextStyle(
                                          fontSize: FontSize.small2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        "${Get.find<GlobalController>().currencyCode!}${cartController.cart[itemIndex].price} x ${cartController.cart[itemIndex].qty} = ${Get.find<GlobalController>().currencyCode!}${cartController.cart[itemIndex].price! * cartController.cart[itemIndex].qty!}",
                                        style: TextStyle(
                                          overflow: TextOverflow.fade,
                                          fontSize: FontSize.small,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                      trailing: Column(
                                        children: [
                                          Text(
                                            "${Get.find<GlobalController>().currencyCode!}${cartController.cart[itemIndex].price! * cartController.cart[itemIndex].qty!}",
                                            style: TextStyle(
                                              fontSize: FontSize.medium,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    )),
              )),
    );
  }

  _choosePaymentMedthod() => ToggleSwitch(
        minWidth: mainWidth / 2.5,
        cornerRadius: 20.0,
        activeBgColors: [
          [Colors.green],
          [ThemeColors.baseThemeColor]
        ],
        activeFgColor: Colors.white,
        inactiveBgColor: Colors.grey[300],
        inactiveFgColor: Colors.black,
        initialLabelIndex: orderPaymentSelect,
        totalSwitches: 2,
        labels: paymentMethod,
        radiusStyle: true,
        onToggle: (index) {
          setState(() {
            print(index);
            orderPaymentSelect = index!;
          });
          print('switched to: $index');
        },
      );

  Future<void> makePayment(
      stripeSecret, currency, total, customer, orderTypeSelect) async {
    try {
      paymentIntentData =
          await createPaymentIntent(stripeSecret, total.toString(), 'usd');
      await Stripe.instance
          .initPaymentSheet(
              paymentSheetParameters: SetupPaymentSheetParameters(
                  paymentIntentClientSecret:
                      paymentIntentData!['client_secret'],
                  applePay: true,
                  googlePay: true,
                  testEnv: true,
                  style: ThemeMode.dark,
                  merchantCountryCode: 'US',
                  merchantDisplayName: customer))
          .then((value) {});
      displayPaymentSheet();
    } catch (e) {
      print('exception' + e.toString());
    }
  }

  displayPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((newValue) async {
        checkoutController.postOrder(
            phoneController.text.trim(),
            addressController.text.trim(),
            true,
            paymentIntentData!['id'].toString(),
            latitude,
            longitude,
            orderTypeSelect,
            '15');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("paid successfully")));

        paymentIntentData = null;
      }).onError((error, stackTrace) {
        print('Exception/DISPLAYPAYMENTSHEET==> $error $stackTrace');
      });
    } on StripeException {
      showDialog(
          context: context,
          builder: (_) => AlertDialog(
                content: Text("Cancelled "),
              ));
    } catch (e) {
      print('$e');
    }
  }

  createPaymentIntent(stripeSecret, String amount, String currency) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currency,
        'payment_method_types[]': 'card'
      };

      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer ' + stripeSecret,
            'Content-Type': 'application/x-www-form-urlencoded'
          });

      return jsonDecode(response.body);
    } catch (err) {
      print('err charging user: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    print(amount);
    final a = (double.parse(amount).toInt()) * 100;
    return a.toString();
  }
}
