import 'package:navigation/shared pref.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:navigation/Service/Bloc.dart';
import 'package:navigation/Model/polygon.dart';
import 'package:navigation/Getx/timer.dart';
import 'package:navigation/Service/Repository.dart';
import 'package:navigation/Getx/maps.dart';
import 'package:navigation/Utility.dart';

class StartController extends GetxController with WidgetsBindingObserver {
  var start = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadStart();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      saveStart(); // Save the state when the app is backgrounded
    }
  }

  @override
  void onClose() {
    saveStart();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  void toggleStart() {
    start.toggle();
  }

  Future<void> loadStart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    start.value = prefs.getBool('start') ?? true;
  }

  Future<void> saveStart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('start', start.value);
  }
}


class StartActionButton extends StatelessWidget  {
  final StartController _startController = Get.find<StartController>();
  final CountdownController _countdownController = Get.find<CountdownController>();
  final LocationController _locationController = Get.find<LocationController>(); // Use Get.find instead of Get.put



  @override
  Widget build(BuildContext context) {
    _startController.loadStart();

    return Obx(() {
      return Padding(
        padding: const EdgeInsets.only(top: 24.0, bottom: 24),
        child: ElevatedButton.icon(
          onPressed: () async {


            if (_startController.start.value) {
              try {
                List<PolygonModel> varia = await repository.fetchPolygons();
                await storeData(varia.map((polygon) => polygon.toJson()).toList());
                streetBloc.fetchStreetsByPolygon(varia[0].polygonId);
                openMapWithDirections(_locationController.currentLocation.value.latitude, _locationController.currentLocation.value.longitude, varia[0].navigatingCoordinateStart.latitude,varia[0].navigatingCoordinateStart.longitude );
                _countdownController.remainingTime.value = Duration(minutes: varia[0].timer);
                _countdownController.startTimer();
                //_eulerCircuit.setCurrentSegmentIndex(0);
              } catch (e) {
                print(e);
              }
            } else {
              await deleteStoredData();
              _countdownController.remainingTime.value = Duration(minutes: 0);
            }

            // Toggle the start state and save it
            _startController.toggleStart();
            await _startController.saveStart();
          },
          icon: Icon(
              _startController.start.value ? Icons.location_on : Icons.location_off,
              size: 36.0
          ),
          label: Text(
            _startController.start.value ? "Start" : "End",
            style: TextStyle(fontSize: 18.0),
          ),
          style: ElevatedButton.styleFrom(
            primary: Colors.white,
            onPrimary: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      );
    });
  }
}



