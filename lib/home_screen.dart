import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final flutterReactiveBle = FlutterReactiveBle();

  @override
  void initState() {
    super.initState();
    // scanDevices(context);
  }

  scanDevices(BuildContext context) {
    flutterReactiveBle.scanForDevices(withServices: [], scanMode: ScanMode.lowLatency).listen(
      (device) {
        log("This is the devices: $device");
      },
    );
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    log("Service: $serviceEnabled");
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    log("Permission: $permission");

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () async {
                // scanDevices(context);
                final locationData = await _determinePosition();
                log("Current Position: $locationData");
              },
              child: const Text("Get Location"),
            ),
          ),
          // const SizedBox(height: 25),
          // Center(
          //   child: ElevatedButton(
          //     onPressed: () {},
          //     child: const Text("Stop devices"),
          //   ),
          // ),
        ],
      ),
    );
  }
}
