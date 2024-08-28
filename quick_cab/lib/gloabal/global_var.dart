import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String userPhone = "";
String userID = FirebaseAuth.instance.currentUser!.uid;
String googleMapKey = "AIzaSyCEv-qKdYWR06KN4bSkIvwHtEKu-4h8mqk";

const CameraPosition googlePlexInitialPosition = CameraPosition(
    target: LatLng(28.7213,77.1418),
    zoom: 15,
  );