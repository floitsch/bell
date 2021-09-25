import 'package:flutter/material.dart';

import 'dart:async';
import 'dart:convert';
import 'package:grpc/grpc.dart';
import 'package:toit_api/toit/api/pubsub/publish.pbgrpc.dart'
    show PublishClient, PublishRequest;
import 'package:toit_api/toit/api/device.pbgrpc.dart';
import 'package:toit_api/toit/model/device.pb.dart';

void main() {
  runApp(const MyApp());
}

class ToitServer {
  static final ClientChannel _channel = ClientChannel("api.toit.io");
  static const String _authorizationToken =
      "062b7d8ed744c18e133bfec0a87cd7145043ecc474097124d2ec4ac19ff94f01";
  static final CallOptions _options =
      CallOptions(metadata: {'Authorization': 'Bearer $_authorizationToken'});

  static Future<DeviceStatus> getConnectedStatus() async {
    var deviceStub = DeviceServiceClient(_channel, options: _options);
    /*
    var deviceList = (await deviceStub.listDevices(ListDevicesRequest())).devices;
    for (var device in deviceList) {
      print(device);
    }
    */
    var lookupResponse = await deviceStub
        .lookupDevices(LookupDevicesRequest(deviceName: "bell"));
    var deviceIds = lookupResponse.deviceIds;
    if (deviceIds.length != 1) {
      throw "expected only one match";
    }

    var device = (await deviceStub
            .getDevice(GetDeviceRequest(deviceId: deviceIds.first)))
        .device;
    return device.status;
  }

  static Future<void> simulateButton(String button) async {
    var publishStub = PublishClient(_channel, options: _options);
    await publishStub.publish(PublishRequest(
        topic: "cloud:bell",
        publisherName: "from flutter",
        data: [utf8.encode(button)]));
  }

  static Future<void> changeVolume() {
    return simulateButton("volume");
  }

  static Future<void> melodyUp() {
    return simulateButton("up");
  }

  static Future<void> melodyDown() {
    return simulateButton("down");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: "Bell",
      home: MyHomePage(title: 'Bell'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<DeviceStatus> _connectedFuture;
  bool sprayed = false;

  @override
  void initState() {
    super.initState();
    _connectedFuture = ToitServer.getConnectedStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<DeviceStatus>(
                future: _connectedFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var status = snapshot.data!;
                    var isAlive =
                        !status.health.connectivity.checkins.last.hasMissed();
                    if (!isAlive) return const Text("Dead");
                    var lastCheckin = status.health.connectivity.lastSeen;
                    return Text(
                        "Alive: ${DateTime.fromMillisecondsSinceEpoch(lastCheckin.seconds.toInt() * 1000)}");
                  } else if (snapshot.hasError) {
                    return Text("$snapshot.error}");
                  }
                  return const CircularProgressIndicator();
                }),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: const <Widget>[
                  OutlinedButton(
                      child: Text("Volume"),
                      onPressed: ToitServer.changeVolume,
                  ),
                  OutlinedButton(
                      child: Text("Up"),
                      onPressed: ToitServer.melodyUp,
                  ),
                  OutlinedButton(
                      child: Text("Down"),
                      onPressed: ToitServer.melodyDown,
                  )
                ]),
          ],
        ),
      ),
    );
  }
}
