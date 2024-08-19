import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:navigation/screens/Login screen.dart';
import 'package:navigation/Utility.dart';
import 'package:navigation/Service/Bloc.dart';
import 'package:navigation/screens/Maps.dart';
import 'package:navigation/Getx/maps.dart';
import 'package:navigation/Widget/StartEnd.dart';
import 'package:navigation/Getx/navigation.dart';
import 'package:navigation/Getx/timer.dart';
import 'package:navigation/Getx/euler.dart';
import 'package:navigation/Widget/street review.dart';
import 'package:navigation/Getx/street review.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeControllers();

  runApp(MyApp());
}

Future<void> initializeControllers() async {
  Get.put(LocationController());
  Get.put(StartController());
  Get.put(NavigationController());
  Get.put(EulerCircuit());
  Get.put(StreetreviewController());
  Get.put(CountdownController());
  Get.put(ReasonController());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(
        primaryColor: Colors.black,
      ),
      home: InitialScreen(), // MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitialScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: checkLoginStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white70,
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.white70,
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        } else {
          return snapshot.data == true ? MapScreen() : LoginPage();
        }
      },
    );
  }

  Future<bool> checkLoginStatus() async {
    JWT jwt = JWT();
    var token = await jwt.read_token();
    if (token == null) {
      return false;
    }
    await userBloc.currentuser();
    return userBloc.getUserObject() != null;
  }
}
