import 'dart:ui';

import 'package:file_preview/file_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/routes/route_observer_utils.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/service/foreground_service.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/widgets/image_picker.dart';
import 'package:oktoast/oktoast.dart';
// import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  Get.deleteAll();

  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  SVProgressHUD.dismiss();
  SVProgressHUD.setDefaultMaskType(SVProgressHUDMaskType.custom);
  SVProgressHUD.setDefaultAnimationType(SVProgressHUDAnimationType.native);
  SVProgressHUD.setBorderWidth(0);
  SVProgressHUD.setBackgroundLayerColor(Colors.black.withOpacity(0.1));

  // if (kReleaseMode && GetPlatform.isAndroid == false) {
  //   SentryFlutter.init(
  //     (options) {
  //       options.dsn =
  //           'https://f34c4edb683748a2a87459f440f785a2@o408543.ingest.sentry.io/4503942719799296';
  //       options.tracesSampleRate = 1.0;
  //     },
  //     appRunner: () => runApp(const MyApp()),
  //   );
  // } else {
  // }

  Get.put(AppHomeController());
  runApp(const MyApp());

  // 锁死屏幕方向 main() WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
    const [
      DeviceOrientation.portraitUp,
    ],
  );

  //隐藏状态栏，底部按钮栏
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: const [],
  );

  QueueUtil.get("kFilePreviewTBS")?.addTask(() {
    return FilePreview.initTBS();
  });

  ImagePicker.cleanTempDirectory();

  QueueUtil.get("kForegroundServiceInit")?.addTask(() {
    return ForegroundService().initForegroundTask();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(375.0, 667.0),
      builder: (ctx, child) {
        return OKToast(
          child: GetMaterialApp(
            title: "海外服务",
            debugShowCheckedModeBanner: false,
            getPages: RouteUtils.routes,
            initialRoute: RouteNameString.launch,
            theme: ThemeData(
              appBarTheme: AppBarTheme(
                centerTitle: true,
                toolbarHeight: 44.w,
                titleTextStyle: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
                elevation: 0,
                backgroundColor: const Color(0xFFFFFFFF),
                actionsIconTheme: IconThemeData(
                  color: const Color(0xFF515151),
                ),
                iconTheme: IconThemeData(
                  color: const Color(0xFF333333),
                ),
                systemOverlayStyle: GetPlatform.isAndroid
                    ? SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.dark,
                      )
                    : Theme.of(context).appBarTheme.systemOverlayStyle,
              ),
              scaffoldBackgroundColor: const Color(0xFFFFFFFF),
            ),
            locale: Locale("zh"),
            supportedLocales: [Locale("zh")],
            localizationsDelegates: [
              GlobalCupertinoLocalizations.delegate,
              // 本地化的代理类
              GlobalMaterialLocalizations.delegate, //为Material组件库提供的本地化的字符串和其他值
              GlobalCupertinoLocalizations
                  .delegate, //为Material组件库提供的本地化的字符串和其他值
              GlobalWidgetsLocalizations.delegate, // 定义组件默认的文本方向，从左到右或从右到左
            ],
            navigatorObservers: [
              RouteObserverUtils().routeObserver,
            ],
          ),
        );
      },
    );
  }
}
