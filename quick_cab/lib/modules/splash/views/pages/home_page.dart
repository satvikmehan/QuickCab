import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';
import 'package:quick_cab/appinfo/app_info.dart';
import 'package:quick_cab/gloabal/global_var.dart';
import 'package:quick_cab/gloabal/trip_var.dart';
import 'package:quick_cab/models/direction_details.dart';
import 'package:quick_cab/models/online_nearby_drivers.dart';
import 'package:quick_cab/modules/splash/views/pages/about_page.dart';
import 'package:quick_cab/modules/splash/views/pages/login_screen.dart';
import 'package:quick_cab/modules/splash/views/pages/search_destination_page.dart';
import 'package:quick_cab/modules/splash/views/pages/trips_history_page.dart';
import 'package:quick_cab/modules/splash/views/widgets/loading_dialog.dart';
import 'package:quick_cab/shared/methods/common_methods.dart';
import 'package:quick_cab/shared/methods/manage_drivers_methods.dart';
import 'package:quick_cab/shared/methods/push_notification_service.dart';
import 'package:quick_cab/shared/widgets/info_dialog.dart';
import 'package:quick_cab/shared/widgets/payment_dialog.dart';
import 'package:restart_app/restart_app.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final Completer<GoogleMapController> googleMapCompletterController =
  Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;
  Position? currentPositionOfUser; 
  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>(); 
  CommonMethods cMethods = CommonMethods();
  double searchContainerHeight = 276; 
  double bottomMapPadding = 0;  
  double rideDetailsContainerHeight = 0;
  double requestContainerHeight = 0;
  double tripContainerHeight= 0;
  DirectionDetails? tripDirectionDetailsInfo;
  List<LatLng> polylineCoOrdinates = [];
  Set<Polyline> polylineSet = {};
  Set<Marker> markerSet = {};
  Set<Circle> circleSet = {};
  bool isDrawerOpened = true;
  String stateOfApp = "normal";
  bool nearbyOnlineDriversKeysLoaded = false;
  BitmapDescriptor? carIconNearbyDriver;
  DatabaseReference? tripRequestRef;
  List<OnlineNearbyDrivers>? availableNearbyOnlineDriversList;
  StreamSubscription<DatabaseEvent>? tripStreamSubscription;
  bool requestingDirectionDetailsInfo = false;

  makeDriverNearbyCarIcon()
  {
    if(carIconNearbyDriver == null)
    {
      ImageConfiguration configuration = createLocalImageConfiguration(context, size: const Size(38, 38));
      BitmapDescriptor.asset(configuration, "assets/images/tracking.png").then((iconImage)
      {
        carIconNearbyDriver = iconImage;
      });
    }
  }


  void updateMapTheme(GoogleMapController controller)
  {
    getJsonFileFromThemes("themes/retro_style.json").then((value) => setGoogleMapStyle(value, controller));
  }

  Future<String> getJsonFileFromThemes(String mapStylePath) async
  {
    ByteData byteData = await rootBundle.load(mapStylePath);
    var list = byteData.buffer.asUint8List(byteData.offsetInBytes,byteData.lengthInBytes);
    return utf8.decode(list);
  }

  setGoogleMapStyle(String setGoogleMapStyle, GoogleMapController controller)
  {
    // ignore: deprecated_member_use
    controller.setMapStyle(setGoogleMapStyle);
  }

  getCurrentLiveLocationOfUser() async
  {
    // ignore: deprecated_member_use
    Position positionOfUser = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.bestForNavigation);
    currentPositionOfUser = positionOfUser;

    LatLng positionOfUserInLatLng = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);
    CameraPosition cameraPosition = CameraPosition(target: positionOfUserInLatLng, zoom: 15);
    controllerGoogleMap!.animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    await cMethods.convertGeoGraphicCoOrdinatesIntoHumanReadableAddress(currentPositionOfUser!,context);

    await getUserInfoAndCheckBlockStauts();
    
    await initializeGeoFireListener();

  }

  getUserInfoAndCheckBlockStauts() async
  {
    DatabaseReference usersRef = FirebaseDatabase.instance.ref().child("users").child(FirebaseAuth.instance.currentUser!.uid);
    await usersRef.once().then((snap)
      {
        if(snap.snapshot.value != null)
        {
          if((snap.snapshot.value as Map)["blockStatus"] == "no")
          {
            setState(() 
            {
              userName = (snap.snapshot.value as Map)["name"];
              userPhone = (snap.snapshot.value as Map)["phone"]; 
            }
            );
          }
          else
          {
            FirebaseAuth.instance.signOut();
            Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
            cMethods.displaySnackBar("You are blocked. Contact admin: quickcab0108@gmail.com", context);
          }

        }
        else
        {
          FirebaseAuth.instance.signOut();
          Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen()));
        }
      });
  }

  displayUserRideDetailsContainer() async
  {
    ///Directions API
    await retrieveDirectionDetails();

    setState(() {
      searchContainerHeight = 0;
      bottomMapPadding = 240;
      rideDetailsContainerHeight = 242;
      isDrawerOpened = false;
    });
  }

  retrieveDirectionDetails() async
  {
    var pickUpLocation = Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    var pickupGeoGraphicCoOrdinates = LatLng(pickUpLocation!.latitudePosition!, pickUpLocation.longitudePosition!);
    var dropOffDestinationGeoGraphicCoOrdinates = LatLng(dropOffDestinationLocation!.latitudePosition!, dropOffDestinationLocation.longitudePosition!);

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (BuildContext context) => LoadingDialog(messageText: "Getting direction..."),
    );

    ///Directions API
    var detailsFromDirectionAPI = await CommonMethods.getDirectionDetailsFromAPI(pickupGeoGraphicCoOrdinates, dropOffDestinationGeoGraphicCoOrdinates);
    setState(() {
      tripDirectionDetailsInfo = detailsFromDirectionAPI;
    });

    Navigator.pop(context);

    //draw route from pickup to dropOffDestination
    PolylinePoints pointsPolyline = PolylinePoints();
    List<PointLatLng> latLngPointsFromPickUpToDestination = pointsPolyline.decodePolyline(tripDirectionDetailsInfo!.encodedPoints!);

    polylineCoOrdinates.clear();
    if(latLngPointsFromPickUpToDestination.isNotEmpty)
    {
      latLngPointsFromPickUpToDestination.forEach((PointLatLng latLngPoint)
      {
        polylineCoOrdinates.add(LatLng(latLngPoint.latitude, latLngPoint.longitude));
      });
    }

    polylineSet.clear();
    setState(() 
    {
      Polyline polyline = Polyline(
        polylineId: const PolylineId("polylineID"),
        color: Colors.pink,
        points: polylineCoOrdinates,
        jointType: JointType.round,
        width: 4,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      polylineSet.add(polyline);
    }
    );

    //fit the polyline into the map
    LatLngBounds boundsLatLng;
    if(pickupGeoGraphicCoOrdinates.latitude > dropOffDestinationGeoGraphicCoOrdinates.latitude
        && pickupGeoGraphicCoOrdinates.longitude > dropOffDestinationGeoGraphicCoOrdinates.longitude)
    {
      boundsLatLng = LatLngBounds(
          southwest: dropOffDestinationGeoGraphicCoOrdinates,
          northeast: pickupGeoGraphicCoOrdinates,
      );
    }
    else if(pickupGeoGraphicCoOrdinates.longitude > dropOffDestinationGeoGraphicCoOrdinates.longitude)
    {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(pickupGeoGraphicCoOrdinates.latitude, dropOffDestinationGeoGraphicCoOrdinates.longitude),
        northeast: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude, pickupGeoGraphicCoOrdinates.longitude),
      );
    }
    else if(pickupGeoGraphicCoOrdinates.latitude > dropOffDestinationGeoGraphicCoOrdinates.latitude)
    {
      boundsLatLng = LatLngBounds(
          southwest: LatLng(dropOffDestinationGeoGraphicCoOrdinates.latitude, pickupGeoGraphicCoOrdinates.longitude),
          northeast: LatLng(pickupGeoGraphicCoOrdinates.latitude, dropOffDestinationGeoGraphicCoOrdinates.longitude),
      );
    }
    else
    {
      boundsLatLng = LatLngBounds(
          southwest: pickupGeoGraphicCoOrdinates,
          northeast: dropOffDestinationGeoGraphicCoOrdinates,
      );
    }

    controllerGoogleMap!.animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 72));

    //add markers to pickup and dropOffDestination points
    Marker pickUpPointMarker = Marker(
      markerId: const MarkerId("pickUpPointMarkerID"),
      position: pickupGeoGraphicCoOrdinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: pickUpLocation.placeName, snippet: "Pickup Location"),
    );

    Marker dropOffDestinationPointMarker = Marker(
      markerId: const MarkerId("dropOffDestinationPointMarkerID"),
      position: dropOffDestinationGeoGraphicCoOrdinates,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: InfoWindow(title: dropOffDestinationLocation.placeName, snippet: "Destination Location"),
    );

    setState(() {
      markerSet.add(pickUpPointMarker);
      markerSet.add(dropOffDestinationPointMarker);
    });

    //add circles to pickup and dropOffDestination points
    Circle pickUpPointCircle = Circle(
      circleId: const CircleId('pickupCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: pickupGeoGraphicCoOrdinates,
      fillColor: Colors.pink,
    );

    Circle dropOffDestinationPointCircle = Circle(
      circleId: const CircleId('dropOffDestinationCircleID'),
      strokeColor: Colors.blue,
      strokeWidth: 4,
      radius: 14,
      center: dropOffDestinationGeoGraphicCoOrdinates,
      fillColor: Colors.pink,
    );

    setState(() {
      circleSet.add(pickUpPointCircle);
      circleSet.add(dropOffDestinationPointCircle);
    });
  }
      
  resetAppNow()
  {
    setState(() 
    {
      polylineCoOrdinates.clear();
      polylineSet.clear();
      markerSet.clear();
      circleSet.clear();
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 0;
      tripContainerHeight = 0;
      searchContainerHeight = 276;
      bottomMapPadding = 300;
      isDrawerOpened = true;

      status = "";
      nameDriver = "";
      photoDriver = "";
      phoneNumberDriver = "";
      carDetailsDriver = "";
      tripStatusDisplay = 'Driver is Arriving';
    }
    );
  }

  cancelRideRequest()
  {
    tripRequestRef!.remove();

    setState(() 
    {
      stateOfApp = "normal";
    })
    ;
  }

  displayRequestContainer()
  {
    setState(() 
    {
      rideDetailsContainerHeight = 0;
      requestContainerHeight = 220;
      bottomMapPadding = 200;
      isDrawerOpened = true;
    }
    );

    makeTripRequest();
  }
  
  updateAvailableNearbyOnlineDriversOnMap()
  {
    setState(() 
    {
      markerSet.clear();
    });

    Set<Marker> markersTempSet = Set<Marker>();

    for(OnlineNearbyDrivers eachOnlineNearbyDriver in ManageDriversMethods.nearbyOnlineDriversList)
    {
      LatLng driverCurrentPosition = LatLng(eachOnlineNearbyDriver.latDriver!, eachOnlineNearbyDriver.lngDriver!);

      Marker driverMarker = Marker(
        markerId: MarkerId("driver ID = " + eachOnlineNearbyDriver.uidDriver.toString()),
        position: driverCurrentPosition,
        icon: carIconNearbyDriver!,
      );

      markersTempSet.add(driverMarker);
    }

    setState(() {
      markerSet = markersTempSet;
    });
  }

  initializeGeoFireListener()
  {
    Geofire.initialize("onlineDrivers");
    Geofire.queryAtLocation(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude, 22)!
        .listen((driverEvent)
    {
      if(driverEvent != null)
      {
        var onlineDriverChild = driverEvent["callBack"];

        switch(onlineDriverChild)
        {
          case Geofire.onKeyEntered:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethods.nearbyOnlineDriversList.add(onlineNearbyDrivers);

            if(nearbyOnlineDriversKeysLoaded == true)
            {
              //update drivers on google map
              updateAvailableNearbyOnlineDriversOnMap();
            }

            break;

          case Geofire.onKeyExited:
            ManageDriversMethods.removeDriverFromList(driverEvent["key"]);

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;

          case Geofire.onKeyMoved:
            OnlineNearbyDrivers onlineNearbyDrivers = OnlineNearbyDrivers();
            onlineNearbyDrivers.uidDriver = driverEvent["key"];
            onlineNearbyDrivers.latDriver = driverEvent["latitude"];
            onlineNearbyDrivers.lngDriver = driverEvent["longitude"];
            ManageDriversMethods.updateOnlineNearbyDriversLocation(onlineNearbyDrivers);

            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();

            break;

          case Geofire.onGeoQueryReady:
            nearbyOnlineDriversKeysLoaded = true;
            
            //update drivers on google map
            updateAvailableNearbyOnlineDriversOnMap();
            
            break;
        }
      }
    });
  }

  makeTripRequest()
  {
    tripRequestRef = FirebaseDatabase.instance.ref().child("tripRequests").push();

    var pickUpLocation = Provider.of<AppInfo>(context, listen: false).pickUpLocation;
    var dropOffDestinationLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;

    Map pickUpCoOrdinatesMap =
    {
      "latitude": pickUpLocation!.latitudePosition.toString(),
      "longitude": pickUpLocation.longitudePosition.toString(),
    };

    Map dropOffDestinationCoOrdinatesMap =
    {
      "latitude": dropOffDestinationLocation!.latitudePosition.toString(),
      "longitude": dropOffDestinationLocation.longitudePosition.toString(),
    };

    Map driverCoOrdinates =
    {
      "latitude": "",
      "longitude": "",
    };

    Map dataMap =
    {
      "tripID": tripRequestRef!.key,
      "publishDateTime": DateTime.now().toString(),

      "userName": userName,
      "userPhone": userPhone,
      "userID": userID,
      "pickUpLatLng": pickUpCoOrdinatesMap,
      "dropOffLatLng": dropOffDestinationCoOrdinatesMap,
      "pickUpAddress": pickUpLocation.placeName,
      "dropOffAddress": dropOffDestinationLocation.placeName,

      "driverID": "waiting",
      "carDetails": "",
      "driverLocation": driverCoOrdinates,
      "driverName": "",
      "driverPhone": "",
      "driverPhoto": "",
      "fareAmount": "",
      "status": "new",
    };

    tripRequestRef!.set(dataMap);

    tripStreamSubscription = tripRequestRef!.onValue.listen((eventSnapshot) async
    {
      if(eventSnapshot.snapshot.value == null)
      {
        return;
      }

      if((eventSnapshot.snapshot.value as Map)["driverName"] != null)
      {
        nameDriver = (eventSnapshot.snapshot.value as Map)["driverName"];
      }

      if((eventSnapshot.snapshot.value as Map)["driverPhone"] != null)
      {
        phoneNumberDriver = (eventSnapshot.snapshot.value as Map)["driverPhone"];
      }

      if((eventSnapshot.snapshot.value as Map)["driverPhoto"] != null)
      {
        photoDriver = (eventSnapshot.snapshot.value as Map)["driverPhoto"];
      }

      if((eventSnapshot.snapshot.value as Map)["carDetails"] != null)
      {
        carDetailsDriver = (eventSnapshot.snapshot.value as Map)["carDetails"];
      }

      if((eventSnapshot.snapshot.value as Map)["status"] != null)
      {
        status = (eventSnapshot.snapshot.value as Map)["status"];
      }

      if((eventSnapshot.snapshot.value as Map)["driverLocation"] != null)
      {
        double driverLatitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["latitude"].toString());
        double driverLongitude = double.parse((eventSnapshot.snapshot.value as Map)["driverLocation"]["longitude"].toString());
        LatLng driverCurrentLocationLatLng = LatLng(driverLatitude, driverLongitude);

        if(status == "accepted")
        {
          //update info for pickup to user on UI
          //info from driver current location to user pickup location
          updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng);
        }
        else if(status == "arrived")
        {
          //update info for arrived - when driver reach at the pickup point of user
          setState(() 
          {
            tripStatusDisplay = 'Driver has Arrived';
          }
          );
        }
        else if(status == "ontrip")
        {
          //update info for dropoff to user on UI
          //info from driver current location to user dropoff location
          updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng);
        }
      }

      if(status == "accepted")
      {
        displayTripDetailsContainer();

        Geofire.stopListener();

        //remove drivers markers
        setState(() 
        {
          markerSet.removeWhere((element) => element.markerId.value.contains("driver"));
        }
        );
      }

      if(status == "ended")
      {
        if((eventSnapshot.snapshot.value as Map)["fareAmount"] != null)
        {
          double fareAmount = double.parse((eventSnapshot.snapshot.value as Map)["fareAmount"].toString());

          var responseFromPaymentDialog = await showDialog(
              context: context,
              builder: (BuildContext context) => PaymentDialog(fareAmount: fareAmount.toString()),
          );

          if(responseFromPaymentDialog == "paid")
          {
            tripRequestRef!.onDisconnect();
            tripRequestRef = null;

            tripStreamSubscription!.cancel();
            tripStreamSubscription = null;

            resetAppNow();

            //Restart.restartApp();
          }
        }
      }
    });
  }

  displayTripDetailsContainer()
  {
    setState(() {
      requestContainerHeight = 0;
      tripContainerHeight = 291;
      bottomMapPadding = 281;
    });
  }

  updateFromDriverCurrentLocationToPickUp(driverCurrentLocationLatLng) async
  {
    if(!requestingDirectionDetailsInfo)
    {
      requestingDirectionDetailsInfo = true;

      var userPickUpLocationLatLng = LatLng(currentPositionOfUser!.latitude, currentPositionOfUser!.longitude);

      var directionDetailsPickup = await CommonMethods.getDirectionDetailsFromAPI(driverCurrentLocationLatLng, userPickUpLocationLatLng);

      if(directionDetailsPickup == null)
      {
        return;
      }

      setState(() {
        tripStatusDisplay = "Driver is Coming - ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  updateFromDriverCurrentLocationToDropOffDestination(driverCurrentLocationLatLng) async
  {
    if(!requestingDirectionDetailsInfo)
    {
      requestingDirectionDetailsInfo = true;

      var dropOffLocation = Provider.of<AppInfo>(context, listen: false).dropOffLocation;
      var userDropOffLocationLatLng = LatLng(dropOffLocation!.latitudePosition!, dropOffLocation.longitudePosition!);

      var directionDetailsPickup = await CommonMethods.getDirectionDetailsFromAPI(driverCurrentLocationLatLng, userDropOffLocationLatLng);

      if(directionDetailsPickup == null)
      {
        return;
      }

      setState(() {
        tripStatusDisplay = "Driving to DropOff Location - ${directionDetailsPickup.durationTextString}";
      });

      requestingDirectionDetailsInfo = false;
    }
  }

  noDriverAvailable()
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => InfoDialog(
          title: "No Driver Available",
          description: "No driver found in the nearby location. Please try again shortly.",
        )
    );
  }

  searchDriver()
  {
    if(availableNearbyOnlineDriversList!.length == 0)
    {
      cancelRideRequest();
      resetAppNow();
      noDriverAvailable();
      return;
    }

    // ignore: unused_local_variable
    var currentDriver = availableNearbyOnlineDriversList![0];

    //send notification to this currentDriver
    sendNotificationToDriver(currentDriver);

    availableNearbyOnlineDriversList!.removeAt(0);
  }
  
  sendNotificationToDriver(OnlineNearbyDrivers currentDriver)
  {
    //update driver's newTripStatus - assign tripID to current driver
    DatabaseReference currentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("newTripStatus");

    currentDriverRef.set(tripRequestRef!.key);

    //get current driver device recognition token
    DatabaseReference tokenOfCurrentDriverRef = FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentDriver.uidDriver.toString())
        .child("deviceToken");

    tokenOfCurrentDriverRef.once().then((dataSnapshot)
    {
      if(dataSnapshot.snapshot.value != null)
      {
        String deviceToken = dataSnapshot.snapshot.value.toString();

        //send notification
        PushNotificationService.sendNotificationToSelectedDriver(
            deviceToken,
            context,
            tripRequestRef!.key.toString()
        );
      }
      else
      {
        return;
      }

      const oneTickPerSec = Duration(seconds: 1);

      var timerCountDown = Timer.periodic(oneTickPerSec, (timer)
      {

        requestTimeoutDriver = requestTimeoutDriver - 1;


        if(stateOfApp != "requesting")
        {
          timer.cancel();
          currentDriverRef.set("cancelled");
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;
        }

        currentDriverRef.onValue.listen((dataSnapshot)
        {
          if(dataSnapshot.snapshot.value.toString() == "accepted")
          {
            timer.cancel();
            currentDriverRef.onDisconnect();
            requestTimeoutDriver = 20;
          }
        });

        if(requestTimeoutDriver == 0)
        {
          currentDriverRef.set("timedout");
          timer.cancel();
          currentDriverRef.onDisconnect();
          requestTimeoutDriver = 20;

          searchDriver();

        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {

    makeDriverNearbyCarIcon();

    return Scaffold(
      key: sKey,
      drawer: Container(
        width: 255,
        color: Colors.black87,
        child: Drawer(
          backgroundColor: Colors.white10,
          child: ListView(
            children: [

              const Divider(
                height: 1,
                color: Colors.white,
                thickness: 1,
              ),

              Container(
                color: Colors.black,
                height: 160,
                child: 
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: Row(
                    children: [

                      Image.asset(
                        "assets/images/avatarman.png",
                        width: 80,
                        height: 80,
                      ),
                      // const Icon(
                      //   Icons.person,
                      //   size: 60,
                      // ),

                      const SizedBox(width: 25),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 15),

                          const Text(
                            "Profile",
                            style: TextStyle(
                              color: Colors.white10,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              const Divider(
                height: 1,
                color: Colors.white,
                thickness: 1,
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const TripsHistoryPage()));
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: ()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => const TripsHistoryPage()));
                    },
                    icon: const Icon(Icons.history, color: Colors.grey,),
                  ),
                  title: const Text("History",style: TextStyle(color:Colors.grey)),
                ),
              ),

              GestureDetector(
                onTap: ()
                {
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const AboutPage()));
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: ()
                    {
                      Navigator.push(context, MaterialPageRoute(builder: (c) => const AboutPage()));
                    },
                    icon: const Icon(Icons.info, color: Colors.grey,),
                  ),
                  title: const Text("About",style: TextStyle(color:Colors.grey)),
                ),
              ),

              GestureDetector(
                onTap: ()
                {
                  FirebaseAuth.instance.signOut();
                  Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen())); 
                },
                child: ListTile(
                  leading: IconButton(
                    onPressed: ()
                    { 
                      FirebaseAuth.instance.signOut();
                      Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen()));           
                    },
                    icon: const Icon(Icons.logout, color: Colors.grey,),
                  ),
                  title: const Text("Logout",style: TextStyle(color:Colors.grey)),
                ),
              ),

            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(top: 44, bottom: bottomMapPadding),
            mapType: MapType.normal,
            myLocationEnabled: true,
            polylines: polylineSet,
            markers: markerSet,
            circles: circleSet,
            initialCameraPosition: googlePlexInitialPosition,
            onMapCreated: (GoogleMapController mapController)
            {
              controllerGoogleMap = mapController;
              updateMapTheme(controllerGoogleMap!);
              googleMapCompletterController.complete(controllerGoogleMap);

              setState(() 
              {
                bottomMapPadding = 120;
              }
              );
              getCurrentLiveLocationOfUser();
            },
          ),

          Positioned(
            top: 55,
            left: 19,
            child: GestureDetector(
              onTap: ()
              {
                if(isDrawerOpened == true)
                {
                  sKey.currentState!.openDrawer();
                }
                else
                {
                  resetAppNow();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const 
                  [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 5,
                      spreadRadius: 0.5,
                      offset: Offset(0.7, 0.7)
                    )
                  ]
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey,
                  radius: 20,
                  child: Icon(
                    isDrawerOpened == true ? Icons.menu : Icons.close,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),

        Positioned(
          left: 0,
          right: 0,
          bottom: -80,
          child: Container(
           height: searchContainerHeight,
           child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(
                onPressed:() async
                {
                  var responseFromSearchPage = await Navigator.push(context, MaterialPageRoute(builder: (c) => const SearchDestinationPage()));

                  if(responseFromSearchPage == "placeSelected")
                      {
                       displayUserRideDetailsContainer();
                      }
                      
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(24),
                ),
                child:const Icon(
                  Icons.search,
                  color: Colors.white,
                  size: 25
                  )
                  ),
                ElevatedButton(
                  onPressed:()
                  {

                  },
                  style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.grey,
                   shape: const CircleBorder(),
                   padding: const EdgeInsets.all(24),
                  ),
                child:const Icon(
                  Icons.home,
                  color: Colors.white,
                  size: 25
                  )
                  ),
                ElevatedButton(
                  onPressed:() 
                  {

                  },
                  style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.grey,
                   shape: const CircleBorder(),
                   padding: const EdgeInsets.all(24),
                  ),
                child:const Icon(
                  Icons.work,
                  color: Colors.white,
                  size: 25
                  )
                  )
            ],

          ),

        ),
      ),

        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: rideDetailsContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
                boxShadow:
                [
                  BoxShadow(
                    color: Colors.white12,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(.7, .7),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: SizedBox(
                        height: 190,
                        child: Card(
                          elevation: 10,
                          child: Container(
                            width: MediaQuery.of(context).size.width * .75,
                            color: Colors.black45,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   Padding(
                                     padding: const EdgeInsets.only(left: 8, right: 8),
                                     child: Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text(
                                           (tripDirectionDetailsInfo != null) ? tripDirectionDetailsInfo!.distanceTextString! : "",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white70,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),

                                         Text(
                                           (tripDirectionDetailsInfo != null) ? tripDirectionDetailsInfo!.durationTextString! : "",
                                           style: const TextStyle(
                                             fontSize: 16,
                                             color: Colors.white70,
                                             fontWeight: FontWeight.bold,
                                           ),
                                         ),
                                       ],
                                     ),
                                   ),

                                  GestureDetector(
                                    onTap: ()
                                    {
                                      setState(() 
                                      {
                                        stateOfApp = "requesting";
                                      }
                                      );

                                      displayRequestContainer();

                                      availableNearbyOnlineDriversList = ManageDriversMethods.nearbyOnlineDriversList;

                                      searchDriver();

                                    },
                                    child: Image.asset(
                                      "assets/images/uberexec.png",
                                      height: 122,
                                      width: 122,
                                    ),
                                  ),

                                  Text(
                                    (tripDirectionDetailsInfo != null) ? "\$ ${(cMethods.calculateFareAmount(tripDirectionDetailsInfo!)).toString()}" : "",
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: requestContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                boxShadow:
                [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    const SizedBox(height: 12,),

                    SizedBox(
                      width: 200,
                      child: LoadingAnimationWidget.flickr(
                        leftDotColor: Colors.greenAccent,
                        rightDotColor: Colors.pinkAccent,
                        size: 50,
                      ),
                    ),

                    const SizedBox(height: 20,),

                    GestureDetector(
                      onTap: ()
                      {
                        resetAppNow();
                        cancelRideRequest();
                      },
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(width: 1.5, color: Colors.grey),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black,
                          size: 25,
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: tripContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                boxShadow:
                [
                  BoxShadow(
                    color: Colors.white24,
                    blurRadius: 15.0,
                    spreadRadius: 0.5,
                    offset: Offset(
                      0.7,
                      0.7,
                    ),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 5,),

                    //trip status display text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tripStatusDisplay,
                          style: const TextStyle(fontSize: 19, color: Colors.grey,),
                        ),
                      ],
                    ),

                    const SizedBox(height: 19,),

                    const Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),

                    const SizedBox(height: 19,),

                    //image - driver name and driver car details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        ClipOval(
                          child: Image.network(
                            photoDriver == ''
                                ? "https://firebasestorage.googleapis.com/v0/b/quickcab-b8b8a.appspot.com/o/avatarman.png?alt=media&token=70b8d362-e7e0-4bd2-a236-66011dc87e51"
                                : photoDriver,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(width: 8,),

                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(nameDriver, style: const TextStyle(fontSize: 20, color: Colors.grey,),),

                            Text(carDetailsDriver, style: const TextStyle(fontSize: 14, color: Colors.grey,),),

                          ],
                        ),

                      ],
                    ),

                    const SizedBox(height: 19,),

                    const Divider(
                      height: 1,
                      color: Colors.white70,
                      thickness: 1,
                    ),

                    const SizedBox(height: 19,),

                    //call driver btn
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        GestureDetector(
                          onTap: ()
                          {
                            launchUrl(Uri.parse("tel://$phoneNumberDriver"));
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              Container(
                                height: 50,
                                width: 50,
                                decoration: BoxDecoration(
                                  borderRadius: const BorderRadius.all(Radius.circular(25)),
                                  border: Border.all(
                                    width: 1,
                                    color: Colors.white,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.phone,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 11,),

                              const Text("Call", style: TextStyle(color: Colors.grey,),),

                            ],
                          ),
                        ),

                      ],
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      )
    );
  }
}