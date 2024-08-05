import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StepCounterPage extends StatefulWidget {
  @override
  _StepCounterPageState createState() => _StepCounterPageState();
}

class AccelerometerData {
  final int time;
  final double x;
  final double y;
  final double z;

  AccelerometerData(this.time, this.x, this.y, this.z);
}

class _StepCounterPageState extends State<StepCounterPage> {
  String _motionState = 'Not Moving';
  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  List<AccelerometerData> _chartData = [];
  double _walkingThreshold = 12.0;
  double _runningThreshold = 20.0;
  late Timer _timer;
  DateTime? _lastNotificationTime;
  static const _notificationCooldown = Duration(seconds: 5);

  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _startListeningToAccelerometer();
    _timer = Timer.periodic(Duration(seconds: 1), _updateChart);
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _timer.cancel();
    super.dispose();
  }

  void _startListeningToAccelerometer() {
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      _detectMotion(event);
    });
  }

  void _detectMotion(AccelerometerEvent event) {
    double magnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    String newState;

    if (magnitude > _runningThreshold) {
      newState = 'Running';
    } else if (magnitude > _walkingThreshold) {
      newState = 'Walking';
    } else {
      newState = 'Not Moving';
    }

    if (newState != _motionState) {
      setState(() {
        _motionState = newState;
        _chartData.add(AccelerometerData(
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
            event.x,
            event.y,
            event.z));
        if (_chartData.length > 20) {
          _chartData.removeAt(0);
        }
      });
      _triggerNotification();
    }
  }

  void _updateChart(Timer timer) {
    setState(() {});
  }

  void _triggerNotification() async {
    DateTime now = DateTime.now();
    if (_lastNotificationTime == null ||
        now.difference(_lastNotificationTime!) > _notificationCooldown) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'MotionDetection_channel',
        'MotionDetection Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0,
        'Motion Update',
        'You are now $_motionState',
        platformChannelSpecifics,
      );
      print(
          'Motion state changed! Alerting user... Current state: $_motionState');
      _lastNotificationTime = now;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> accelerometer = _chartData.isNotEmpty
        ? [
            _chartData.last.x.toStringAsFixed(1),
            _chartData.last.y.toStringAsFixed(1),
            _chartData.last.z.toStringAsFixed(1)
          ]
        : ['0.0', '0.0', '0.0'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Motion Detection'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              _getIconForMotionState(),
              size: 100,
              color: _getColorForMotionState(),
            ),
            SizedBox(height: 20),
            Text(
              'Accelerometer (X, Y, Z):',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              '${accelerometer.join(', ')}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Current State: $_motionState',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Walking Threshold: ${_walkingThreshold.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 16),
            ),
            Slider(
              value: _walkingThreshold,
              min: 5.0,
              max: 30.0,
              divisions: 50,
              label: _walkingThreshold.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  _walkingThreshold = value;
                  if (_walkingThreshold >= _runningThreshold) {
                    _runningThreshold = _walkingThreshold + 1;
                  }
                });
              },
            ),
            Text(
              'Running Threshold: ${_runningThreshold.toStringAsFixed(1)}',
              style: TextStyle(fontSize: 16),
            ),
            Slider(
              value: _runningThreshold,
              min: 10.0,
              max: 40.0,
              divisions: 60,
              label: _runningThreshold.toStringAsFixed(1),
              onChanged: (double value) {
                setState(() {
                  _runningThreshold = value;
                  if (_runningThreshold <= _walkingThreshold) {
                    _walkingThreshold = _runningThreshold - 1;
                  }
                });
              },
            ),
            SizedBox(height: 20),
            Expanded(
              child: SfCartesianChart(
                primaryXAxis: NumericAxis(
                  title: AxisTitle(text: 'Time (s)'),
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Acceleration'),
                ),
                title: ChartTitle(text: 'Accelerometer Data'),
                legend: Legend(isVisible: true),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: <LineSeries<AccelerometerData, int>>[
                  LineSeries<AccelerometerData, int>(
                    dataSource: _chartData,
                    xValueMapper: (AccelerometerData data, _) => data.time,
                    yValueMapper: (AccelerometerData data, _) => data.x,
                    name: 'X Axis',
                  ),
                  LineSeries<AccelerometerData, int>(
                    dataSource: _chartData,
                    xValueMapper: (AccelerometerData data, _) => data.time,
                    yValueMapper: (AccelerometerData data, _) => data.y,
                    name: 'Y Axis',
                  ),
                  LineSeries<AccelerometerData, int>(
                    dataSource: _chartData,
                    xValueMapper: (AccelerometerData data, _) => data.time,
                    yValueMapper: (AccelerometerData data, _) => data.z,
                    name: 'Z Axis',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMotionState() {
    switch (_motionState) {
      case 'Walking':
        return Icons.directions_walk;
      case 'Running':
        return Icons.directions_run;
      default:
        return Icons.accessibility_new;
    }
  }

  Color _getColorForMotionState() {
    switch (_motionState) {
      case 'Walking':
        return Colors.green;
      case 'Running':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
