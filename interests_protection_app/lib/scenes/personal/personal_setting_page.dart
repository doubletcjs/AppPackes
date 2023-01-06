import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/scenes/personal/directions/directions_list_page.dart';
import 'package:interests_protection_app/scenes/personal/feedback_complaint_page.dart';
import 'package:interests_protection_app/scenes/personal/personal_about_page.dart';
import 'package:interests_protection_app/scenes/personal/personal_info_page.dart';
import 'package:interests_protection_app/scenes/personal/widgets/personal_list_item.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class PersonalSettingPage extends StatelessWidget {
  const PersonalSettingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("设置"),
        leading: AppbarBack(),
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: [
          Container(
            margin: EdgeInsets.only(top: 14.w, bottom: 14.w),
            child: PersonalListItem(
              leading: Text(
                "个人资料",
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 15.sp,
                ),
              ),
              labelAction: () {
                Get.to(PersonalInfoPage());
              },
              hideBorder: true,
              height: 56.w,
            ),
          ),
          PersonalListItem(
            leading: Text(
              "APP使用说明",
              style: TextStyle(
                color: const Color(0xFF000000),
                fontSize: 15.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
            labelAction: () {
              Get.to(DirectionsListPage());
            },
            height: 56.w,
          ),
          PersonalListItem(
            leading: Text(
              "意见反馈",
              style: TextStyle(
                color: const Color(0xFF000000),
                fontSize: 15.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
            labelAction: () {
              Get.to(FeedbackComplaintPage(feedback: true));
            },
            height: 56.w,
          ),
          PersonalListItem(
            leading: Text(
              "关于我们",
              style: TextStyle(
                color: const Color(0xFF000000),
                fontSize: 15.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
            labelAction: () {
              Get.to(PersonalAboutPage());
            },
            height: 56.w,
          )
        ],
      ),
    );
  }
}
