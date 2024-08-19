import 'dart:async';
import 'package:navigation/Service/Api Service.dart';
import 'package:navigation/Model/polygon.dart';

class Repository {
  final apiProvider = Apirepository();
  Future<dynamic> registerUser(Map<dynamic,dynamic> user) =>
      apiProvider.signUp(user);

  Future signinUser(String email, String password) =>
      apiProvider.signInWithEmail(email, password);


  Future currentuser() =>
      apiProvider.getCurrentUser();
  Future<List<PolygonModel>> fetchPolygons() => apiProvider.fetchPolygons();

  Future<Map<String, dynamic>> fetchStreetsByPolygon(String polygonId) => apiProvider.fetchStreetsByPolygon(polygonId);

  Future<bool> updateStreet(int streetId, String delStatus, String delType, String delReason) => apiProvider.updateStreet(streetId, delStatus, delType, delReason);

}

final repository = Repository();
