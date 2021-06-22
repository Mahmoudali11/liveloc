import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:livelocation/trac.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FirebaseFirestore fs = FirebaseFirestore.instance;
  DocumentReference? re;
  Marker? m;
  Circle? c;
  GoogleMapController? gmc;
  int i = 0;
  ByteData? bytesd;
  Position? p;

  @override
  dispose() {
    print("diposes");
    fs
        .collection("dl")
        .doc(re!.id)
        .delete()
        .then((value) => print("object deleted"));
    if (gmc != null) gmc!.dispose();

    super.dispose();
  }

  Future<Position> _determinePosition() async {
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
    p = await Geolocator.getCurrentPosition();

    c = Circle(
        fillColor: Colors.blue.withAlpha(70),
        strokeColor: Colors.blue,
        radius: 30,
        circleId: CircleId("fd"),
        center: LatLng(p!.latitude, p!.longitude));
    m = Marker(
        anchor: Offset(0.5, .6),
        position: LatLng(p!.latitude, p!.longitude),
        markerId: MarkerId("d"),
        icon: BitmapDescriptor.fromBytes(bytesd!.buffer.asUint8List()));
          re = await fs.collection("dl").add(
              {"location": GeoPoint(p!.latitude,p!.longitude)});
    return p!;
  }

  Future updateLocation() async {
    Geolocator.getPositionStream(intervalDuration: Duration(seconds: 10))
        .listen((Position? position) async {
      p = position;
      c = Circle(
          fillColor: Colors.blue.withAlpha(70),
          strokeColor: Colors.blue,
          radius: 30,
          circleId: CircleId("fd"),
          center: LatLng(p!.latitude, p!.longitude));
      m = Marker(
          anchor: Offset(0.5, .6),
          position: LatLng(position!.latitude, position.longitude),
          markerId: MarkerId("d"),
          icon: BitmapDescriptor.fromBytes(bytesd!.buffer.asUint8List()));
      gmc!.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 15,
      )));
      if (position != null) {
        if (re != null) {
       
        
 
          await fs.collection("dl").doc(re!.id).update(
              {"location": GeoPoint(position.latitude, position.longitude)});
          setState(() {
            m = m;
            c = c;
            p = p;
          });
        }
      }
    });
  }

  @override
  void initState() {
    _determinePosition().then((value) {
      setState(() {});
    });

    rootBundle.load('assets/m.png').then((value) {
      setState(() {
        bytesd = value;
      });
    });
    super.initState();
  }

  int v = 0;
  @override
  Widget build(BuildContext context) {
    if (gmc != null) {
      print("gmc init");
    }
    print(re != null ? re!.id : 2);
    print("build caled${i++}");
    return Scaffold(
      appBar: AppBar(
        title: Text("build caled${v++}"),
      ),
      body: p == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                GoogleMap(
                  circles: Set.of([c!]),
                  //myLocationEnabled: true,
                  markers: Set.of([m!]),
                  initialCameraPosition: CameraPosition(
                      target: LatLng(p!.latitude, p!.longitude), zoom: 15),
                  onMapCreated: (mc) async {
                    gmc = mc;
                    print("gggggggggg");
                  },
                ),
                Positioned(
                    top: 5,
                    left: 3,
                    child: ElevatedButton(
                        onPressed: () {
                          final route = MaterialPageRoute(builder: (context) {
                            return Tracking();
                          });
                          Navigator.push(context, route);
                        },
                        child: Text("Track$v"))),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          updateLocation();
        },
        child: Icon(Icons.play_arrow),
      ),
    );
  }
}
