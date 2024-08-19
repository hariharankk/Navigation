import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:navigation/Getx/maps.dart'; // Import your LocationController
import 'package:navigation/Widget/timer.dart';
import 'package:navigation/Widget/navigation.dart';
import 'package:navigation/Service/Bloc.dart';
import 'package:navigation/Widget/StartEnd.dart';
import 'package:navigation/Getx/euler.dart';
import 'package:navigation/Getx/timer.dart';
import 'package:navigation/Model/polygon.dart';
import 'package:navigation/shared pref.dart';
import 'package:navigation/Widget/street review.dart';
import 'package:navigation/Widget/marker.dart';
// Usage example

class MapScreen extends StatelessWidget {
  final MapController _mapController = MapController();
  final LocationController _locationController = Get.find<LocationController>(); // Use Get.find instead of Get.put
  final CountdownController _countdownController = Get.find<CountdownController>();
  final EulerCircuit _eulerCircuit = Get.find<EulerCircuit>();
  final StreetreviewController _streetReviewController = Get.find<StreetreviewController>();
  final StartController _startController = Get.find<StartController>();

  Future<void> _handleNoStreamData() async {
    // Check if the start flag is false before proceeding
    if (!_startController.start.value) {
      List<Map<String, dynamic>> retrievedData = await retrieveData();
      if (retrievedData.isNotEmpty) {
        PolygonModel firstPolygon = PolygonModel.fromJson(retrievedData[0]);
        streetBloc.fetchStreetsByPolygon(firstPolygon.polygonId);
        _countdownController.remainingTime.value = Duration(minutes: firstPolygon.timer);
        _countdownController.startTimer();
        _eulerCircuit.setCurrentSegmentIndex(0);
      }
    }
  }

  void _zoomIn() {
    _mapController.move(
        _mapController.camera.center, (_mapController.camera.zoom) + 1);
  }

  void _zoomOut() {
    _mapController.move(
        _mapController.camera.center, (_mapController.camera.zoom) - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Obx(
                () {
              var currentLocation = _locationController.currentLocation.value;
              var currentbearing = _locationController.compassHeading.value;
              var neededstreetid = _streetReviewController.selectedStreetIndex.value;
              var selectedid = _eulerCircuit.currentSegmentIndex.value;
              return StreamBuilder<dynamic>(
                stream: streetBloc.streetDataStream,
                // Replace with your location stream
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData) {
                    _handleNoStreamData();
                    return Center(child: Text('Waiting for location data...'));
                  }
                  // Get the current location from the snapshot
                  var streetsData = snapshot.data!['streets'];
                  var euler = snapshot.data!['eulerCircuit'];
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _streetReviewController.initializeStreets(streetsData);
                  });
                  List<Polyline> polylines =
                  _eulerCircuit.generatePolylinesForCurrentAndNextSegments(
                      euler,
                      streetsData,
                      currentLocation,
                      currentbearing,
                      neededstreetid);

// Create a polyline with the points list
                  // Add the current location marker to the list

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: currentLocation,
                      initialZoom: 13.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      // Replace the direct Marker creation with LocationMarker
                      LocationMarker(currentLocation: currentLocation),
                      PolylineLayer(polylines: polylines),
                    ],
                  );
                },
              );
            },
          ),
          Positioned(
            right: 20.0,
            top: 410.0,
            child: FloatingActionButton(
              onPressed: () {
                var streetsData = streetBloc.getstreetsObject()['streets'];
                var eulerCircuit =
                streetBloc.getstreetsObject()['eulerCircuit'];

                Map<int, List<dynamic>> streetMap = _locationController
                    .createStreetIdToCoordinatesMap(streetsData);
                List<dynamic> fullPath = _locationController
                    .generateFullPathFromEulerCircuit(eulerCircuit, streetMap);

                _locationController.startSimulation(fullPath);

                // When the button is pressed, rotate the map to the current compass heading
              },
              child: Icon(Icons.compass_calibration_rounded),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),

          Positioned(
            top: 100, // Distance from the top of the screen.
            left: 20, // Distance from the left side of the screen.
            child: NavigationInstructionWidget(),
          ),
          Positioned(
            top: 20.0,
            left: 0.0,
            right: 0.0,
            child: Center(child: CountdownTimerWidget()),
          ),
          Positioned(
            right: 20.0,
            top: 310.0,
            child: FloatingActionButton(
              onPressed: () async {
                _locationController.moveToCurrentLocation(_mapController);
              },
              child: Icon(Icons.my_location),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),


          Positioned(
            right: 20.0,
            top: 210.0,
            child: FloatingActionButton(
              onPressed: () {
                // When the button is pressed, rotate the map to the current compass heading
                var targetRotation =
                    _locationController.compassHeading.value % 360;
                _mapController.rotate(targetRotation);
              },
              child: Icon(Icons.compass_calibration_rounded),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
          ),

// Usage in your main widget
//          Positioned(right: 20.0, top: 110.0, child: FlagActionButton()),
          Positioned(right: 20.0, top: 110.0, child: StartActionButton()),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.001,
            // Example position
            top: MediaQuery.of(context).size.height * 0.65,
//            right: MediaQuery.of(context).size.width * 0.005, // Add a right constraint
            bottom: MediaQuery.of(context).size.height * 0.05,
            // Add a bottom constraint to define the height

            child: StreetListView(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          FloatingActionButton(
            onPressed: () => _zoomIn(),
            mini: true,
            child: Icon(Icons.add),
            heroTag: 'zoom-in',
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _zoomOut(),
            mini: true,
            child: Icon(Icons.remove),
            heroTag: 'zoom-out',
          ),
          // Other FABs...
        ],
      ),
    );
  }
}
