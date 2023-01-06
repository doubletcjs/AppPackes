import 'package:get/get.dart';
import 'package:interests_protection_app/routes/middleware.dart';
import 'package:interests_protection_app/scenes/account/account_login_page.dart';
import 'package:interests_protection_app/scenes/account/account_register_page.dart';
import 'package:interests_protection_app/scenes/chat/chat_main_page.dart';
import 'package:interests_protection_app/scenes/guidance/loading_guidance.dart';
import 'package:interests_protection_app/scenes/home/home_tab_page.dart';

part 'route_name_string.dart';

class RouteUtils {
  static final List<GetPage> routes = [
    /// 引导页
    GetPage(
      name: RouteNameString.launch,
      page: () {
        return LoadingGuidance();
      },
      transition: Transition.noTransition,
    ),

    /// 首页
    GetPage(
      name: RouteNameString.home,
      page: () {
        return HomeTabPage();
      },
      transition: Transition.noTransition,
    ),

    /// 登录
    GetPage(
      name: RouteNameString.login,
      page: () {
        return AccountLoginPage();
      },
    ),

    /// 注册
    GetPage(
      name: RouteNameString.register,
      page: () {
        return AccountRegisterPage();
      },
    ),

    /// 助理
    GetPage(
      name: RouteNameString.customer,
      page: () {
        return ChatMainPage();
      },
      transition: Transition.downToUp,
      popGesture: false,
      fullscreenDialog: true,
      middlewares: [MiddleWare()],
    ),

    /// 聊天
    GetPage(
      name: RouteNameString.chat,
      page: () {
        String fromId = (Get.arguments ?? {})["fromId"] ?? "";
        bool fromAlert = (Get.arguments ?? {})["fromAlert"] ?? false;

        return ChatMainPage(
          fromId: fromId,
          fromAlert: fromAlert,
        );
      },
      middlewares: [MiddleWare()],
    ),
  ];
}
