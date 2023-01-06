import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_apns_only/flutter_apns_only.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/utils/local_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 收到消息的回调
Future<void> onMessage(ApnsRemoteMessage message) async {
  print("onMessage: $message");
  debugPrint(message.payload.toString());
}

// 点击消息的回调
Future<void> onResume(ApnsRemoteMessage message) async {
  print("onResume: $message");
  debugPrint(message.payload.toString());
  disposeNotification(message.payload["data"]);
}

// 静默push的回调
Future<void> onBackgroundMessage(ApnsRemoteMessage message) async {
  print("onBackgroundPush: $message");
  debugPrint(message.payload.toString());
}

// 冷启动点击通知栏的回调
Future<void> onLaunch(ApnsRemoteMessage message) async {
  print("onLaunch: $message");
  debugPrint(message.payload.toString());
  disposeNotification(message.payload["data"]);
}

Future<void> disposeNotification(dynamic data) async {
  try {
    if (Get.find<AppHomeController>().appState != AppCurrentState.init) {
      (await SharedPreferences.getInstance())
          .setString("kNotificationData", jsonEncode(data));
      debugPrint('点击了通知 : $data');

      if (await FlutterForegroundTask.isAppOnForeground) {
        Get.find<AppHomeController>().disposeNotification();
      }
    } else {
      notification.cleanNotification();
    }
  } catch (e) {}
}
