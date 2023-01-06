import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/scenes/chat/widgets/customer_pop_menu.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class CustomerHeaderBar {
  final void Function()? onTap;
  const CustomerHeaderBar({
    Key? key,
    this.onTap,
  });

  PreferredSizeWidget init(BuildContext context) {
    return AppBar(
      leadingWidth: 0,
      titleSpacing: 0,
      leading: Container(),
      toolbarHeight: 102.w,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
          if (onTap != null) {
            onTap!();
          }
        },
        child: Container(
          height: 102.w,
          color: const Color(0xFFEFEFEF),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -24.w,
                right: -24.w,
                child: Image.asset("images/assistant_circle@2x.png"),
              ),
              Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    color: const Color(0xFFFFFFFF),
                    height: 32.w + 15.w,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AppbarBack(),
                        CustomerPopMenu(),
                      ],
                    ),
                  ),
                  SizedBox(height: 29.w),
                ],
              ),
              Positioned(
                bottom: 0,
                child: Image.asset(
                  "images/assistant_avatar@2x.png",
                  width: 50.w,
                  height: 55.w,
                ),
              ),
              Positioned(
                bottom: 55.w + 4.w,
                child: GetBuilder<AppHomeController>(
                  id: "kFriendInfoUpdate",
                  builder: (controller) {
                    return Text(
                      "${kAppConfig.assistantNickName.length == 0 ? '客服' : kAppConfig.assistantNickName}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.normal,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
