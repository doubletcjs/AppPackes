import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class MiddleWare extends GetMiddleware {
  @override
  GetPage? onPageCalled(GetPage? page) {
    debugPrint('中间件拦截');
    if (page?.name == RouteNameString.chat ||
        page?.name == RouteNameString.customer) {
      int sseState = Get.find<AppHomeController>().sseState;
      if (sseState != 1) {
        // -1 初始化 0 连接中 1 已连接 2 已断开
        utilsToast(
            msg:
                "${sseState == 0 ? 'SSE连接中' : sseState == 2 ? "SSE已断开" : 'SSE初始化中'}");
        return null;
      }
    }

    return super.onPageCalled(page);
  }

  @override
  Widget onPageBuilt(Widget page) {
    return page;
  }

  @override
  RouteSettings? redirect(String? route) {
    return super.redirect(route);
  }
}
