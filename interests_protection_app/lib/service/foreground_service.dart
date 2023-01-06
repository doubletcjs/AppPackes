import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_sseclient_controller.dart';
import 'package:interests_protection_app/service/isolate/service_sseclient_controller.dart';
import 'package:interests_protection_app/utils/notification.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class ForegroundService {
  AppSseclientController sseclientController = AppSseclientController();

  void _notificationChannel() {
    EventChannel _defaultListener =
        EventChannel("com.tairnet.chat.android.local.notification/listen");
    _defaultListener.receiveBroadcastStream().listen(
      (message) async {
        try {
          Map<String, dynamic> map = jsonDecode(message) ?? Map();
          if (map.containsKey("event") && map.containsKey("from")) {
            disposeNotification(map);
          }
        } catch (e) {}
      },
    );
  }

  void initForegroundTask() async {
    if (GetPlatform.isAndroid) {
      _notificationChannel();

      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'com.tairnet.chat',
          channelName: 'Tairnet Foreground Notification',
          channelDescription:
              'This notification appears when the foreground service is running.',
          channelImportance: NotificationChannelImportance.MAX,
          priority: NotificationPriority.HIGH,
          iconData: const NotificationIconData(
            resType: ResourceType.mipmap,
            resPrefix: ResourcePrefix.ic,
            name: 'launcher',
          ),
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: const ForegroundTaskOptions(
          interval: 5000,
          isOnceEvent: false,
          autoRunOnBoot: true,
          allowWakeLock: true,
          allowWifiLock: true,
        ),
      );

      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    } else {
      if (await FlutterForegroundTask.isRunningService == true) {
        await FlutterForegroundTask.stopService();
        await FlutterForegroundTask.clearAllData();
      }
    }
  }

  void stopTask() async {
    sseclientController.restoreMessageSign();
    await FlutterForegroundTask.clearAllData();
    await FlutterForegroundTask.reLaunch();
  }

  Future<void> startTask({
    required Map auth,
  }) async {
    Completer _completer = Completer();

    if (GetPlatform.isAndroid) {
      debugPrint("前台服务注册");
      // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
      // onNotificationPressed function to be called.
      //
      // When the notification is pressed while permission is denied,
      // the onNotificationPressed function is not called and the app opens.
      //
      // If you do not use the onNotificationPressed or launchApp function,
      // you do not need to write this code.
      // if (!await FlutterForegroundTask.canDrawOverlays) {
      //   final isGranted =
      //       await FlutterForegroundTask.openSystemAlertWindowSettings();
      //   if (!isGranted) {
      //     debugPrint('SYSTEM_ALERT_WINDOW permission denied!');
      //     return false;
      //   }
      // }

      String token = auth["token"] ?? "";
      if (token.length > 0) {
        String salt = auth["salt"] ?? "";
        String curve25519 = auth["curve25519"] ?? "";
        String userId = auth["userId"] ?? "";

        await FlutterForegroundTask.saveData(
          key: "token",
          value: token,
        );
        await FlutterForegroundTask.saveData(
          key: "salt",
          value: salt,
        );
        await FlutterForegroundTask.saveData(
          key: "curve25519",
          value: curve25519,
        );
        await FlutterForegroundTask.saveData(
          key: "userId",
          value: userId,
        );
      }

      if (await FlutterForegroundTask.isRunningService) {
        debugPrint("激活服务");
        await FlutterForegroundTask.reLaunch();
      } else {
        await FlutterForegroundTask.startService(
          notificationTitle: "服务启动中",
          notificationText: "",
          callback: startCallback,
        );

        debugPrint("前台服务启动");
      }

      if (token.length > 0) {
        // 打开安卓通知
        MethodChannel("com.tairnet.chat.android.local.notification/receiver")
            .invokeMethod("openLaunchIntent");

        sseclientController.subscribe();
      }

      _completer.complete();
    } else {
      if (auth.length > 0 && auth.containsKey("token")) {
        sseclientController.subscribe();
      }
      _completer.complete();
    }

    return _completer.future;
  }
}

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

@pragma('vm:entry-point')
class FirstTaskHandler extends TaskHandler {
  ServiceSseclientController sseclientController = ServiceSseclientController();
  bool _sseInit = false;

  void _stopSSE() async {
    debugPrint("isolate _stopSSE");
    String token =
        await FlutterForegroundTask.getData<String>(key: "token") ?? "";
    if (_sseInit || token.length == 0) {
      await sseclientController.unsubscribe();
      _sseInit = false;
    }
  }

  void _startSSE() async {
    debugPrint("isolate _startSSE");
    String token =
        await FlutterForegroundTask.getData<String>(key: "token") ?? "";
    if (token.length > 0) {
      String salt =
          await FlutterForegroundTask.getData<String>(key: "salt") ?? "";
      String curve25519 =
          await FlutterForegroundTask.getData<String>(key: "curve25519") ?? "";
      String userId =
          await FlutterForegroundTask.getData<String>(key: "userId") ?? "";

      kAppConfig.apiHeader["Authorization"] = "Bearer $token";
      kAppConfig.serverSalt = salt;
      kAppConfig.curvePrivateKey = curve25519;

      // 初始化SSE
      sseclientController.subscribe(userId: userId);
      _sseInit = true;
    }
  }

  @override
  Future<void> onStart(DateTime timestamp) async {
    debugPrint('onStart timestamp:$timestamp');
    _stopSSE();
  }

  @override
  Future<void> onEvent(DateTime timestamp) async {
    if (await FlutterForegroundTask.isAppOnBackground) {
      debugPrint('onEvent timestamp:$timestamp');
    }
  }

  @override
  Future<void> onLaunch(DateTime timestamp) async {
    debugPrint('重启应用进入前台 timestamp:$timestamp');
    // 重启应用进入前台
    _stopSSE();
  }

  @override
  Future<void> onDetached(DateTime timestamp) async {
    debugPrint('杀死应用进入后台 timestamp:$timestamp');
    // 杀死应用进入后台
    _startSSE();
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('onDestroy timestamp:$timestamp');
    _stopSSE();
  }

  @override
  void onButtonPressed(String id) {
    // Called when the notification button on the Android platform is pressed.
  }

  @override
  void onNotificationPressed() {
    // Called when the notification itself on the Android platform is pressed.
    //
    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // this function to be called.

    // Note that the app will only route to "/resume-route" when it is exited so
    // it will usually be necessary to send a message through the send port to
    // signal it to restore state when the app is already started.
    FlutterForegroundTask.launchApp();
  }
}
