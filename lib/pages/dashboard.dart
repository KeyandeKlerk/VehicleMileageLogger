import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vehicle_log_book/pages/getStartingMileage.dart';
import 'package:vehicle_log_book/pages/login_page.dart';
import 'package:vehicle_log_book/pages/splash_screen.dart';
import 'package:vehicle_log_book/pages/widgets/header_widget.dart';

class Dashboard extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _DashboardState();
  }
}

class _DashboardState extends State<Dashboard> {
  String _FirstName = "";
  String _LastName = "";
  String _StartingMileage = "";
  String _EndingMileage = "";
  String _DateTime = "";
  String _DateTimeFuel = "";
  String _DistanceTravelled = "";
  String _UserID = "";
  String _MobileNumber = "";
  String _Email = "";
  String _Photo = "";
  String? _error;
  String _latitude = "";
  String _longitude = "";
  String _locationMessage = "";
  double _drawerIconSize = 24;
  double _drawerFontSize = 17;
  Timer? timer;
  String dropdownvalue = 'Business';
  var items = [
    'Business',
    'Personal',
  ];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _textEditingControllerClosingFuel =
      TextEditingController();
  final TextEditingController _textEditingControllerClosingTrip =
      TextEditingController();
  final TextEditingController _textEditingControllerVisitTrip =
      TextEditingController();
  @override
  void initState() {
    super.initState();
    autoLogIn();
    _determinePosition();
    timer = Timer.periodic(
        Duration(seconds: 15), (Timer t) => _determinePosition());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void autoLogIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userID = prefs.getString('UserID');
    if (userID == "") {
      setState(() {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          ModalRoute.withName('/'),
        );
      });
      return;
    }
    getCurrentInfoAndFuel(context, userID!);
  }

  void loadPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _UserID = prefs.getString('UserID')!;
      _FirstName = prefs.getString('FirstName')!;
      _LastName = prefs.getString('LastName')!;
      _MobileNumber = prefs.getString('MobileNumber')!;
      _Email = prefs.getString('Email')!;
      _Photo = prefs.getString('Photo')!;
    });
  }

  Future getCurrentInfoAndFuel(context, String userID) async {
    // set up POST request arguments
    final url = Uri.parse(
        'https://www.keyandeklerk.co.za/API/vehicleLoggerGetInfoAndFuel.php');
    final headers = {"Content-type": "application/json"};
    var json = '{"UserID": "' + userID + '"}';
    // make POST request
    final response = await http.post(url, headers: headers, body: json);
    // now we have a json...
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      _StartingMileage = jsonResponse["OpeningMileage"];
      if (_StartingMileage == "N/A"){
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => StartingMileage()),
    ModalRoute.withName('/'));
      }
      else {
        _EndingMileage = jsonResponse["ClosingMileage"];
        _DistanceTravelled = jsonResponse["DistanceTravelled"];
        _DateTime = jsonResponse["DateTime"];
        _DateTimeFuel = jsonResponse["DateTimeFuel"];
      }

    } else {
      print('Request failed with status1: ${response.body}.');
    }
  }

  Future insertNewTrip(
      context,
      String userID,
      int startingMileage,
      int endingMileage,
      String typeOfTrip,
      String latitude,
      String longitude) async {
    // set up POST request arguments
    final url = Uri.parse(
        'https://www.keyandeklerk.co.za/API/vehicleLoggerInsertTrip.php');
    final headers = {"Content-type": "application/json"};
    var json = '{"UserID": "' +
        userID +
        '","StartingMileage": "' +
        startingMileage.toString() +
        '","EndingMileage": "' +
        endingMileage.toString() +
        '","TripType": "' +
        typeOfTrip +
        '","Latitude": "' +
        latitude +
        '","Longitude": "' +
        longitude +
        '"}';
    print(json);
    // make POST request
    final response = await http.post(url, headers: headers, body: json);
    // now we have a json...
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print(jsonResponse);
      getCurrentInfoAndFuel(context, userID);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Dashboard()));
    } else {
      print('Request failed with status: ${response.body}.');
    }
  }

  Future insertNewFuel(context, String userID, int currentMileage,
      String latitude, String longitude) async {
    // set up POST request arguments
    final url = Uri.parse(
        'https://www.keyandeklerk.co.za/API/vehicleLoggerInsertFuel.php');
    final headers = {"Content-type": "application/json"};
    var json = '{"UserID": "' +
        userID +
        '","CurrentMileage": "' +
        currentMileage.toString() +
        '","Latitude": "' +
        latitude +
        '","Longitude": "' +
        longitude +
        '"}';
    // make POST request
    final response = await http.post(url, headers: headers, body: json);
    // now we have a json...
    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);
      print(jsonResponse);
      getCurrentInfoAndFuel(context, userID);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => Dashboard()));
    } else {
      print('Request failed with status: ${response.body}.');
    }
  }

  void _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _latitude = position.latitude.toString();
    _longitude = position.longitude.toString();
    List<Placemark> placemarks =
        await placemarkFromCoordinates(position.latitude, position.longitude);
    String message =
        '${placemarks.first.name!.isNotEmpty ? placemarks.first.name! + ' ' : ''}${placemarks.first.thoroughfare!.isNotEmpty ? placemarks.first.thoroughfare! + ', ' : ''}${placemarks.first.subLocality!.isNotEmpty ? placemarks.first.subLocality! + ', ' : ''}${placemarks.first.subAdministrativeArea!.isNotEmpty ? placemarks.first.subAdministrativeArea! + ', ' : ''}${placemarks.first.postalCode!.isNotEmpty ? placemarks.first.postalCode! + ', ' : ''}${placemarks.first.administrativeArea!.isNotEmpty ? placemarks.first.administrativeArea! + ', ' : ''}${placemarks.first.isoCountryCode!.isNotEmpty ? placemarks.first.isoCountryCode : ''}';
    _locationMessage = message;
  }

  void _insertFuel(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        controller: _textEditingControllerClosingFuel,
                        validator: (value) {
                          return value!.isNotEmpty
                              ? null
                              : "Enter the Closing reading for the Car";
                        },
                        decoration: InputDecoration(
                            hintText: "Current Odometer Reading"),
                      ),
                    ],
                  )),
              title: Text('Insert Fuel'),
              actions: <Widget>[
                InkWell(
                  child: Text('OK   '),
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      insertNewFuel(
                          context,
                          _UserID,
                          int.parse(_textEditingControllerClosingFuel.text),
                          _latitude,
                          _longitude);
                    }
                  },
                ),
              ],
            );
          });
        });
  }

  void _insertTrip(BuildContext context) async {
    return await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              content: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        controller: _textEditingControllerClosingTrip,
                        validator: (value) {
                          return value!.isNotEmpty
                              ? null
                              : "Enter the Closing reading for the Car";
                        },
                        decoration: InputDecoration(
                            hintText: "Current Odometer Reading"),
                      ),
                      TextFormField(
                        controller: _textEditingControllerVisitTrip,
                        validator: (value) {
                          return value!.isNotEmpty
                              ? null
                              : "Enter Visit Destination";
                        },
                        decoration:
                            InputDecoration(hintText: "Visit Destination"),
                      ),
                      SizedBox(
                        width: 250,
                        child: DropdownButton(
                          value: dropdownvalue,
                          icon: const Icon(Icons.keyboard_arrow_down),
                          isExpanded: true,
                          items: items.map((String items) {
                            return DropdownMenuItem(
                              value: items,
                              child: Text(items),
                            );
                          }).toList(),
                          // After selecting the desired option,it will
                          // change button value to selected value
                          onChanged: (String? newValue) {
                            setState(() {
                              dropdownvalue = newValue!;
                              print(dropdownvalue);
                            });
                          },
                        ),
                      ),
                    ],
                  )),
              title: Text('Insert Trip'),
              actions: <Widget>[
                InkWell(
                  child: Text('OK   '),
                  onTap: () {
                    if (_formKey.currentState!.validate()) {
                      insertNewTrip(
                          context,
                          _UserID,
                          int.parse(_EndingMileage),
                          int.parse(_textEditingControllerClosingTrip.text),
                          dropdownvalue,
                          _latitude,
                          _longitude);
                    }
                  },
                ),
              ],
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    loadPrefs();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                Theme.of(context).primaryColor,
                Theme.of(context).accentColor,
              ])),
        ),
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [
                0.0,
                1.0
              ],
                  colors: [
                Theme.of(context).primaryColor.withOpacity(0.2),
                Theme.of(context).accentColor.withOpacity(0.5),
              ])),
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 1.0],
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).accentColor,
                    ],
                  ),
                ),
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    "Vehicle Mileage Logger",
                    style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(
                  Icons.screen_lock_landscape_rounded,
                  size: _drawerIconSize,
                  color: Theme.of(context).accentColor,
                ),
                title: Text(
                  'Splash Screen',
                  style: TextStyle(
                      fontSize: 17, color: Theme.of(context).accentColor),
                ),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              SplashScreen(title: "Splash Screen")));
                },
              ),
              ListTile(
                leading: Icon(Icons.login_rounded,
                    size: _drawerIconSize,
                    color: Theme.of(context).accentColor),
                title: Text(
                  'Login Page',
                  style: TextStyle(
                      fontSize: _drawerFontSize,
                      color: Theme.of(context).accentColor),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
              ),
              Divider(
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
              ListTile(
                leading: Icon(
                  Icons.logout_rounded,
                  size: _drawerIconSize,
                  color: Theme.of(context).accentColor,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(
                      fontSize: _drawerFontSize,
                      color: Theme.of(context).accentColor),
                ),
                onTap: () async {
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.clear();
                  prefs.setString('UserID', "");
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    ModalRoute.withName('/'),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              height: 100,
              child: HeaderWidget(100, false, Icons.house_rounded),
            ),
            Container(
              alignment: Alignment.center,
              margin: EdgeInsets.fromLTRB(25, 10, 25, 10),
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(width: 5, color: Colors.white),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: const Offset(5, 5),
                        ),
                      ],
                    ),
                    child: SizedBox(
                        height: 100,
                        child: CircleAvatar(
                          radius: 50.0,
                          backgroundImage: NetworkImage(
                              "https://www.keyandeklerk.co.za/profilePicture/1_Keyan.jpg"),
                          backgroundColor: Colors.grey,
                        )),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'Welcome Back',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    ' ${_FirstName} ${_LastName}',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: <Widget>[
                        Card(
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                              side: BorderSide(
                                  color: Colors.grey.shade200, width: 0.5),
                              borderRadius: BorderRadius.circular(30)),
                          child: Container(
                            alignment: Alignment.topLeft,
                            padding: EdgeInsets.all(15),
                            child: Column(
                              children: <Widget>[
                                Column(
                                  children: <Widget>[
                                    ...ListTile.divideTiles(
                                      color: Colors.lightBlue,
                                      tiles: [
                                        ListTile(
                                            title: Text(_locationMessage,
                                                textAlign: TextAlign.center)),
                                        ListTile(
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          leading: Icon(Icons.my_location),
                                          title: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("Current Mileage")),
                                          subtitle: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text(_EndingMileage)),
                                        ),
                                        ListTile(
                                          leading:
                                              Icon(Icons.local_gas_station),
                                          title: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Text("Last Fill Up Date")),
                                          subtitle: Column(
                                            children: <Widget>[
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: Text(_DateTimeFuel),
                                              ),
                                              Align(
                                                alignment: Alignment.bottomLeft,
                                                child: ElevatedButton.icon(
                                                  icon: Icon(Icons
                                                      .local_gas_station_outlined),
                                                  style: ButtonStyle(
                                                      foregroundColor:
                                                          MaterialStateProperty
                                                              .all<Color>(
                                                                  Colors.white),
                                                      backgroundColor:
                                                          MaterialStateProperty.all<Color>(
                                                              Colors.purple),
                                                      shape: MaterialStateProperty.all<
                                                              RoundedRectangleBorder>(
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(18.0),
                                                              side: BorderSide(color: Colors.purple)))),
                                                  onPressed: () {
                                                    _insertFuel(context);
                                                  },
                                                  label: Text("ADD FUEL"),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          _insertTrip(context);
          // Add your onPressed code here!
        },
        label: const Text('ADD TRIP'),
        icon: const Icon(Icons.add_location_sharp),
        backgroundColor: HexColor('#00ffff'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
