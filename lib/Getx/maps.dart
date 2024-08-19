import 'package:get/get.dart';
import 'package:location/location.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'dart:async';


class LocationController extends GetxController {

  var currentLocation = Rx<LatLng>(LatLng(9.901297733498891 , 78.0111798216437));
  var currentHeading = Rx<double>(0.0);
  Location location = new Location();
  var compassHeading = 0.0.obs; // Observable for compass heading
  bool isSimulationActive = false;

  @override
  void onInit() {
    super.onInit();
    _getLocation();
    _listenToCompass();
  }
  // Inside your LocationController class

  void moveToCurrentLocation(MapController mapController) {
    final currentLoc = currentLocation.value;
    mapController.move(currentLoc, mapController.zoom);
  }

  void _listenToCompass() {
    if (FlutterCompass.events != null) {
      FlutterCompass.events!.listen((CompassEvent event) {
        compassHeading.value = event.heading ?? 0.0; // Also, handle a potential null heading
      });
    } else {
      // Handle the situation when the compass is not available or permissions are not granted
    }
  }



  // Get current location and listen for changes
  void _getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) return;
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) return;
    }

    location.onLocationChanged.listen((LocationData currentLocationData) {
      if (!isSimulationActive) {
        currentLocation.value = LatLng(
          currentLocationData.latitude ?? 0.0,
          currentLocationData.longitude ?? 0.0,
        );

        if (currentLocationData.speed != null && currentLocationData.speed! > 0) {
          // Use GPS heading if the device is moving
          currentHeading.value = currentLocationData.heading ?? compassHeading.value;
        } else {
          // Use compass heading if the device is stationary
          currentHeading.value = compassHeading.value;
        }
      }
    });
  }

  Map<int, List<LatLng>> createStreetIdToCoordinatesMap(dynamic streetsData) {
    Map<int, List<LatLng>> streetMap = {};

    for (var street in streetsData) {
      int streetId = street.streetId; // Assuming streetId is a non-nullable integer
      List<LatLng> coordinates = (street.streetCoordinates as List).map((coord) {
        return LatLng(coord.latitude, coord.longitude);
      }).toList();

      streetMap[streetId] = coordinates;
    }
    return streetMap;
  }

  List<dynamic> generateFullPathFromEulerCircuit(dynamic eulerCircuit, Map<int, List<dynamic>> streetMap) {
    List<dynamic> fullPath = [];

    for (var segment in eulerCircuit) {
      // Assuming each segment's third element contains the street ID
      if (segment.length > 2 && segment[2] is Map && segment[2].containsKey('id')) {
        int streetId = segment[2]['id'];
        // Check if streetMap contains streetId and it's not null before adding
        if (streetMap.containsKey(streetId) && streetMap[streetId] != null) {
          fullPath.addAll(streetMap[streetId]!);
        }
      }
    }

    // Ensure continuity between segments by reversing as needed
    List<LatLng> optimizedPath = [];
    for (int i = 0; i < fullPath.length - 1; i++) {
      LatLng currentPoint = fullPath[i];
      LatLng nextPoint = fullPath[i + 1];
      optimizedPath.add(currentPoint);
      if (i == fullPath.length - 2) {
        optimizedPath.add(nextPoint);
      }
    }
    return optimizedPath;
  }


  void startSimulation(List<dynamic> fullPath) {
    isSimulationActive = true; // Enable simulation
    const speed = Duration(milliseconds: 500);
    int currentIndex = 0;
    Timer.periodic(speed, (Timer timer) {
      if (currentIndex < fullPath.length) {
        currentLocation.value = fullPath[currentIndex];
        currentIndex++;
      } else {
        timer.cancel();
        isSimulationActive = false; // Disable simulation at the end
      }
    });
  }

}
