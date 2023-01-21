import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';

import 'package:rxdart/rxdart.dart';

class NotificationService {
  NotificationService();

  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<String> behaviorSubject = BehaviorSubject();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initializePlatformNotifications() async {
    log('hereeeeeeeeeee');
    getNotificationPermission();
    getToken();

    handleMessageOnBackground();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/marvel_notification_icon');

    final DarwinInitializationSettings iosInitializationSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: onDidReceiveLocalNotification,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: iosInitializationSettings,
    );

    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      // onDidReceiveBackgroundNotificationResponse: onBackGroundNotificationTap,
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
          behaviorSubject.add(message.data['screen']);
          // Navigator.of(context).push(
          //   MaterialPageRoute(
          //     builder: (context) => const SecondScreen(),
          //   ),
          // );
        } else {
          log('in onMessageOpenedApp else section');
        }
      }
    });
  }

  Future<dynamic> onNotificationTap(NotificationResponse response) async {
    log('On Notification Tap: ${response.payload}');
    if (response.payload == 'secondScreen') {
      behaviorSubject.add(response.payload!);
      // runApp(const MyApp(screen: SecondScreen()));
      // Navigator.of(context).push(
      //   MaterialPageRoute(
      //     builder: (context) => const SecondScreen(),
      //   ),
      // );
    } else {
      log('in On tap else');
    }
  }

  void onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    print('id $id');
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
    String? token = await FirebaseMessaging.instance.getToken();
    log(token!);
    return token;
  }

  Future _showNotification(RemoteMessage message) async {
    AndroidNotificationChannel androidPlatformChannelSpecifics =
        const AndroidNotificationChannel(
      'channel id',
      'channel name',
      description: 'channel description',
      importance: Importance.max,
      playSound: true,
    );

    DarwinNotificationDetails iosNotificationDetails =
        const DarwinNotificationDetails(
      threadIdentifier: "thread1",
      //   attachments: <DarwinNotificationAttachment>[
      // IOSNotificationAttachment(bigPicture)
      // ]
    );

    // final details = await _flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    // if (details != null && details.didNotificationLaunchApp) {
    //   behaviorSubject.add(details.payload!);
    // }

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidPlatformChannelSpecifics);

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

      _flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            androidPlatformChannelSpecifics.id,
            androidPlatformChannelSpecifics.name,
            channelDescription: androidPlatformChannelSpecifics.description,
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

  void handleMessageOnBackground() {
    FirebaseMessaging.instance.getInitialMessage().then(
      (remoteMessage) {
        log('on handleMessageOnBackground');
        if (remoteMessage != null) {
          if (remoteMessage.data['screen'] == 'secondScreen') {
            Future.delayed(const Duration(milliseconds: 1000), () async {
              behaviorSubject.add(remoteMessage.data['screen']);
              // Navigator.of(context).push(
              //   MaterialPageRoute(
              //     builder: (context) => const SecondScreen(),
              //   ),
              // );
            });
          } else {
            log('in onMessageOpenedApp else section');
          }
        }
      },
    );
  }
}
