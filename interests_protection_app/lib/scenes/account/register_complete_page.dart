import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/scenes/personal/real_name_auth_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class RegisterCompletePage extends StatefulWidget {
  final bool? resetAction;
  const RegisterCompletePage({
    Key? key,
    this.resetAction,
  }) : super(key: key);

  @override
  State<RegisterCompletePage> createState() => _RegisterCompletePageState();
}

class _RegisterCompletePageState extends State<RegisterCompletePage> {
  @override
  Widget build(BuildContext context) {
    String _phone = (Get.arguments ?? {})["phone"] ?? "";
    bool _real = (Get.arguments ?? {})["real"] ?? false;

    return Scaffold(
      appBar: AppBar(leading: SizedBox()),
      body: Container(
        margin: EdgeInsets.only(left: 54.w, right: 54.w),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 100.w - AppBar().preferredSize.height),
            Image.asset(
              "images/register_complete@2x.png",
              width: 167.w,
              height: 122.w,
            ),
            SizedBox(height: 9.w),
            Text(
              (widget.resetAction ?? false) == true ? "恭喜您，修改成功" : "恭喜您，注册成功",
              style: TextStyle(
                color: const Color(0xFF000000),
                fontSize: 20.sp,
              ),
            ),
            SizedBox(height: 60.w),
            Row(
              children: [
                Expanded(
                  child: MaterialButton(
                    onPressed: () {
                      Get.offAllNamed(
                        RouteNameString.login,
                        arguments: {"phone": _phone},
                      );
                    },
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    color: kAppConfig.appThemeColor,
                    height: 48.w,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24.w),
                    ),
                    highlightElevation: 0,
                    elevation: 0,
                    child: Text(
                      (widget.resetAction ?? false) == true ? "马上登录" : "开始体验",
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15.w),
            (widget.resetAction ?? false) == true || _real == true
                ? SizedBox()
                : Row(
                    children: [
                      Expanded(
                        child: MaterialButton(
                          onPressed: () {
                            Get.offAll(RealNameAuthPage(fromRegister: true));
                          },
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          color: const Color(0xFFFFFFFF),
                          height: 48.w,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.w),
                            side: BorderSide(
                              width: 0.5.w,
                              color: kAppConfig.appThemeColor,
                            ),
                          ),
                          highlightElevation: 0,
                          elevation: 0,
                          child: Text(
                            "实名认证",
                            style: TextStyle(
                              color: kAppConfig.appThemeColor,
                              fontSize: 18.sp,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: 9.w),
            (widget.resetAction ?? false) == true
                ? SizedBox()
                : Text(
                    "为更好的体验软件功能，请尽快进行实名认证",
                    style: TextStyle(
                      color: const Color(0xFFB3B3B3),
                      fontSize: 12.sp,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
