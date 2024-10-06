import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:speed_test_dart/classes/server.dart';
import 'package:speed_test_dart/speed_test_dart.dart';
import 'package:geolocator/geolocator.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      home: const WifiInfoScreen(),
    );
  }
}

class WifiInfoScreen extends StatefulWidget {
  const WifiInfoScreen({super.key});

  @override
  _WifiInfoScreenState createState() => _WifiInfoScreenState();
}

class _WifiInfoScreenState extends State<WifiInfoScreen> {
  static const platform = MethodChannel('wifiInfo');
  String wifiName = 'Unknown';
  String wifiSignalStrength = 'Unknown';
  String wifiLevel = 'Unknown';
  String downloadSpeed = 'Testing...';
  String uploadSpeed = 'Testing...';
  String statusMessage = 'Fetching servers...'; // Default status message

  Timer? _wifiInfoTimer;
  Timer? _speedTestTimer;
  SpeedTestDart tester = SpeedTestDart(); // SpeedTestDart instance
  List<Server> bestServersList = []; // Store the best servers

  @override
  void initState() {
    super.initState();
    checkPermissions();

    // Periodically fetch Wi-Fi info every 1 second
    _wifiInfoTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _getWifiInfo();
    });

    // Fetch best servers and start automated speed tests every 5 minutes
    setBestServers();
    _speedTestTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _runSpeedTest();
    });
  }

  Future<void> checkPermissions() async {
    // Request location permission
    if (await Permission.location.isDenied) {
      await Permission.location.request();
    }

    // Check if location services are enabled
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationServiceEnabled) {
      // Prompt user to enable location services
      await Geolocator.openLocationSettings();
    }
  }

  @override
  void dispose() {
    // Cancel timers when the widget is disposed
    _wifiInfoTimer?.cancel();
    _speedTestTimer?.cancel();
    super.dispose();
  }

  Future<void> _getWifiInfo() async {
    try {
      // Ensure that location permissions and services are enabled
      await checkPermissions();

      // Invoke the method to get Wi-Fi info
      final Map<dynamic, dynamic> result = await platform.invokeMethod('getWifiInfo');

      setState(() {
        wifiName = result['ssid'] ?? 'Unknown';
        wifiSignalStrength = '${result['rssi']} dBm';
        wifiLevel = '${result['level']} out of 100';
      });
    } on PlatformException catch (e) {
      setState(() {
        wifiName = "Failed to get Wi-Fi Info: '${e.message}'";
        wifiSignalStrength = "Failed to get Wi-Fi Signal Strength: '${e.message}'";
      });
    }
  }

  Future<void> setBestServers() async {
    try {
      setState(() {
        statusMessage = 'Fetching best servers...';
      });
      final settings = await tester.getSettings();
      final servers = settings.servers;

      final _bestServersList = await tester.getBestServers(
        servers: servers,
      );

      setState(() {
        bestServersList = _bestServersList;
        statusMessage = 'Running speed test...';
      });

      // Start the initial speed test after getting the best servers
      await _runSpeedTest();
    } catch (e) {
      setState(() {
        downloadSpeed = "Failed to get servers";
        uploadSpeed = "Failed to get servers";
        statusMessage = 'Error fetching servers';
      });
    }
  }

  Future<void> _runSpeedTest() async {
    // Ensure that status is reset before each speed test starts
    setState(() {
      downloadSpeed = 'Testing...';
      uploadSpeed = 'Testing...';
      statusMessage = 'Running speed test...'; // Reset status message
    });

    if (bestServersList.isEmpty) return;

    try {
      final downloadRate = await tester.testDownloadSpeed(
        servers: bestServersList,
      );

      final uploadRate = await tester.testUploadSpeed(
        servers: bestServersList,
      );

      setState(() {
        downloadSpeed = '${downloadRate.toStringAsFixed(2)} Mbps';
        uploadSpeed = '${uploadRate.toStringAsFixed(2)} Mbps';
        statusMessage = 'Speed test complete';
      });
    } catch (e) {
      setState(() {
        downloadSpeed = "Error testing download";
        uploadSpeed = "Error testing upload";
        statusMessage = 'Error during speed test';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: const Text('Wi-Fi Info & Speed Test'),
        backgroundColor: const Color(0xFFF8F8F8),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _buildInfoCard(
                icon: FontAwesomeIcons.wifi,
                title: 'Wi-Fi Name',
                data: wifiName,
                color: Colors.blueAccent,
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                icon: FontAwesomeIcons.signal,
                title: 'Signal Strength',
                data: wifiSignalStrength,
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                icon: FontAwesomeIcons.chartLine,
                title: 'Signal Level',
                data: wifiLevel,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                icon: FontAwesomeIcons.circleInfo,
                title: 'Status',
                data: statusMessage,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                icon: FontAwesomeIcons.download,
                title: 'Download Speed',
                data: downloadSpeed,
                color: Colors.purpleAccent,
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                icon: FontAwesomeIcons.upload,
                title: 'Upload Speed',
                data: uploadSpeed,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String data,
    required Color color,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
