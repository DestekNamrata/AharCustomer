import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_google_places_hoc081098/flutter_google_places_hoc081098.dart';
import 'package:food_ex/Controllers/address_controller.dart';
import 'package:food_ex/theme/map_dark_theme.dart';
import 'package:food_ex/theme/map_light_theme.dart';
import 'package:food_ex/views/checkout_page.dart';
import 'package:food_ex/widgets/location_search.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:google_place/google_place.dart' as GooglePlace;

class SearchAddressLocation extends StatefulWidget {
  _SearchAddressLocationState createState() => _SearchAddressLocationState();
}

class _SearchAddressLocationState extends State<SearchAddressLocation> {
  final AddressController controller = Get.put(AddressController());

  Map<MarkerId, Marker> markers = {};
  BitmapDescriptor? pinLocationIcon;
  GoogleMapController? mapController; //contrller for Google map
  bool clickPredictions = false;
  LatLng startLocation = LatLng(21.185440050385917, 79.06569532337792);
  // String location = "Search Location";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //initialization of map
    controller.mapController = Completer();
    controller.currentLocation();
    
  }
  // void _updatePosition(CameraPosition _position) {
  //   Position newMarkerPosition = Position(
  //       latitude: _position.target.latitude,
  //       longitude: _position.target.longitude, accuracy: null,);
  //   Marker marker = markers["1"];
  //
  //   setState(() {
  //     markers["1"] = marker.copyWith(
  //         positionParam: LatLng(newMarkerPosition.latitude, newMarkerPosition.longitude));
  //   });
  // }

  @override
  void dispose() {
    super.dispose();
    // controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      appBar: AppBar(
        title: Text("Search Address"),
      ),
      body: Obx(() => Container(
            child: Stack(
              children: [
                Container(
                  child:
                  GoogleMap(
                    mapType: MapType.normal,
                    onTap: (LatLng data) {
                      controller.moveToCoords(data.latitude, data.longitude);
                      controller.getPlaceName(data.latitude, data.longitude);
                    },
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    // markers:Set<Marker>.of(markers.values) ,
                    // ignore: invalid_use_of_protected_member
                    // markers: Set<Marker>.of(controller.markers.value.values),
                    markers: Set<Marker>.of(
                      <Marker>[
                        Marker(
                          draggable: true,
                          markerId: MarkerId("1"),
                          position: LatLng(controller.latitude.value, controller.longitude.value),
                          icon: BitmapDescriptor.defaultMarker,
                          infoWindow: const InfoWindow(
                            title: 'AHAR Customer',
                          ),
                      onDragEnd: ((newPosition) {
                        controller.updateNewPosition(newPosition);
                        // controller.latitude.value=newPosition.latitude;
                        // controller.longitude.value=newPosition.longitude;
                        print(newPosition.latitude);
                        print(newPosition.longitude);
                      }),
                        )
                      ],
                    ),
                    padding: EdgeInsets.only(top: 600, right: 0),
                    zoomControlsEnabled: false,
                    // initialCameraPosition: _kGooglePlex,
                    initialCameraPosition: CameraPosition(
                      target: LatLng(controller.latitude.value,
                          controller.longitude.value),
                      zoom: 12,
                    ),
                    // onCameraMove: ((_position) => _updatePosition(_position)),
                    onMapCreated: (GoogleMapController mapcontroller) {
                      mapcontroller.setMapStyle(json.encode(
                          Get.isDarkMode ? MAP_DARK_THEME : MAP_LIGHT_THEME));
                      if (!controller.mapController!.isCompleted)
                        controller.mapController!.complete(mapcontroller);
                      mapController=mapcontroller;

                    },
                  ),
                ),
                // if(controller.markers.value.values.isEmpty)
                //   Center(
                //     child: SizedBox(
                //       height: 20.0,
                //       width: 20.0,
                //       child: CircularProgressIndicator(),
                //       // padding: EdgeInsets.symmetric(
                //       //     horizontal: 15, vertical: 10),
                //       // child: loading(),
                //     ),
                //   ),

                // Positioned(
                //     top: 20,
                //     left: 10,
                //     right: 25,
                //     child: Column(
                //       children: [
                //         Column(
                //           children: <Widget>[
                //             Container(
                //               margin: const EdgeInsets.only(left: 5),
                //               width: MediaQuery.of(context).size.width,
                //               decoration: BoxDecoration(
                //                   boxShadow: const <BoxShadow>[
                //                     BoxShadow(
                //                         color:
                //                             Color.fromRGBO(169, 169, 150, 0.13),
                //                         offset: Offset(0, 2),
                //                         blurRadius: 2,
                //                         spreadRadius: 0)
                //                   ],
                //                   color: Get.isDarkMode
                //                       ? Color.fromRGBO(37, 48, 63, 1)
                //                       : Colors.white,
                //                   borderRadius: BorderRadius.circular(25)),
                //               child: TextField(
                //                 controller: TextEditingController(
                //                     text: controller.searchText.value)
                //                   ..selection = TextSelection.fromPosition(
                //                     TextPosition(
                //                         offset:
                //                             controller.searchText.value.length),
                //                   ),
                //                 textAlignVertical: TextAlignVertical.center,
                //                 onChanged: (text) {
                //                   controller.onChangeAddressSearchText(text);
                //                 },
                //                 style: TextStyle(
                //                     fontFamily: 'Inter',
                //                     fontWeight: FontWeight.w500,
                //                     fontSize: 16.0,
                //                     letterSpacing: -0.4,
                //                     color: Get.isDarkMode
                //                         ? Colors.white
                //                         : Colors.black),
                //                 decoration: InputDecoration(
                //                   border: InputBorder.none,
                //                   prefixIcon: IconButton(
                //                     onPressed: () {},
                //                     icon: Icon(Icons.search,
                //                       // const IconData(0xf0d1,
                //                       //     fontFamily: 'MIcon'),
                //                       size: 22.0,
                //                       color: Get.isDarkMode
                //                           ? Colors.white
                //                           : Colors.black,
                //                     ),
                //                   ),
                //                   suffixIcon: IconButton(
                //                     onPressed: () => controller
                //                         .onChangeAddressSearchText(""),
                //                     icon: Icon(Icons.clear,
                //                       // const IconData(0xeb99,
                //                       //     fontFamily: 'MIcon'),
                //                       size: 22.0,
                //                       color: Get.isDarkMode
                //                           ? Colors.white
                //                           : Colors.black,
                //                     ),
                //                   ),
                //                 ),
                //               ),
                //             ),
                //
                //             if (controller.isSearch.value)
                //               Container(
                //                 margin: const EdgeInsets.only(top: 5),
                //                 padding: const EdgeInsets.symmetric(
                //                     vertical: 10, horizontal: 20),
                //                 decoration: BoxDecoration(
                //                     boxShadow: const <BoxShadow>[
                //                       BoxShadow(
                //                           color: Color.fromRGBO(
                //                               169, 169, 150, 0.13),
                //                           offset: Offset(0, 2),
                //                           blurRadius: 2,
                //                           spreadRadius: 0)
                //                     ],
                //                     color: Get.isDarkMode
                //                         ? Color.fromRGBO(37, 48, 63, 1)
                //                         : Colors.white,
                //                     borderRadius: BorderRadius.circular(15)),
                //                 child: Column(
                //                   children:
                //                       controller.predictions.map((element) {
                //                     int index =
                //                         controller.predictions.indexOf(element);
                //                     GooglePlace.AutocompletePrediction
                //                         prediction = element;
                //
                //                     return LocationSearchItem(
                //                       mainText: prediction
                //                           .structuredFormatting!.mainText,
                //                       address: prediction
                //                           .structuredFormatting!.secondaryText,
                //                       onClickRaw: (text) => controller
                //                           .getLatLngFromName(text)
                //                           .then((value) {}),
                //                       onClickIcon: (text) =>
                //                           controller.onChangeSearchText(text),
                //                       isLast: index ==
                //                           (controller.predictions.length - 1),
                //                     );
                //                   }).toList(),
                //                 ),
                //               )
                //           ],
                //         )
                //       ],
                //     ))

                //updated on 5/07/2022
                //search autocomplete input
                Positioned(  //search input bar
                    top:10,
                    child: InkWell(
                        onTap: () async {
                          var place = await PlacesAutocomplete.show(
                              context: context,
                              apiKey: controller.googlePlace.apiKEY.obs.value,
                              mode: Mode.overlay,
                              types: [],
                              strictbounds: false,
                              components: [Component(Component.country, 'in')],
                              //google_map_webservice package
                              onError: (err){
                                print(err);
                              }
                          );

                          if(place != null){
                            // setState(() {
                              controller.location = place.description.toString();
                            // });

                              //form google_maps_webservice package
                            final plist = GoogleMapsPlaces(apiKey:controller.googlePlace.apiKEY.obs.value,
                              // apiHeaders: await GoogleApiHeaders().getHeaders(),
                              apiHeaders: null,
                              //from google_api_headers package
                            );
                            String placeid = place.placeId ?? "0";
                            final detail = await plist.getDetailsByPlaceId(placeid);
                            final geometry = detail.result.geometry!;
                            final lat = geometry.location.lat;
                            final lang = geometry.location.lng;

                            // setState(() {
                            //   startLocation = LatLng(lat, lang);
                            // });
                              setState(() {

                              });
                            var newlatlang = LatLng(lat, lang);
                            controller.latitude.value=lat;
                            controller.longitude.value=lang;

                            //move map camera to selected place with animation
                           mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: newlatlang, zoom: 20)));
                          }
                        },
                        child:Padding(
                          padding: EdgeInsets.all(15),
                          child: Card(
                            child: Container(
                                padding: EdgeInsets.all(0),
                                width: MediaQuery.of(context).size.width - 40,
                                child: ListTile(
                                  title:Text(controller.location, style: TextStyle(fontSize: 18),),
                                  trailing: Icon(Icons.search),
                                  dense: true,
                                )
                            ),
                          ),
                        )
                    )
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: EdgeInsets.all(10.0),
                    child:
                    TextButton(
                        style: ButtonStyle(
                            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                                EdgeInsets.all(0))),
                        child: Container(
                          // width: 1.sw - 30,
                          width:200.0,
                          height: 50,
                          alignment: Alignment.center,
                          child:
                          Text("Add Address",
                            style:TextStyle(
                              fontSize:16.0,fontWeight: FontWeight.w600,color: Colors.white),),
                          decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: () {
                          SystemChannels.textInput.invokeMethod('TextInput.hide');
                          Navigator.pop(context,{'address':controller.location.obs.value,
                          'lat':controller.latitude.value.toString(),'long':controller.longitude.value.toString()});
                          // Get.off(()=>CheckoutPage(address:controller.location.obs.value,
                          // lat:controller.latitude.value.toString(),long:controller.longitude.value.toString()));

                        }),
                  ),
                )
              ],
            ),
          )),
    );
  }
}
