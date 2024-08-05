import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:sensormobileapplication/main.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Location _locationController = Location();
  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  LatLng _kigaliCenter = LatLng(-1.9441, 30.0619);
  LatLng? _currentP;
  Map<PolylineId, Polyline> polylines = {};
  Map<PolygonId, Polygon> _polygons = {};
  StreamSubscription<LocationData>? _locationSubscription;
  bool _notificationSentOutSide = false;
  bool _notificationSentInSide = false;
  bool _isInsideGeofence = false;

  @override
  void initState() {
    super.initState();
    getLocationUpdates().then((_) => _createGeofence());
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text('Location Tracker', style: TextStyle(color: Colors.white)),
        elevation: 0,
      ),
      body: Stack(
        children: [
          _currentP == null
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  onMapCreated: ((GoogleMapController controller) =>
                      _mapController.complete(controller)),
                  initialCameraPosition:
                      CameraPosition(target: _kigaliCenter, zoom: 13),
                  polygons: Set<Polygon>.of(_polygons.values),
                  markers: {
                    if (_currentP != null)
                      Marker(
                        markerId: MarkerId("_currentLocation"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueAzure),
                        position: _currentP!,
                        infoWindow: InfoWindow(title: "Current Location"),
                      ),
                  },
                  polylines: Set<Polyline>.of(polylines.values),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                ),
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isInsideGeofence ? "Inside Kigali" : "Outside Kigali",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isInsideGeofence ? Colors.green : Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _isInsideGeofence
                          ? "You are within the geographical boundaries of Kigali."
                          : "You have left the geographical boundaries of Kigali.",
                      style: TextStyle(fontSize: 14),
                    ),
                    if (_currentP != null) ...[
                      SizedBox(height: 8),
                      Text(
                        "Current Location:",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Lat: ${_currentP!.latitude.toStringAsFixed(4)}, Lng: ${_currentP!.longitude.toStringAsFixed(4)}",
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _cameraToPosition(_currentP ?? _kigaliCenter),
        child: Icon(Icons.my_location),
        backgroundColor: theme.primaryColor,
      ),
    );
  }

  void _triggerInSideNotification() async {
    if (!_notificationSentInSide) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'Map_channel',
        'Map Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Welcome to Kigali!',
        'You have entered the geographical boundaries of Kigali. Enjoy your stay!',
        platformChannelSpecifics,
      );
      setState(() {
        _notificationSentInSide = true;
        _notificationSentOutSide = false;
        _isInsideGeofence = true;
      });
    }
  }

  void _triggerOutSideNotification() async {
    if (!_notificationSentOutSide) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'Map_channel',
        'Map Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Leaving Kigali',
        'You have left the geographical boundaries of Kigali. Safe travels!',
        platformChannelSpecifics,
      );
      setState(() {
        _notificationSentOutSide = true;
        _notificationSentInSide = false;
        _isInsideGeofence = false;
      });
    }
  }

  void _createGeofence() {
    List<LatLng> kigaliBoundaries = [
      LatLng(-1.9740, 30.0274),
      LatLng(-1.9740, 30.1300),
      LatLng(-1.8980, 30.1300),
      LatLng(-1.8980, 30.0274),
    ];

    PolygonId polygonId = PolygonId('kigali');
    Polygon polygon = Polygon(
      polygonId: polygonId,
      points: kigaliBoundaries,
      strokeWidth: 2,
      strokeColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.1),
    );

    setState(() {
      _polygons[polygonId] = polygon;
    });

    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _locationSubscription = _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      bool insideGeofence = _isLocationInsideGeofence(
          currentLocation.latitude!, currentLocation.longitude!);

      setState(() {
        _currentP =
            LatLng(currentLocation.latitude!, currentLocation.longitude!);
        _isInsideGeofence = insideGeofence;
      });

      if (insideGeofence && !_notificationSentInSide) {
        _triggerInSideNotification();
      } else if (!insideGeofence && !_notificationSentOutSide) {
        _triggerOutSideNotification();
      }

      _cameraToPosition(_currentP!);
    });
  }

  bool _isLocationInsideGeofence(double latitude, double longitude) {
    // Check if the provided location is inside the geofence boundaries
    bool isInside = false;
    List<LatLng> kigaliBoundaries = [
      LatLng(-1.9740, 30.0274),
      LatLng(-1.9740, 30.1300),
      LatLng(-1.8980, 30.1300),
      LatLng(-1.8980, 30.0274),
    ];

    // Algorithm to determine if a point is inside a polygon
    int i, j = kigaliBoundaries.length - 1;
    for (i = 0; i < kigaliBoundaries.length; i++) {
      if ((kigaliBoundaries[i].latitude < latitude &&
                  kigaliBoundaries[j].latitude >= latitude ||
              kigaliBoundaries[j].latitude < latitude &&
                  kigaliBoundaries[i].latitude >= latitude) &&
          (kigaliBoundaries[i].longitude <= longitude ||
              kigaliBoundaries[j].longitude <= longitude)) {
        if (kigaliBoundaries[i].longitude +
                (latitude - kigaliBoundaries[i].latitude) /
                    (kigaliBoundaries[j].latitude -
                        kigaliBoundaries[i].latitude) *
                    (kigaliBoundaries[j].longitude -
                        kigaliBoundaries[i].longitude) <
            longitude) {
          isInside = !isInside;
        }
      }
      j = i;
    }
    return isInside;
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPosition = CameraPosition(target: pos, zoom: 15);
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(_newCameraPosition));
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });
      }
    });
  }
}
