import 'dart:convert';
import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:notification_app/services/my_stream.dart';

class NotificationService {
  NotificationService();

  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final myStream = MyStream();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initializePlatformNotifications() async {
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
      _showNotification(message);
    });

    //when app is in background but not terminated.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        if (message.data['screen'] == 'secondScreen') {
          myStream.addString(message.data['screen']);
        } else {}
      }
    });
  }

  Future<dynamic> onNotificationTap(NotificationResponse response) async {
    if (response.payload == 'secondScreen') {
      myStream.addString(response.payload!);
    } else {}
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

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  getToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
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
    } else {}
  }

  void handleMessageOnBackground() {
    FirebaseMessaging.instance.getInitialMessage().then(
      (remoteMessage) {
        if (remoteMessage != null) {
          if (remoteMessage.data['screen'] == 'secondScreen') {
            Future.delayed(const Duration(milliseconds: 1000), () async {
              // behaviorSubject.add(remoteMessage.data['screen']);
              myStream.addString(remoteMessage.data['screen']);
            });
          } else {}
        }
      },
    );
  }
}
