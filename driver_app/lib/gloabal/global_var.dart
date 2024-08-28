import 'dart:async';
import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

String userName = "";
String googleMapKey = "AIzaSyCEv-qKdYWR06KN4bSkIvwHtEKu-4h8mqk";

const CameraPosition googlePlexInitialPosition = CameraPosition(
    target: LatLng(28.7213,77.1418),
    zoom: 15,
  );

StreamSubscription<Position>? positionStreamHomePage;
StreamSubscription<Position>? positionStreamNewTripPage;    

int driverTripRequestTimeout = 20;

final audioPlayer = AssetsAudioPlayer();

Position? driverCurrentPosition;

String driverName = "";
String driverPhone = "";
String driverPhoto = "";
String carColor = "";
String carModel = "";
String carNumber = "";


