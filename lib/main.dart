import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:page_transition/page_transition.dart';
import 'package:provider/provider.dart';
import 'package:sensormobileapplication/components/ThemeProvider.dart';
import 'package:sensormobileapplication/screens/StepCounter.dart';
import 'package:sensormobileapplication/screens/lightsensor.dart'; // Ensure the file exists and path is correct
import 'package:sensormobileapplication/screens/maps.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initNotifications();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const MyApp(),
    ),
  );
}

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Sensor App',
      theme: themeNotifier.currentTheme,
      home: const MyHomePage(title: 'Smart Home Monitoring'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({required this.title, Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text(
          widget.title,
          style: TextStyle(
            color: theme.scaffoldBackgroundColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon:
                Icon(Icons.brightness_6, color: theme.scaffoldBackgroundColor),
            onPressed: () => themeNotifier.toggleTheme(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildOptionCard(
                      context,
                      theme,
                      icon: FontAwesomeIcons.lightbulb,
                      label: 'Light Sensing',
                      onTap: () => Navigator.of(context).push(PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: LightSensorScreen(), // Corrected class name
                      )),
                    ),
                    _buildOptionCard(
                      context,
                      theme,
                      icon: FontAwesomeIcons.locationDot,
                      label: 'Location Tracking',
                      onTap: () => Navigator.of(context).push(PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: MapPage(),
                      )),
                    ),
                    _buildOptionCard(
                      context,
                      theme,
                      icon: FontAwesomeIcons.personRunning,
                      label: 'Motion detection',
                      onTap: () => Navigator.of(context).push(PageTransition(
                        type: PageTransitionType.rightToLeft,
                        child: StepCounterPage(),
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, ThemeData theme,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48.0, color: theme.primaryColor),
              SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
