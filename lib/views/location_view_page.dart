import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '/Controllers/restaurant_details_controller.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_marker/cached_network_marker.dart';

class LocationViewPage extends StatefulWidget {
  final lat, long;
  LocationViewPage(this.lat, this.long);
  @override
  State<LocationViewPage> createState() => LocationViewPageState();
}

class LocationViewPageState extends State<LocationViewPage> {
  final restaurantDetailsController = Get.put(RestaurantDetailsController());
  Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    print(widget.lat);
    print(widget.long);
    final CameraPosition _kGooglePlex = CameraPosition(
      target: LatLng(double.parse(widget.lat.toString()),
          double.parse(widget.long.toString())),
      zoom: 16,
    );

    var markerPositions = LatLng(double.parse(widget.lat.toString()),
        double.parse(widget.long.toString()));

    const colors = [
      Colors.purple,
      Colors.red,
      Colors.lightBlue,
    ];
    return new Scaffold(
      body: FutureBuilder(
        future: Future.wait(
          List.generate(
            1,
            (index) => CachedNetworkMarker(
              url: restaurantDetailsController.restaurantImage!,
              dpr: MediaQuery.of(context).devicePixelRatio,
            ).circleAvatar(CircleAvatarParams(color: colors[index])),
          ),
        ),
        builder: (context, AsyncSnapshot<List<Uint8List>> snapshot) {
          if (snapshot.hasData) {
            final bytes = snapshot.data;
            final markers = Marker(
              markerId: MarkerId('1'),
              position: markerPositions,
              icon: BitmapDescriptor.fromBytes(bytes![0]),
            );

            return GoogleMap(
              mapType: MapType.normal,
              padding: EdgeInsets.only(bottom: 100),
              initialCameraPosition: _kGooglePlex,
              markers: {markers},
              minMaxZoomPreference: MinMaxZoomPreference(10, 18.6),
              onMapCreated: (GoogleMapController? controller) {
                _controller.complete(controller);
              },
            );
          }

          return GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController? controller) {
              _controller.complete(controller);
            },
          );
        },
      ),
    );
  }
}
