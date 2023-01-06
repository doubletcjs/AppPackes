import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

class AppbarBack extends StatelessWidget {
  final Color? iconColor;
  const AppbarBack({super.key, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MaterialButton(
        onPressed: () {
          Get.back();
        },
        padding: EdgeInsets.zero,
        minWidth: 44.w,
        height: 44.w,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(44.w / 2),
        ),
        child: Image.asset(
          "images/nav_back@2x.png",
          width: 32.w,
          height: 32.w,
          color: iconColor ?? const Color(0xFF000000),
        ),
      ),
    );
  }
}
