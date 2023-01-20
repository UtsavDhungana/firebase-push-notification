import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:notification_app/getFcm.dart';
import 'package:notification_app/second_screen.dart';
import 'package:http/http.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBankgroundHandler);

  runApp(const MyApp());
}

Future _showNotification(RemoteMessage message) async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', //id,
    'High Importance Notifications', //title
    description:
        'This channel is used for important notifications.', //description
    importance: Importance.max,
    playSound: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  log(message.toString());
  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;
  Map<String, dynamic> dataValue = message.data;
  BigPictureStyleInformation? bigPictureStyleInformation;
  AndroidBitmap<Object>? largeIcon;
  if (notification != null) {
    String screen = dataValue['screen'].toString();
    log('Data: ${message.data.toString()}');
    log('Image URL: ${message.notification?.android?.imageUrl.toString()}');
    if (android != null && android.imageUrl != null) {
      Response response = await get(
        Uri.parse(message.notification!.android!.imageUrl.toString()),
      );
      bigPictureStyleInformation = BigPictureStyleInformation(
        ByteArrayAndroidBitmap.fromBase64String(
          base64Encode(response.bodyBytes),
        ),
      );
      largeIcon = ByteArrayAndroidBitmap.fromBase64String(
        base64Encode(response.bodyBytes),
      );
    }

    flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          color: Colors.blue,
          playSound: true,
          icon: '@mipmap/marvel_notification_icon',
          largeIcon: largeIcon,
          styleInformation: bigPictureStyleInformation,
        ),
      ),
      payload: screen,
    );
  } else {
    log('IN Else');
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBankgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  final Widget? screen;
  const MyApp({this.screen, Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: screen ?? const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    getNotificationPermission();
    getToken();

    handleMessageOnBackground();

    var initializationSettingsAndroid =
        const AndroidInitializationSettings('@mipmap/marvel_notification_icon');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log('listening to message');
      _showNotification(message);
    });

    //when app is in background but not terminated.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      log('on Message Opened App');
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        log('opened onmessageopen: ${message.data}');
        if (message.data['screen'] == 'secondScreen') {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SecondScreen(),
            ),
          );
        } else {
          log('in onMessageOpenedApp else section');
        }
      }
    });
  }

  void handleMessageOnBackground() {
    FirebaseMessaging.instance.getInitialMessage().then(
      (remoteMessage) {
        log('on handleMessageOnBackground');
        if (remoteMessage != null) {
          if (remoteMessage.data['screen'] == 'secondScreen') {
            Future.delayed(const Duration(milliseconds: 1000), () async {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SecondScreen(),
                ),
              );
            });
          } else {
            log('in onMessageOpenedApp else section');
          }
        }
      },
    );
  }

  void getNotificationPermission() async {
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    log('User granted permission: ${settings.authorizationStatus}');

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  getToken() async {
    await FirebaseMessaging.instance.getToken();
  }

  Future<dynamic> onNotificationTap(NotificationResponse response) async {
    log('On Notification Tap: ${response.payload}');
    if (response.payload == 'secondScreen') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SecondScreen(),
        ),
      );
    } else {
      log('in On tap else');
    }
  }

  @pragma('vm:entry-point')
  Future<dynamic> onBackGroundNotificationTap(
      NotificationResponse response) async {
    log('On Notification Tap: ${response.payload}');
    if (response.payload == 'secondScreen') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const SecondScreen(),
        ),
      );
    } else {
      log('in On tap else');
    }
  }

  void showNotification() async {
    setState(() {
      _counter++;
    });
    _showNotification(
      RemoteMessage(
        notification: RemoteNotification(
          title: 'Texting $_counter',
          body: 'Notifying the user.',
        ),
      ),
    );
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
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showNotification,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
