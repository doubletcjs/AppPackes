import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/scenes/guidance/launch_agreement.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:package_info_plus/package_info_plus.dart';

class LoadingGuidance extends StatefulWidget {
  const LoadingGuidance({Key? key}) : super(key: key);

  @override
  State<LoadingGuidance> createState() => _LoadingGuidanceState();
}

class _LoadingGuidanceState extends State<LoadingGuidance> {
  // 检测启动状态
  void _checkLaunchStatus() {
    StorageUtils.buildVersionCheck(() {
      //  检验登录状态
      StorageUtils.appAuthStatus(
        finish: (auth) async {
          if (auth.length > 0) {
            Get.find<AppHomeController>().cacheLogin(auth: auth);
          } else {
            Get.find<AppHomeController>().sseState = -1;
            Get.offAllNamed(RouteNameString.home);
          }

          //隐藏状态栏，底部按钮栏
          SystemChrome.setEnabledSystemUIMode(
            SystemUiMode.manual,
            overlays: const [SystemUiOverlay.top, SystemUiOverlay.bottom],
          );

          Future.delayed(Duration(seconds: 1), () {
            Get.find<AppHomeController>().launchAert(
              Get.context!,
              getPermission: false,
            );
          });
        },
      );
    });
  }

  // 用户协议
  void _versionAgreement() {
    void _launch() {
      PackageInfo.fromPlatform().then((packageInfo) async {
        String version = packageInfo.version;
        debugPrint("当前app版本:$version -- 构建版本:${packageInfo.buildNumber}");
        String _currentVersion = "$version${'+'}${packageInfo.buildNumber}";

        (await StorageUtils.sharedPreferences)
            .setString("kAppVersionAgreementShowVersion", _currentVersion);
        Get.find<AppHomeController>().appVersion = _currentVersion;
        _checkLaunchStatus();

        // 应用返回后台检测
        BasicMessageChannel<String?> lifecycleChannel =
            SystemChannels.lifecycle;
        lifecycleChannel.setMessageHandler((message) {
          if (message == "AppLifecycleState.resumed" &&
              Get.find<AppHomeController>().appState != AppCurrentState.init) {
            try {
              Get.find<AppHomeController>()
                  .launchAert(Get.context!, resume: true);
            } catch (e) {}
          }
          return Future.value("");
        });
      });
    }

    StorageUtils.sharedPreferences.then((preferences) {
      String _appVersion =
          preferences.getString("kAppVersionAgreementShowVersion") ?? "";
      if (_appVersion.length == 0) {
        debugPrint("用户协议");
        LaunchAgreement.show(context, agreeAction: (agree) async {
          if (agree) {
            _launch();
          } else {
            exit(0);
          }
        });
      } else {
        _launch();
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _versionAgreement();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            "images/ios_launch@3x.png",
          ),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
