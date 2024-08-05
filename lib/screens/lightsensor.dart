import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:light_sensor/light_sensor.dart'; // Use the correct package name for light sensor

class LightSensorScreen extends StatefulWidget {
  @override
  _LightSensorScreenState createState() => _LightSensorScreenState();
}

class _LightSensorScreenState extends State<LightSensorScreen> {
  String _luxString = 'Unknown';
  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  late StreamSubscription<int> _lightSubscription;
  int? previousLuxValue;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _startListeningToLightSensor();
  }

  @override
  void dispose() {
    _lightSubscription.cancel();
    super.dispose();
  }

  void _initializeNotifications() {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _startListeningToLightSensor() {
    LightSensor.hasSensor().then((hasSensor) {
      if (hasSensor) {
        _lightSubscription = LightSensor.luxStream().listen((int luxValue) {
          setState(() {
            _luxString = "$luxValue";
            _handleLuxChanges(luxValue);
          });
        });
      } else {
        print("Device does not have a light sensor");
      }
    }).catchError((e) {
      print("Error checking for light sensor: $e");
    });
  }

  void _handleLuxChanges(int luxValue) {
    if (previousLuxValue != null) {
      if (luxValue > previousLuxValue!) {
        _sendNotification(
          'Light Level Increase',
          'The ambient light level has increased to ${luxValue} lux.',
        );
      } else if (luxValue < previousLuxValue!) {
        _sendNotification(
          'Light Level Decrease',
          'The ambient light level has decreased to ${luxValue} lux.',
        );
      }
    }

    previousLuxValue = luxValue;

    // Automation based on light level
    if (luxValue >= 40000) {
      _showPopup('High Light Intensity',
          '🌟 Wow! The ambient light is at its peak! 🌟\nCurrent light level: ${luxValue.toStringAsFixed(2)} lux.');
      _sendNotification('High Light Intensity',
          '🌟 Wow! The ambient light is at its peak! 🌟\nCurrent light level: ${luxValue.toStringAsFixed(2)} lux.');
    } else if (luxValue == 0) {
      _showPopup('Low Light Intensity',
          '🔆 The room is as bright as it gets! 🔆\nCurrent light level: ${luxValue.toStringAsFixed(2)} lux.');
      _sendNotification('Low Light Intensity',
          '🔆 The room is as bright as it gets! 🔆\nCurrent light level: ${luxValue.toStringAsFixed(2)} lux.');
    }
  }

  void _sendNotification(String title, String message) async {
    const androidDetails = AndroidNotificationDetails(
      'channelId',
      'channelName',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const notificationDetails = NotificationDetails(android: androidDetails);
    await _flutterLocalNotificationsPlugin.show(
        0, title, message, notificationDetails);
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double luxValue = double.tryParse(_luxString) ?? 0;
    double opacity = 1 - (luxValue / 40000);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Light Sensor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.lightbulb, size: 100, color: Colors.amber),
            SizedBox(height: 20),
            Text(
              'Lux value:',
              style: TextStyle(fontSize: 24),
            ),
            Text(
              _luxString,
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            // Display a visual representation based on lux value
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(opacity),
                boxShadow: [
                  BoxShadow(
                    color: Colors.yellow.withOpacity(opacity),
                    blurRadius: 20,
                    spreadRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Image.asset(
                  'lib/assets/light-bulb.png',
                  width: 200,
                  height: 200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
