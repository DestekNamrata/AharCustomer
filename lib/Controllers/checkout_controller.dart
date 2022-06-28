import 'dart:convert';
import '/Controllers/cart_controller.dart';
import '/models/cart_model.dart';
import '/models/profile_model.dart';
import '/services/api-list.dart';
import '/services/server.dart';
import '/services/user-service.dart';
import '/views/order_confirmation_page.dart';
import 'package:get/get.dart';

class CheckoutController extends GetxController {
  UserService userService = UserService();
  Server server = Server();

  String? userID;
  int? orderId;

  bool checkoutLoader = true;
  List<Map> items = [];
  List<Map> paymentOptions = [];
  String? name, email, username, phone, address, image, credit;

  //

  @override
  void onInit() {
    getUserProfile();
    super.onInit();
  }

  getUserProfile() {
    server.getRequest(endPoint: APIList.profile).then((response) {
      if (response != null && response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse);
        var profileData = Profile.fromJson(jsonResponse);
        name = profileData.data!.data!.name;
        email = profileData.data!.data!.email;
        address = profileData.data!.data!.address;
        phone = profileData.data!.data!.phone;
        username = profileData.data!.data!.username;
        image = profileData.data!.data!.image;
        credit = profileData.data!.data!.balance;
        Future.delayed(Duration(milliseconds: 10), () {
          update();
        });
      } else {}
    });
  }

  postOrder(phoneNumber, address, payment, paymentID, latitude, longitude,
      orderTypeSelect, paymentTypeID) async {
    Get.find<CartController>().cart.forEach((element) => items.add(ItemProduct(
            restaurantId: Get.find<CartController>().restaurantId,
            menuItemId: element.id,
            unitPrice: element.price,
            discountedPrice: 0.0,
            quantity: element.qty,
            instructions: element.instructions,
            menuItemVariationId: element.variationId,
            options: element.options)
        .toJsonData()));
    print(json.encode(items));
    Map body = {
      "items": json.encode(items),
      "mobile": phoneNumber,
      "address": address,
      "delivery_charge": Get.find<CartController>().charge,
      "order_type": orderTypeSelect == 0 ? 1 : 2,
      "lat": latitude,
      "long": longitude,
      "remarks": 'remarks',
      "total": Get.find<CartController>().totalCartValue,
      "restaurant_id": Get.find<CartController>().restaurantId,
    };
    print(body);
    String jsonBody = json.encode(body);
    print(jsonBody);
    server
        .postRequestWithToken(endPoint: APIList.orders, body: jsonBody)
        .then((response) {
      final jsonResponse = json.decode(response.body);
      print('order =================>');

      print(jsonResponse);
      if (response != null && response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print(jsonResponse);
        orderId = jsonResponse['data']['order_id'];
        if (payment) {
          paymentOrder(orderId, jsonResponse['data']['total_amount'], paymentID,
              paymentTypeID);
        } else {
          Get.off(() => OrderConfirmation(
                orderId: orderId,
                totalAmount: jsonResponse['data']['total_amount'].toString(),
                subTotal: Get.find<CartController>().totalCartValue.toString(),
                deliveryCharge:
                    Get.find<CartController>().deliveryCharge.toString(),
              ));
        }
      } else {
        Get.rawSnackbar(message: 'Please enter valid input');
      }
    });
  }

  paymentOrder(orderID, amount, paymentID, paymentTypeID) async {
    Map body = {
      'order_id': orderID,
      'amount': amount,
      'payment_method': paymentTypeID,
      'payment_transaction_id': paymentID,
    };
    String jsonBody = json.encode(body);
    server
        .postRequestWithToken(endPoint: APIList.ordersPayment, body: jsonBody)
        .then((response) {
      final jsonResponse = json.decode(response.body);
      print('jsonResponse=========>');
      print(jsonResponse);

      if (response != null && response.statusCode == 200) {
        Get.off(() => OrderConfirmation(
              orderId: orderID,
              totalAmount: amount,
              subTotal: Get.find<CartController>().totalCartValue.toString(),
              deliveryCharge:
                  Get.find<CartController>().deliveryCharge.toString(),
            ));
      } else {
        Get.rawSnackbar(message: 'Please enter valid input');
      }
    });
  }
}
