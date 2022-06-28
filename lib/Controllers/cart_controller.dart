import '/models/cart_model.dart';
import 'package:get/get.dart';

class CartController extends GetxController {
  List<OrderMenuItem> cart = [];
  double totalCartValue = 0;
  int totalQunty = 0;
  double? deliveryCharge = 0;
  String restaurantID = '';
  int get total => cart.length;
  double? get charge => deliveryCharge;
  String get restaurantId => restaurantID;
  void addProduct(menuItem, menuItemId, menuItemPrice, instructions, qunty,
      restaurantid, deliverycharge, selecteOptions, selectVaration) {
    deliveryCharge = double.parse(deliverycharge);
    restaurantID = restaurantid.toString();
    int index = cart.indexWhere((i) => i.id == menuItemId);
    if (index != -1)
      updateProduct(menuItemId, menuItemPrice, (cart[index].qty! + qunty));
    else {
      cart.add(OrderMenuItem(
          id: menuItemId,
          instructions: instructions.toString(),
          name: menuItem.menuItemName,
          price: double.parse(menuItemPrice),
          stockCount: 0,
          qty: qunty,
          imgUrl: menuItem.menuItemImage,
          variationId: selectVaration.toString(),
          options: selecteOptions));
      calculateTotal();
      update();
    }
  }

  void removeProduct(product) {
    int index = cart.indexWhere((i) => i.id == product);
    cart[index].qty = 1;
    cart.removeWhere((item) => item.id == product);
    calculateTotal();
    Future.delayed(Duration(milliseconds: 10), () {
      update();
    });
  }

  void updateProduct(productId, price, qty) {
    int index = cart.indexWhere((i) => i.id == productId);
    cart[index].qty = qty;
    cart[index].price = double.parse(price);
    if (cart[index].qty == 0) removeProduct(productId);
    calculateTotal();
    Future.delayed(Duration(milliseconds: 10), () {
      update();
    });
  }

  void clearCart() {
    cart.forEach((f) => f.qty = 1);
    cart = [];
    deliveryCharge = 0;
    totalQunty = 0;
    Future.delayed(Duration(milliseconds: 10), () {
      update();
    });
  }

  void calculateTotal() {
    totalCartValue = 0;
    totalQunty = 0;
    cart.forEach((f) {
      totalCartValue += (f.price!) * f.qty!;
      totalQunty += f.qty!;
    });
    Future.delayed(Duration(milliseconds: 10), () {
      update();
    });
  }
}
