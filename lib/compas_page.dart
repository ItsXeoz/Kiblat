import 'dart:math';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kiblat/widget/compass_custompainter.dart';

class CompasPage extends StatefulWidget {
  const CompasPage({super.key});

  @override
  State<CompasPage> createState() => _CompasPageState();
}

class _CompasPageState extends State<CompasPage> {
  Future<Position>? getPosition;
  // State to track if the compass sensor stream is available (null check)
  bool _isCompassAvailable = false;

  @override
  void initState() {
    super.initState();
    getPosition = _determinePosition();
    
    // CRITICAL FIX: Check if the compass sensor stream is null on this device.
    // If null, it means the hardware is missing, and we must not subscribe to the stream.
    try {
      if (FlutterCompass.events != null) {
        _isCompassAvailable = true;
      }
    } catch (e) {
      // Added try-catch to handle potential native exceptions when checking availability
      _isCompassAvailable = false;
      debugPrint("Error checking compass availability: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Qibla Finder App',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
      ),
      body: Container(
        color: Colors.blueGrey[800],
        child: SafeArea(
          child: FutureBuilder<Position>(
            future: getPosition,
            builder: (context, snapshot) {
              
              // 🛠️ FIX 1: Handle Errors from _determinePosition (Location failures)
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Text(
                      'Location Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent, 
                        fontSize: 16
                      ),
                    ),
                  ),
                );
              }
              
              if (snapshot.hasData) {
                Position positionResult = snapshot.data!;
                Coordinates coordinates = Coordinates(
                  positionResult.latitude,
                  positionResult.longitude,
                );
                double qiblaDirection = Qibla.qibla(coordinates);

                // 🛠️ FIX 2: Guard against missing compass sensor
                if (!_isCompassAvailable) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        "Error: Device does not have a working compass sensor (magnetometer). This is common on emulators or aggressive Android versions like MIUI. Please test on a different physical device.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.yellowAccent,
                          fontSize: 16
                        ),
                      ),
                    ),
                  );
                }

                // 2. Only run StreamBuilder if compass is available
                return StreamBuilder<CompassEvent>(
                  stream: FlutterCompass.events,
                  builder: (context, snapshot) {
                    // Handle sensor stream error (e.g., momentary sensor failure)
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Sensor stream error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    // Handle connection waiting state
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    // 3. Get the direction
                    double? direction = snapshot.data?.heading;

                    if (direction == null) {
                      return const Center(
                        child: Text(
                          "Waiting for sensor data...",
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    // The rest of your Column code remains the same
                    return Column(
                      children: [
                        // Display Current Location Info
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Lat: ${positionResult.latitude.toStringAsFixed(3)}, Lon: ${positionResult.longitude.toStringAsFixed(3)}\nQibla Angle: ${qiblaDirection.toStringAsFixed(1)}°',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Compass Face (CustomPainter)
                              CustomPaint(
                                size: size,
                                painter: CompassCustomPainter(angle: direction),
                              ),
                              
                              // Qibla (Kaaba Image)
                              Transform.rotate(
                                angle: -2 * pi * (direction / 360),
                                child: Transform(
                                  alignment: FractionalOffset.center,
                                  transform: Matrix4.rotationZ(
                                    qiblaDirection * pi / 180,
                                  ),
                                  origin: Offset.zero,
                                  child: Image.asset(
                                    // NOTE: Ensure 'images/kaaba.png' is in your assets folder
                                    'assets/kaaba.png', 
                                    width: 112,
                                  ),
                                ),
                              ),
                              
                              // Qibla Direction Indicator (Arrow)
                              CircleAvatar(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.transparent,
                                radius: 140,
                                child: Transform.rotate(
                                  angle: -2 * pi * (direction / 360),
                                  child: Transform(
                                    alignment: FractionalOffset.center,
                                    transform: Matrix4.rotationZ(
                                      qiblaDirection * pi / 180,
                                    ),
                                    origin: Offset.zero,
                                    child: const Align(
                                      alignment: Alignment.topCenter,
                                      child: Icon(
                                        Icons.expand_less_outlined,
                                        color: Colors.greenAccent, // Green arrow for Qibla
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Current Heading Text
                              Align(
                                alignment: const Alignment(0, 0.45),
                                child: Text(
                                  showHeading(direction, qiblaDirection),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              }
              
              // Default loading spinner while waiting for location
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
          ),
        ),
      ),
    );
  }
}

Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled. Please enable GPS.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied. Please grant permission.');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
        'Location permissions are permanently denied. Go to settings to allow location access.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

String showHeading(double direction, double qiblaDirection) {
  return qiblaDirection.toInt() != direction.toInt()
      ? '${direction.toStringAsFixed(0)}°'
      : "You're facing Makkah!";
}
