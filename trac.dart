import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

class Tracking extends StatefulWidget {
  const Tracking({Key? key}) : super(key: key);

  @override
  _TrackingState createState() => _TrackingState();
}

class _TrackingState extends State<Tracking> {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  Position? p;
  ByteData? bytesd;

  Future getLocation() async {
    p = await Geolocator.getCurrentPosition();
    setState(() {
      p = p;
    });
  }

  @override
  void initState() {
    rootBundle.load('assets/m.png').then((value) {
      setState(() {
        bytesd = value;
      });
    });
    getLocation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: p == null
          ? Center(
              child: SingleChildScrollView(),
            )
          : Container(
              child: StreamBuilder<QuerySnapshot>(
                stream: firebaseFirestore.collection("dl").snapshots(),
                builder: (context, snap) {
                  print(snap.data);

                  print(snap.data);
                  if (!snap.hasData)
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  else if (snap.hasData) {
                    GeoPoint g = snap.data!.docs[0]["location"];
                    final gg = GeoPoint(g.latitude, g.longitude);
                    return GoogleMap(
                        myLocationEnabled: true,
                        markers: Set.of([
                          Marker(
                              anchor: Offset(0.5, .6),
                              position: LatLng(gg.latitude, gg.longitude),
                              markerId: MarkerId("d"),
                              icon: BitmapDescriptor.fromBytes(
                                  bytesd!.buffer.asUint8List()))
                        ]),
                        initialCameraPosition: CameraPosition(
                            zoom: 15,
                            target: LatLng(p!.latitude, p!.longitude)));
                  } else {
                    return Text("ff");
                  }
                },
              ),
            ),
    );
  }
}
