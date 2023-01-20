import 'dart:developer';
import 'dart:html';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:rxdart/rxdart.dart';

import '../second_screen.dart';

class NotificationService {
  NotificationService();

  final _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  final BehaviorSubject<String> behaviorSubject = BehaviorSubject();

  Future<void> initializePlatformNotifications() async {
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

//   Future<NotificationDetails> _notificationDetails() async {
//     final bigPicture = await DownloadUtil.downloadAndSaveFile(
//         "https://images.unsplash.com/photo-1624948465027-6f9b51067557?ixlib=rb-1.2.1&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1470&q=80",
//         "drinkwater");

//     AndroidNotificationDetails androidPlatformChannelSpecifics =
//         AndroidNotificationDetails(
//       'channel id',
//       'channel name',
//       groupKey: 'com.example.flutter_push_notifications',
//       channelDescription: 'channel description',
//       importance: Importance.max,
//       priority: Priority.max,
//       playSound: true,
//       ticker: 'ticker',
//       largeIcon: const DrawableResourceAndroidBitmap('justwater'),
//       styleInformation: BigPictureStyleInformation(
//         FilePathAndroidBitmap(bigPicture),
//         hideExpandedLargeIcon: false,
//       ),
//       color: const Color(0xff2196f3),
//     );
//   }
}
