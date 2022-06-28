import 'package:flutter/material.dart';
import '/Controllers/cart_controller.dart';
import '/Controllers/restaurant_details_controller.dart';
import '/utils/theme_colors.dart';
import '/views/cart.dart';
import '/widgets/description_container.dart';
import '/widgets/img_container_res_details.dart';
import '/widgets/tab_bar.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'book_table.dart';

class RestaurantDetails extends StatefulWidget {
  final int? id;

  RestaurantDetails({required this.id});

  @override
  State<StatefulWidget> createState() => _RestaurantDetailsState();
}

class _RestaurantDetailsState extends State<RestaurantDetails> {
  var mainHeight, mainWidth;
  final restaurantDetailsController = Get.put(RestaurantDetailsController());
  final cartController = Get.put(CartController());

  Future<Null> _refresh() async {
    restaurantDetailsController.getRestaurant(widget.id!);
    await Future.delayed(new Duration(seconds: 3));
  }

  @override
  void initState() {
    restaurantDetailsController.getRestaurant(widget.id!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    mainHeight = MediaQuery.of(context).size.height;
    mainWidth = MediaQuery.of(context).size.width;

    return GetBuilder<RestaurantDetailsController>(
        init: RestaurantDetailsController(),
        builder: (restaurant) => RefreshIndicator(
              onRefresh: _refresh,
              child: Scaffold(
                floatingActionButton: Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: GetBuilder<CartController>(
                            init: CartController(),
                            builder: (cart) => Stack(children: [
                              SizedBox(
                                  height: 45,
                                  width: 45,
                                  child: FittedBox(
                                      child: FloatingActionButton(
                                    onPressed: () {
                                      Get.to(() => CartPage());
                                    },
                                    child: Icon(
                                      Icons.shopping_cart,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                    backgroundColor: ThemeColors.baseThemeColor,
                                  ))),
                              new Positioned(
                                  child: new Stack(
                                children: <Widget>[
                                  new Icon(Icons.brightness_1,
                                      size: 20.0, color: Colors.orange),
                                  new Positioned(
                                      top: 4.0,
                                      right: 5.5,
                                      child: new Center(
                                        child: new Text(
                                          cart.totalQunty.toString(),
                                          style: new TextStyle(
                                              color: Colors.white,
                                              fontSize: 11.0,
                                              fontWeight: FontWeight.w900),
                                        ),
                                      )),
                                ],
                              )),
                            ]),
                          )),
                    ),
                    restaurant.tableStatus == 5
                        ? Align(
                            alignment: Alignment.bottomRight,
                            child: FloatingActionButton.extended(
                              heroTag: 'btn2',
                              backgroundColor: ThemeColors.baseThemeColor,
                              onPressed: () {
                                Get.to(
                                  () => BookTable(
                                    restaurantId: widget.id!,
                                  ),
                                );
                              },
                              icon: Icon(
                                Icons.library_books_outlined,
                                color: Colors.white,
                              ),
                              label: Text("Book table"),
                            ),
                          )
                        : SizedBox(
                            height: 0,
                          ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60, left: 20),
                        child: SizedBox(
                          height: 45,
                          width: 45,
                          child: FittedBox(
                            child: FloatingActionButton(
                              elevation: 5,
                              backgroundColor: ThemeColors.baseThemeColor,
                              onPressed: () {
                                Get.back();
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 5),
                                child: Icon(
                                  Icons.arrow_back_ios,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        height: 32,
                        width: mainWidth,
                        color: ThemeColors.baseThemeColor,
                      ),
                      //Image_container
                      Container(
                        height: mainHeight / 4,
                        width: mainWidth,
                        child: restaurant.restaurantDetailsLoader
                            ? Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[400]!,
                                child: Container(
                                  padding: EdgeInsets.only(bottom: 15),
                                  height: mainHeight / 3.5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(2.0),
                                        topRight: Radius.circular(2.0)),
                                    image: DecorationImage(
                                      image: AssetImage(
                                          "assets/images/farmhouse.jpg"),
                                      fit: BoxFit.fill,
                                    ),
                                  ),
                                ),
                              )
                            : ImageContainer(img: restaurant.restaurantImage),
                      ),
                      //description container
                      DescriptionContainer(),
                      TabBarDemo(),
                    ],
                  ),
                ),
              ),
            ));
  }
}
