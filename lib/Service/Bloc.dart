import 'package:rxdart/rxdart.dart';
import 'package:navigation/Service/Repository.dart';
import 'package:navigation/Model/user.dart';



class UserBloc {
  final PublishSubject<User> _userGetter = PublishSubject<User>();
  User _user = new User.blank();

  UserBloc._privateConstructor();

  static final UserBloc _instance = UserBloc._privateConstructor();

  factory UserBloc() {
    return _instance;
  }

  Stream<User> get getUser => _userGetter.stream;

  User getUserObject() {
    return _user;
  }

  Future<void> registerUser(Map<dynamic,dynamic> user) async {
    try {
      _user = await repository.registerUser(user);

      _userGetter.sink.add(_user);
    } catch (e) {
      throw e;
    }
  }

  Future<void> emailsigninUser(
      String email, String password) async {
    try {
      _user = await repository.signinUser(email, password);
      _userGetter.sink.add(_user);
    } catch (e) {
      throw e;
    }
  }


  Future<void> currentuser() async {
    try {
      _user = await repository.currentuser();
      _userGetter.sink.add(_user);
    } catch (e) {
      throw e;
    }
  }



  dispose() {
    _userGetter.close();
  }
}

UserBloc userBloc = UserBloc();



class StreetBloc {
  final PublishSubject<Map<dynamic,dynamic>> _streetDataGetter = PublishSubject<Map<dynamic,dynamic>>();
  dynamic _streets;

  StreetBloc._privateConstructor();

  static final StreetBloc _instance = StreetBloc._privateConstructor();

  factory StreetBloc() {
    return _instance;
  }

  Stream<Map<dynamic,dynamic>> get streetDataStream => _streetDataGetter.stream;

  dynamic getstreetsObject() {
    return _streets;
  }


  Future<void> fetchStreetsByPolygon(String polygonId) async {
    try {
      _streets = await repository.fetchStreetsByPolygon(polygonId);

      _streetDataGetter.sink.add(_streets);
    } catch (e) {
      _streetDataGetter.sink.addError(e);
    }
  }



  Future updateStreet(int streetId, String delStatus, String delType, String delReason) async {
    try {
      await repository.updateStreet(streetId, delStatus, delType, delReason);
      return ;
    } catch (e) {
      throw e;
    }
  }

  dispose() {
    _streetDataGetter.close();
  }
}

StreetBloc streetBloc = StreetBloc();