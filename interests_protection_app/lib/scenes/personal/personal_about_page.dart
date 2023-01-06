import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/scenes/personal/personal_agressment_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class PersonalAboutPage extends StatefulWidget {
  const PersonalAboutPage({super.key});

  @override
  State<PersonalAboutPage> createState() => _PersonalAboutPageState();
}

class _PersonalAboutPageState extends State<PersonalAboutPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("关于我们"),
        leading: AppbarBack(),
      ),
      body: Align(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(height: 48.w),
                Image.asset("images/about_logo@2x.png", height: 226.w),
                SizedBox(height: 55.w),
                Column(
                  children: [
                    Text(
                      "海外利益保护平台",
                      style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 5.w),
                    Text(
                      "Ver.${Get.find<AppHomeController>().appVersion}",
                      style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: 15.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 42.w),
                InkWell(
                  onTap: () {
                    Get.to(PersonalAgressmentPage());
                  },
                  child: Text(
                    "《用户隐私协议与声明》",
                    style: TextStyle(
                      color: kAppConfig.appThemeColor,
                      fontSize: 15.sp,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset("images/about_co_logo@2x.png", height: 22.w),
                SizedBox(height: 29.w + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
