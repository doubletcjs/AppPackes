import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/scenes/personal/personal_equities_page.dart';
import 'package:interests_protection_app/scenes/personal/personal_setting_page.dart';
import 'package:interests_protection_app/scenes/personal/real_name_auth_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class PersonalInterestsHeader extends StatelessWidget {
  final AppHomeController homeController;
  PersonalInterestsHeader({Key? key, required this.homeController})
      : super(key: key);

// 用户等级
// 0：普通会员；1：VIP；2：SVIP

  final Map _backgroundMap = {
    2: "images/member_svip@2x.png",
    1: "images/member_vip@2x.png",
    0: "images/member_default@2x.png",
    3: "images/member_new@2x.png", // 未实名认证
  };

  final Map _backgroundNameMap = {
    2: "images/member_svip_name@2x.png",
    1: "images/member_vip_name@2x.png",
    0: "images/member_default_name@2x.png",
    3: "images/member_new_name@2x.png", // 未实名认证
  };

  final Map _backgroundColorMap = {
    2: const Color(0xFF000000),
    1: const Color(0xFFFCF3CC),
    0: const Color(0xFFC9DDF8),
    3: const Color(0xFFE4E4E4),
  };

  final Map _nameColorMap = {
    2: const Color(0xFFFFFFFF),
    1: const Color(0xFF6B3A19),
    0: const Color(0xFF42528F),
    3: const Color(0xFF636363),
  };

  final Map _locationColorMap = {
    2: const Color(0xFF949494),
    1: const Color(0xFFDBD2A7),
    0: const Color(0xFF8797D4),
    3: const Color(0xFFA6A6A6),
  };

  final Map _locationMap = {
    2: "images/location_svip@2x.png",
    1: "images/location_vip@2x.png",
    0: "images/location_normal@2x.png",
    3: "images/location_new@2x.png",
  };

  final Map _quantityGradientMap = {
    2: [const Color(0x4CEEDFB4), const Color(0x2CCCCCC)],
    1: [const Color(0xB2F7EAB0), const Color(0x0FCF3CC)],
  };

  final Map _quantityColorMap = {
    2: const Color(0xFFFFEBD1),
    1: const Color(0xFFB58A45),
  };

  final Map _equitiesColorMap = {
    2: const Color(0xFF854829),
    1: const Color(0xFFAB7E3A),
    0: const Color(0xFF546291),
    3: const Color(0xFF636363),
  };

  // 额度
  Widget _quantityWidget(int level) {
    String _amountCN(int amount) {
      if (amount >= 10000 && amount < 100000000) {
        return "${(amount / 10000).truncate()}万";
      } else if (amount >= 100000000) {
        return "${(amount / 100000000).truncate()}亿";
      } else {
        return "$amount";
      }
    }

    return homeController.accountModel.amount == 0
        ? SizedBox()
        : Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _quantityGradientMap[level],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.w),
                bottomLeft: Radius.circular(20.w),
              ),
            ),
            height: 40.w,
            padding: EdgeInsets.only(left: 23.w, right: 29.w),
            alignment: Alignment.center,
            child: Text(
              "额度: ${_amountCN(homeController.accountModel.amount)}",
              style: TextStyle(
                fontSize: 15.sp,
                color: _quantityColorMap[level],
              ),
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    int _level = homeController.accountModel.level;
    if (homeController.accountModel.real == 0) {
      _level = 3;
    }

    return Container(
      height: 220.w + MediaQuery.of(context).padding.top,
      margin: EdgeInsets.only(bottom: 14.w),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景
          Positioned(
            bottom: 0,
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: _backgroundColorMap[_level],
              ),
              margin: EdgeInsets.only(bottom: 1.w),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220.w,
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                    "images/member_backgroud@2x.png",
                  ),
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  _backgroundMap[_level],
                  fit: BoxFit.cover,
                  height: 92.w,
                ),
                // 权益
                Padding(
                  padding: EdgeInsets.only(
                    left: 51.w,
                    right: 51.w,
                    top: 4.w,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            _backgroundNameMap[_level],
                            height: 22.w,
                          ),
                        ],
                      ),
                      MaterialButton(
                        onPressed: () {
                          Get.to(PersonalEquitiesPage(level: _level));
                        },
                        padding: EdgeInsets.zero,
                        child: Row(
                          children: [
                            Text(
                              "查看我的权益",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: _equitiesColorMap[_level],
                              ),
                            ),
                            SizedBox(width: 7.w),
                            Image.asset(
                              "images/equities_arrow@2x.png",
                              width: 4.w,
                              height: 8.w,
                              color: _equitiesColorMap[_level],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              "images/member_mask@2x.png",
              fit: BoxFit.cover,
            ),
          ),
          // 设置
          Positioned(
            top: MediaQuery.of(context).padding.top,
            right: 5.w,
            child: MaterialButton(
              onPressed: () {
                Get.to(PersonalSettingPage());
              },
              minWidth: 44.w,
              height: 44.w,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(44.w / 2),
              ),
              child: Center(
                child: Image.asset(
                  "images/personal_setting@2x.png",
                  width: 20.w,
                  height: 20.w,
                ),
              ),
            ),
          ),
          // 用户信息
          Positioned(
            left: 27.w,
            right: 0,
            top: 52.w + MediaQuery.of(context).padding.top,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      networkImage(
                        homeController.accountModel.avatar,
                        Size(48.w, 48.w),
                        BorderRadius.circular(5.w),
                        memoryData: true,
                        placeholder: "images/personal_placeholder@2x.png",
                      ),
                      SizedBox(width: 15.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              homeController.accountModel.nickname,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: _nameColorMap[_level],
                              ),
                            ),
                            SizedBox(height: 4.w),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  _locationMap[_level],
                                  width: 9.w,
                                  height: 10.w,
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  "${homeController.accountModel.location}",
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: _locationColorMap[_level],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 27.w),
                    ],
                  ),
                ),
                _level == 3
                    ? Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(10.w),
                        ),
                        height: 33.w,
                        margin: EdgeInsets.only(right: 17.w),
                        child: MaterialButton(
                          onPressed: () {
                            Get.to(RealNameAuthPage());
                          },
                          padding: EdgeInsets.only(left: 15.w, right: 15.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.w),
                          ),
                          child: Text(
                            "实名认证",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: const Color(0xFF808080),
                            ),
                          ),
                        ),
                      )
                    : _level == 0
                        ? SizedBox()
                        : _quantityWidget(_level),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
