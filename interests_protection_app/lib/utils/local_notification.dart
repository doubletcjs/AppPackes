import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_apns_only/flutter_apns_only.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

import 'notification.dart';

final notification = LocalNotification();

class LocalNotification {
  // ignore: avoid_init_to_null
  static FlutterLocalNotificationsPlugin? flutterLocalNotificationsPlugin =
      null;
  // ignore: avoid_init_to_null
  late ApnsPushConnectorOnly? _connector = null;

  Future<void> unregisterApns() async {
    if (_connector != null) {
      debugPrint("移除iOS apns");
      _connector?.unregister();
      _connector?.token.removeListener(() {});
      _connector?.dispose();
      _connector = null;
    }
  }

  Future<void> registerApns() async {
    Completer _completer = Completer();
    if (_connector == null) {
      if (GetPlatform.isIOS) {
        debugPrint("注册iOS apns");
        _connector = ApnsPushConnectorOnly();
        _connector?.configureApns(
          onMessage: onMessage,
          onLaunch: onLaunch,
          onResume: onResume,
          onBackgroundMessage: onBackgroundMessage,
        );

        _connector?.token.addListener(() {
          final deviceToken = _connector?.token.value.toString();
          // 用户登录后需要将获取到的 device_token 保存到服务器
          // Sentry.captureMessage("设备 ID " + deviceToken);
          debugPrint('Token $deviceToken');

          try {
            AppHomeController _controller = Get.find<AppHomeController>();
            if (_controller.appState != AppCurrentState.init) {
              debugPrint('上传设备信息');
              String device = "ios";
              AccountApi.editUserInfo(params: {
                "device": device,
                "device_token": deviceToken,
              }, isShowErr: false)
                  .then((value) async {})
                  .catchError((error) {});
            }
          } catch (e) {}
        });

        _completer.complete();
        // if (connector is ApnsPushConnectorOnly) {
        //   final authorizationStatus = await (connector).getAuthorizationStatus();
        //   print(authorizationStatus);
        // }
      } else {
        _completer.complete();
      }
    } else {
      _completer.complete();
    }

    return _completer.future;
  }

  Future<void> init() async {
    Completer _completer = Completer();

    if (flutterLocalNotificationsPlugin == null) {
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      var android = const AndroidInitializationSettings("@mipmap/ic_launcher");
      var ios = const DarwinInitializationSettings();
      await flutterLocalNotificationsPlugin?.initialize(
          InitializationSettings(android: android, iOS: ios),
          onDidReceiveNotificationResponse: selectNotification);
      debugPrint("初始化本地通知");
    }

    _completer.complete();

    return _completer.future;
  }

  void selectNotification(NotificationResponse notificationResponse) async {
    var payload = notificationResponse.payload;
    if (payload != null) {
      try {
        var params = json.decode(payload);
        disposeNotification(params);
      } catch (e) {
        debugPrint('参数非JSON: $e -> $payload');
      }
    }
  }

  // 发送本地通知
  Future<void> send(String title, String body,
      {int? notificationId, String? params}) {
    NotificationDetails? details;

    if (Platform.isIOS) {
      var iosDetails = const DarwinNotificationDetails();
      details = NotificationDetails(iOS: iosDetails);
    } else if (Platform.isAndroid) {
      var androidDetails = const AndroidNotificationDetails(
        'channelId',
        '消息通知',
        importance: Importance.max,
        priority: Priority.high,
      );
      details = NotificationDetails(android: androidDetails);
    } else {
      debugPrint('不支持平台: ${Platform.operatingSystem}');
      return Future.value();
    }

    flutterLocalNotificationsPlugin?.show(
        notificationId ?? DateTime.now().millisecondsSinceEpoch >> 10,
        title,
        body,
        details,
        payload: params);

    return Future.value();
  }

  Future<bool> mustSend(String title, String body,
      {int? notificationId, String? params}) async {
    send(title, body, notificationId: notificationId, params: params);
    return true;
  }

  // 清除所有通知
  void cleanNotification() {
    flutterLocalNotificationsPlugin?.cancelAll();
  }

  // 清除指定id的通知
  void cancelNotification(int id, {String? tag}) {
    flutterLocalNotificationsPlugin?.cancel(id, tag: tag);
  }
}
