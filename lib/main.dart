import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' as flutterWidgets;

import 'dart:async';
import 'dart:convert';
import 'package:grpc/grpc.dart';
import 'package:toit_api/toit/api/pubsub/publish.pbgrpc.dart'
    show PublishClient, PublishRequest;
import 'package:toit_api/toit/api/device.pbgrpc.dart';
import 'package:toit_api/toit/model/device.pb.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class ToitServer {
  static final ClientChannel _channel = ClientChannel("api.toit.io");
  static const String _authorizationToken = PUT YOUR TOIT AUTHORIZATION TOKEN HERE;
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

class MyApp extends StatefulWidget {
  // Create the initialization Future outside of `build`.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        // Initialize FlutterFire:
        future: _initialization,
        builder: (context, snapshot) {
          // Check for errors.
          if (snapshot.hasError) {
            return const MaterialApp(
              title: "Bell",
              home: ErrorPage(),
            );
          }

          if (snapshot.connectionState == flutterWidgets.ConnectionState.done) {
            return const MaterialApp(
              title: "Bell",
              home: MyHomePage(title: 'Bell'),
            );
          }

          return MaterialApp(
              title: "Bell",
              home: Scaffold(
                  appBar: AppBar(
                    title: const Text("Waiting for init"),
                  ),
                  body: const CircularProgressIndicator()));
        });
  }
}

class ErrorPage extends StatelessWidget {
  const ErrorPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Something went wrong"),
      ),
      body: const Text("Something went wrong during initialization"),
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
  late Future<NotificationSettings> _notificationSettings;
  DateTime? _lastBell;

  @override
  void initState() {
    super.initState();
    _connectedFuture = ToitServer.getConnectedStatus();
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    _notificationSettings = messaging.requestPermission();
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
            if (_lastBell != null) Text("Last bell at $_lastBell"),
            FutureBuilder<NotificationSettings>(
                future: _notificationSettings,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    var settings = snapshot.data!;
                    var status = settings.authorizationStatus;
                    switch (status) {
                      case AuthorizationStatus.provisional:
                      case AuthorizationStatus.authorized:
                        print(status);
                        FirebaseMessaging.instance.getToken().then((token) {
                          print(token);
                        });
                        // We don't need to set up the background notification
                        // handler, as a notification will be show
                        // automatically.
                        FirebaseMessaging.onMessage.listen((_) {
                          setState(() {
                            _lastBell = DateTime.now();
                          });
                        });
                        return const Text("Receiving notifications");
                      default:
                        return const Text("Not receiving notifications");
                    }
                  } else if (snapshot.hasError) {
                    return Text("$snapshot.error}");
                  }
                  return const CircularProgressIndicator();
                }),
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
