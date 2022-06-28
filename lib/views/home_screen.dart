import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/Controllers/banner_controller.dart';
import '/Controllers/cuisine_controller.dart';
import '/utils/theme_colors.dart';
import '/views/no_restaurants_found.dart';
import '/widgets/shimmer/popular_restaurant_shimmer.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '/views/view_restaurent_page_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '/Controllers/category_Controller.dart';
import '/Controllers/global-controller.dart';
import '/Controllers/popular_restaurant_controller.dart';
import '/views/restaurant_details.dart';
import '/widgets/all_restaurants_heading.dart';
import '/widgets/cuisine_heading.dart';
import '/widgets/custom_slider.dart';
import '/widgets/popular_cuisines.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int activeMenu = 0;
  String? token;
  late String deviceId;

  String? city;

  LocationData? currentLocation;

  final settingController = Get.put(GlobalController());
  final categoriesController = Get.put(CategoryController());
  final popularRestaurantsController = Get.put(PopularRestaurantController());
  final bannerController = Get.put(BannerController());
  final cuisinesController = Get.put(CuisineController());

  Future<Null> _onRefresh() {
    setState(() {
      categoriesController.onInit();
      popularRestaurantsController.onInit();
      bannerController.onInit();
      cuisinesController.onInit();
    });
    Completer<Null> completer = new Completer<Null>();
    Timer(new Duration(seconds: 3), () {
      completer.complete();
    });

    return completer.future;
  }

  var mainHeight, mainWidth;
  bool isSearching = false;

  String page = 'Home';

  @override
  void initState() {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      print('getInitialMessage data: ${message!.data}');
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("onMessage data: ${message.data}");
    });
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('onMessageOpenedApp data: ${message.data}');
      showOverlayNotification(
        (context) {
          return Card(
            semanticContainer: true,
            elevation: 5,
            margin: EdgeInsets.all(10),
            child: SafeArea(
              child: ListTile(
                leading: SizedBox.fromSize(
                  size: const Size(40, 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5.0),
                    child: message.data.isEmpty
                        ? Image.asset(
                            'assets/images/icon.png',
                            height: 35,
                            width: 35,
                          )
                        : Image.network(
                            message.data['iamge'],
                            fit: BoxFit.contain,
                            height: 35,
                            width: 35,
                          ),
                  ),
                ),
                title: Text(message.notification!.title!),
                subtitle: Text(message.notification!.body!),
                trailing: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () {
                      OverlaySupportEntry.of(context)!.dismiss();
                    }),
              ),
            ),
          );
        },
        duration: Duration(milliseconds: 4000),
      );
    });
    FirebaseMessaging.instance.getToken().then((token) {
      update(token!);
    });

    setInitialLocation();
    super.initState();
  }

  update(String token) async {
    SharedPreferences storage = await SharedPreferences.getInstance();
    await storage.setString('deviceToken', token);
    settingController.updateFCMToken(token);
    print(token);
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

  Future<void> getAddressFromLatLong(Position position) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    print(placemarks);
    Placemark place = placemarks[0];
    print(place.name);

    setState(() {
      this.city = place.locality!;
    });
  }

  void setInitialLocation() async {
    Position position = await _getGeoLocationPosition();
    getAddressFromLatLong(position);
  }

  @override
  Widget build(BuildContext context) {
    mainHeight = MediaQuery.of(context).size.height;
    mainWidth = MediaQuery.of(context).size.width;

    return GetBuilder<PopularRestaurantController>(
        init: PopularRestaurantController(),
        builder: (popularRestaurant) => Scaffold(
            appBar: AppBar(
              elevation: 0,
              backgroundColor: ThemeColors.baseThemeColor,
              foregroundColor: Colors.white,
              centerTitle: true,
              title: GetBuilder<GlobalController>(
                init: GlobalController(),
                builder: (homeName) => homeName.customerAppLogo == null
                    ? Text(
                        'Welcome',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      )
                    : Text(
                        '${homeName.siteName}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                        ),
                      ),
              ),
            ),
            backgroundColor: Colors.white,
            body: popularRestaurant.popularRestaurantLoader
                ? PopularRestaurantShimmer()
                : popularRestaurant.bestSellingRestaurantList.isEmpty
                    ? NoRestaurantFound()
                    : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: Container(
                            color: Colors.white10,
                            //height: mainHeight,
                            child: Column(children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(
                                    top: 10, right: 10, bottom: 10, left: 10),
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  color: Colors.grey.shade200,
                                  child: Container(
                                    height: 40,
                                    padding: EdgeInsets.only(left: 14),
                                    child: TextFormField(
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.only(top: 5),
                                        isCollapsed: true,
                                        border: InputBorder.none,
                                        fillColor: Colors.white,
                                        hintText: "Search for Restaurants",
                                        hintStyle: TextStyle(
                                          color: Colors.grey.shade500,
                                        ),
                                        suffixIcon: Icon(
                                          Icons.search,
                                          color: Colors.grey.shade500,
                                        ),
                                      ),
                                      onTap: () {
                                        Get.to(ViewRestaurantPageSearch(
                                            type: activeMenu));
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              bannerController.bannerList.isEmpty
                                  ? Container()
                                  : CustomSliderWidget(),
                              cuisinesController.cuisineList.isEmpty
                                  ? Container()
                                  : Divider(
                                      height: 10,
                                      thickness: 10,
                                    ),
                              cuisinesController.cuisineList.isEmpty
                                  ? Container()
                                  : CuisineHeading(),
                              cuisinesController.cuisineList.isEmpty
                                  ? Container()
                                  : Cuisines(),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Divider(
                                  height: 10,
                                  thickness: 10,
                                ),
                              ),
                              AllRestaurantsHeading(),
                              popularRestaurant
                                      .bestSellingRestaurantList.isEmpty
                                  ? NoRestaurantFound()
                                  : Container(
                                      color: Colors.white10,
                                      child: ListView.builder(
                                          physics:
                                              NeverScrollableScrollPhysics(),
                                          shrinkWrap: true,
                                          itemCount: popularRestaurant
                                              .bestSellingRestaurantList.length,
                                          itemBuilder: (context, index) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 5,
                                                  left: 10,
                                                  right: 10),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Get.to(RestaurantDetails(
                                                    id: popularRestaurant
                                                        .bestSellingRestaurantList[
                                                            index]
                                                        .id,
                                                  ));
                                                },
                                                child: Card(
                                                  //shadowColor: Colors.grey,
                                                  elevation: 1,
                                                  // shadowColor: Colors.blueGrey,
                                                  margin: EdgeInsets.all(2),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.all(
                                                            Radius.circular(2)),
                                                  ),
                                                  child: Column(
                                                    // crossAxisAlignment: CrossAxisAlignment.stretch,

                                                    children: <Widget>[
                                                      CachedNetworkImage(
                                                        imageUrl: popularRestaurant
                                                            .bestSellingRestaurantList[
                                                                index]
                                                            .image!,
                                                        imageBuilder: (context,
                                                                imageProvider) =>
                                                            Container(
                                                          padding:
                                                              EdgeInsets.only(
                                                                  bottom: 15),
                                                          height:
                                                              mainHeight / 4,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white,
                                                            borderRadius: BorderRadius.only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                        2.0),
                                                                topRight: Radius
                                                                    .circular(
                                                                        2.0)),
                                                            image:
                                                                DecorationImage(
                                                              image:
                                                                  imageProvider,
                                                              fit: BoxFit.fill,
                                                              //alignment: Alignment.topCenter,
                                                            ),
                                                          ),
                                                        ),
                                                        placeholder: (context,
                                                                url) =>
                                                            Shimmer.fromColors(
                                                          child: Container(
                                                              height: 130,
                                                              width: mainWidth,
                                                              color:
                                                                  Colors.grey),
                                                          baseColor:
                                                              Colors.grey[300]!,
                                                          highlightColor:
                                                              Colors.grey[400]!,
                                                        ),
                                                        errorWidget: (context,
                                                                url, error) =>
                                                            Icon(Icons.error),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                    .symmetric(
                                                                vertical: 5.0),
                                                        child: ListTile(
                                                          //  leading:CircleAvatar(backgroundImage:AssetImage("assets/images/pizza_hut") ,) ,
                                                          title: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                        .only(
                                                                    bottom: 5),
                                                            child: Text(
                                                              '${popularRestaurant.bestSellingRestaurantList[index].name}',
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),

                                                          subtitle: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                "${popularRestaurant.bestSellingRestaurantList[index].description}",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              SizedBox(
                                                                height: 5,
                                                              ),
                                                              Text(
                                                                "${popularRestaurant.bestSellingRestaurantList[index].address}",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        13),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              SizedBox(
                                                                height: 5,
                                                              ),
                                                              Row(
                                                                children: [
                                                                  RatingBar
                                                                      .builder(
                                                                    itemSize:
                                                                        20,
                                                                    initialRating: popularRestaurant
                                                                        .bestSellingRestaurantList[
                                                                            index]
                                                                        .avgRating!
                                                                        .toDouble(),
                                                                    minRating:
                                                                        1,
                                                                    direction: Axis
                                                                        .horizontal,
                                                                    allowHalfRating:
                                                                        true,
                                                                    itemCount:
                                                                        5,
                                                                    itemBuilder:
                                                                        (context,
                                                                                _) =>
                                                                            Icon(
                                                                      Icons
                                                                          .star,
                                                                      color: ThemeColors
                                                                          .baseThemeColor,
                                                                    ),
                                                                    onRatingUpdate:
                                                                        (rating) {
                                                                      print(
                                                                          rating);
                                                                    },
                                                                  ),
                                                                  Padding(
                                                                    padding: const EdgeInsets
                                                                            .only(
                                                                        left:
                                                                            10.0),
                                                                    child: Text(
                                                                      "(${popularRestaurant.bestSellingRestaurantList[index].avgRatingUser!.toInt()})  reviews",
                                                                      style: TextStyle(
                                                                          color:
                                                                              Colors.grey),
                                                                    ),
                                                                  )
                                                                ],
                                                              )
                                                            ],
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }),
                                    )
                            ]),
                          ),
                        ),
                      )));
  }
}
