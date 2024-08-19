import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart'; // Import GetX
import 'package:navigation/shared pref.dart';
import 'package:navigation/Service/Bloc.dart';
import 'package:navigation/Model/polygon.dart';
import 'package:navigation/Getx/euler.dart';
import 'dart:math';
import 'package:navigation/Getx/maps.dart';
import 'package:navigation/Utility.dart';
import 'package:navigation/Widget/StartEnd.dart';
import 'package:navigation/Widget/StartEnd.dart';

class CountdownController extends GetxController with WidgetsBindingObserver {
  Rx<Duration> remainingTime = Duration(minutes: 0).obs;
  Timer? _timer;
  final EulerCircuit _eulerCircuit = Get.find<EulerCircuit>();
  final StartController _startController = Get.find<StartController>();
  final LocationController _locationController = Get.find<LocationController>(); // Use Get.find instead of Get.put
  DateTime? lastPausedTime;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      lastPausedTime = DateTime.now();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (lastPausedTime != null) {
        var elapsedTime = DateTime.now().difference(lastPausedTime!).inSeconds;
        remainingTime.value = Duration(seconds: max(0, remainingTime.value.inSeconds - elapsedTime));
      }
      startTimer();
    }
  }

  void startTimer() {
    _timer?.cancel(); // Cancel any existing timer
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (remainingTime.value.inSeconds > 0) {
        remainingTime.value = remainingTime.value - Duration(seconds: 1);
      } else {
        _timer?.cancel();
        var check = await isDataStored();
        if (check && !_startController.start.value) {
          _showNextStepDialog();
        }
      }
    });
  }

  void _showNextStepDialog() {
    if (_timer != null && _timer!.isActive) {
      _timer?.cancel(); // Cancel timer before showing dialog
    }

    if (Get.isDialogOpen == true) {
      return; // Prevent opening multiple instances
    }

    Get.dialog(AlertDialog(
      title: Text('Time’s up!'),
      content: Text('Would you like to add 10 more minutes?'),
      actions: <Widget>[
        TextButton(
          onPressed: () async {
            List<Map<String, dynamic>> retrievedData = await retrieveData();
            retrievedData.removeAt(0);
            PolygonModel firstPolygon = PolygonModel.fromJson(retrievedData[0]);
            print(firstPolygon.navigatingCoordinateStart.latitude);
            print(firstPolygon.navigatingCoordinateStart.longitude);
            openMapWithDirections(_locationController.currentLocation.value.latitude, _locationController.currentLocation.value.longitude, firstPolygon.navigatingCoordinateStart.longitude,firstPolygon.navigatingCoordinateStart.latitude );
            streetBloc.fetchStreetsByPolygon(firstPolygon.polygonId);
            await storeData(retrievedData);
            remainingTime.value = Duration(minutes: firstPolygon.timer);
            _eulerCircuit.setCurrentSegmentIndex(0);
            Get.back();
          },
          child: Text('Next Village'),
        ),
        TextButton(
          onPressed: () {
            remainingTime.value = Duration(minutes: 10);
            Get.back();
          },
          child: Text('Add 10 minutes'),
        ),
      ],
    )).then((_) {
      // This block is executed after the dialog is dismissed
      if (_timer == null || !_timer!.isActive) {
        startTimer(); // Restart timer if not already running
      }
    });
  }

  // Your existing methods (twoDigits, onClose)
  String twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  void onClose() {
    WidgetsBinding.instance!.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }
}




