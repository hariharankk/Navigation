import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:navigation/utility.dart';
import 'package:navigation/Model/user.dart';
import 'dart:async';
import 'package:navigation/Model/polygon.dart';
import 'package:navigation/Model/Streets.dart';
import 'package:navigation/Service/Bloc.dart';

String SERVERURL = 'https://7c72-34-150-157-0.ngrok-free.app';


class Apirepository {

  String? Token;
  JWT jwt = JWT();


  Future<dynamic> signUp(Map<dynamic, dynamic> user) async {
    String URL = '$SERVERURL/register/';
    try {
      final response = await http.post(
        Uri.parse(URL),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(user),
      );
      var responseData = json.decode(response.body);
      if (responseData['status']) {
        return User.fromMap(responseData["data"]);
      }
      else {
        return '';
      }
    } catch (e) {
      return '';
    }
  }

  Future<dynamic> getCurrentUser() async {
    Token = await jwt.read_token();
    if (Token == null) {
      return null;
    }
    String URL = '$SERVERURL/currentuser';
    final response = await http.get(Uri.parse(URL),
      headers: <String, String>{
        'x-access-token': Token!
      },
    );
    try {
      var responseData = json.decode(response.body);
      User user = User.fromMap(
          responseData); //list, alternative empty string " "
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await jwt.delete_token();
  }


  Future<dynamic> signInWithEmail(String email, String password) async {
    String URL = '$SERVERURL/login';
    try {
      final response = await http.post(
        Uri.parse(URL),
        headers: <String, String>{
          "Access-Control-Allow-Origin": "*",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(
            <String, String>{'emailaddress': email, 'password': password}),
      );
      var responseData = json.decode(response.body);
      if (responseData['status']) {
        await jwt.store_token(responseData['token']);
        return User.fromMap(responseData["data"]);
      }
      else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }



  Future<List<PolygonModel>> fetchPolygons() async {
    Token = await jwt.read_token();
    if (Token == null) {
      throw Exception('Token is null'); // Throw an exception if the token is null
    }

    var userId = userBloc.getUserObject().user;
    //var userId = 1;
    String url = '$SERVERURL/user/polygons?user_id=$userId';

    final response = await http.get(Uri.parse(url),
      headers: <String, String>{
        'x-access-token': Token!
      },);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, parse the JSON
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == true) {
        // If status is true, parse the polygon data
        List<dynamic> polygonsJson = data['polygons'];

        return polygonsJson.map((json) => PolygonModel.fromJson(json)).toList();
      } else {
        // If status is false, throw an exception with the message from the server
        throw Exception(data['message']);
      }
    } else {
      // If the server did not return a 200 OK response, throw an exception
      throw Exception(
          'Failed to load polygons, status code: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchStreetsByPolygon(String polygonId) async {
    Token = await jwt.read_token();
    if (Token == null) {
      throw Exception('Token is null'); // Throw an exception if the token is null
    }

    String url = '$SERVERURL/streets?polygon_id=$polygonId';

    final response = await http.get(Uri.parse(url),
      headers: <String, String>{
        'x-access-token': Token!
      },);

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response, parse the JSON
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == true) {
        print(data['streets']);
        // If status is true, parse the streets data and Eulerian circuit
        List<dynamic> streetsJson = data['streets'];
        var eulerCircuit = data['euler_circuit']; // This needs to be serializable data
        List<dynamic> streets = streetsJson.map((json) =>
            StreetModel.fromJson(json)).toList();

        // Return a map with both streets and eulerCircuit
        return {
          'streets': streets,
          'eulerCircuit': eulerCircuit,
        };
      } else {
        // If status is false, throw an exception with the message from the server
        throw Exception(data['message']);
      }
    } else {
      // If the server did not return a 200 OK response, throw an exception
      throw Exception(
          'Failed to load streets, status code: ${response.statusCode}');
    }
  }

// Function to update street details
  Future<bool> updateStreet(int streetId, String delStatus, String delType,
      String delReason) async {
    Token = await jwt.read_token();
    if (Token == null) {
      throw Exception('Token is null'); // Throw an exception if the token is null
    }
    String url = '$SERVERURL/update_street';

    // Prepare the data to be sent in the request
    Map<String, dynamic> updateData = {
      'street_id': streetId,
      'del_status': delStatus,
      'del_type': delType,
      'del_reason': delReason,
    };

    try {
      // Send the PATCH request
      final response = await http.patch(
        Uri.parse(url),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-access-token': Token!
        },
        // Encoding the data to JSON
        body: jsonEncode(updateData),
      );

      // Handle the response from the server
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          return true;
        } else {
          throw Exception(responseData['message']);
        }
      } else {
        throw Exception(
            'Failed to update street details, status code: ${response
                .statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update street details, exception thrown: $e');
    }
  }


  Future<bool> updateStreetDetails(int streetId, String delStatus,
      String delType, String delReason) async {
    Token = await jwt.read_token();
    if (Token == null) {
      throw Exception('Token is null'); // Throw an exception if the token is null
    }

    var url = Uri.parse('$SERVERURL/update_street');
    Map<String, dynamic> data = {
      'street_id': streetId,
      'del_status': delStatus,
      'del_type': delType,
      'del_reason': delReason,
    };

    try {
      var response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          "Accept": "application/json",
          "Access-Control-Allow-Origin": "*",
          'x-access-token': Token!
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        if (responseData['status'] == true) {
          print('Street updated successfully');
          return true;
        } else {
          print('Failed to update street: ${responseData['message']}');
          return false;
        }
      } else {
        print('Failed to update street. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception thrown while updating street: $e');
      return false;
    }
  }
}