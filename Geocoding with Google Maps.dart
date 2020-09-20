import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geocoder/geocoder.dart' as geoCo;
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Geocoding',
        home: Homepage());
  }
}

class Homepage extends StatefulWidget {
  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  GoogleMapController googleMapController;
  Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  Position position;
  String addressLocation;
  String country;
  String postalCode;

  void getMarkers(double lat, double long) {
    MarkerId markerId = MarkerId(lat.toString() + long.toString());
    Marker _marker = Marker(
        markerId: markerId,
        position: LatLng(lat, long),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
        infoWindow: InfoWindow(snippet: addressLocation));
    setState(() {
      markers[markerId] = _marker;
    });
  }

  void getCurrentLocation() async {
    Position currentPosition =
        await GeolocatorPlatform.instance.getCurrentPosition();
    setState(() {
      position = currentPosition;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
      ),
      body: Container(
        child: Column(
          children: [
            SizedBox(
              height: 600.0,
              child: GoogleMap(
                  onTap: (tapped) async {
                    final coordinated = new geoCo.Coordinates(
                        tapped.latitude, tapped.longitude);
                    var address = await geoCo.Geocoder.local
                        .findAddressesFromCoordinates(coordinated);
                    var firstAddress = address.first;
                    getMarkers(tapped.latitude, tapped.longitude);
                    await FirebaseFirestore.instance
                        .collection('location')
                        .add({
                      'latitude': tapped.latitude,
                      'longitude': tapped.longitude,
                      'Address': firstAddress.addressLine,
                      'Country': firstAddress.countryName,
                      'PostalCode': firstAddress.postalCode
                    });
                    setState(() {
                      country = firstAddress.countryName;
                      postalCode = firstAddress.postalCode;
                      addressLocation = firstAddress.addressLine;
                    });
                  },
                  mapType: MapType.hybrid,
                  compassEnabled: true,
                  trafficEnabled: true,
                  onMapCreated: (GoogleMapController controller) {
                    setState(() {
                      googleMapController = controller;
                    });
                  },
                  initialCameraPosition: CameraPosition(
                      target: LatLng(21.1428,79.08820),
                      zoom: 15.0),
                  markers: Set<Marker>.of(markers.values)),
            ),
            Text('Address : $addressLocation'),
            Text('PostalCode : $postalCode'),
            Text('Country : $country')
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
