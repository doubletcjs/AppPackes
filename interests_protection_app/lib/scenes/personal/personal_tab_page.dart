import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/controllers/personal_data_controller.dart';
import 'package:interests_protection_app/scenes/account/pincode_input_page.dart';
import 'package:interests_protection_app/scenes/personal/account_setting_page.dart';
import 'package:interests_protection_app/scenes/personal/widgets/personal_interests_header.dart';
import 'package:interests_protection_app/scenes/personal/widgets/personal_list_item.dart';
import 'package:interests_protection_app/utils/local_notification.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:permission_handler/permission_handler.dart';

class PersonalTabPage extends StatefulWidget {
  PersonalTabPage({Key? key}) : super(key: key);

  @override
  State<PersonalTabPage> createState() => _PersonalTabPageState();
}

class _PersonalTabPageState extends State<PersonalTabPage>
    with AutomaticKeepAliveClientMixin {
  List<bool> _disableItemList = [false, false, false, false, false];

  PersonalDataController _personalDataController =
      Get.find<PersonalDataController>();
  AppHomeController _homeController = Get.find<AppHomeController>();

  // 取消倒计时
  void _cancelRescueCount() {
    if (_personalDataController.rescueTimer != null) {
      _personalDataController.rescueTimer?.cancel();
      _personalDataController.rescueTimer = null;
    }

    _personalDataController.sendingRescueInfo = false;
    _personalDataController.rescueCountSecond = 8;
    _personalDataController.update();
  }

  // 开启倒计时
  void _startRescueCount() {
    if (_personalDataController.rescueTimer != null) {
      _personalDataController.rescueTimer?.cancel();
      _personalDataController.rescueTimer = null;
    }

    _personalDataController.rescueCountSecond -= 1;
    _personalDataController.update();

    _personalDataController.rescueTimer = Timer.periodic(
      Duration(seconds: 1),
      (timer) {
        if (_personalDataController.rescueCountSecond <= 1) {
          _personalDataController.rescueTimer?.cancel();
          _personalDataController.rescueTimer = null;

          SVProgressHUD.show();
          AccountApi.rescueAction().then((value) {
            _personalDataController.setReportMode(isRescue: true);
            SVProgressHUD.dismiss();
          }).catchError((error) {
            _personalDataController.setReportMode(isRescue: false);
            SVProgressHUD.dismiss();
          });
        } else {
          _personalDataController.rescueCountSecond -= 1;
          _personalDataController.update();
        }
      },
    );
  }

  // 权限提示
  Widget _permissionTipWidget(int index) {
    return Padding(
      padding: EdgeInsets.only(left: 8.w),
      child: InkWell(
        onTap: () {
          AlertVeiw.show(
            context,
            confirmText: "确认",
            contentText: index == 1
                ? "蓝牙开关"
                : index == 2
                    ? "消息通知"
                    : "定位开关",
            describeText: index == 1
                ? "打开蓝牙开关除了能定位更精准，还可以和电脑端互传文件。"
                : index == 2
                    ? "关闭消息通知，会跳过手机内置系统设置，有新消息到来时不会显示到屏幕，让您的交流更隐蔽。"
                    : "影响社区及累计在线时间的正常使用",
          );
        },
        borderRadius: BorderRadius.circular(18.w / 2),
        child: Image.asset(
          "images/personal_tip@2x.png",
          width: 18.w,
          height: 18.w,
        ),
      ),
    );
  }

  // 权限开关
  Widget _permissionOnOffWidget(int index) {
    bool _isOn = _personalDataController.statusList[index];

// 用户等级
// 0：普通会员；1：VIP；2：SVIP

    final Map _iconMap = {
      2: "images/switch_on_normal_svip@2x.png",
      1: "images/switch_on_normal_vip@2x.png",
      0: "images/switch_on_normal_default@2x.png",
      3: "images/switch_on_normal_new@2x.png", // 未实名认证
    };

    String _onIcon = _iconMap[_homeController.accountModel.level];
    bool _isDisable = _disableItemList[index];

    return InkWell(
      onTap: _isDisable
          ? null
          : () async {
              // 定位开关
              if (index == 0) {
                void _setting(bool open) async {
                  _personalDataController.statusList[0] = open;
                  (await StorageUtils.sharedPreferences)
                      .setBool(kAppLocationStatus, open);
                  _personalDataController.stateHandler
                      .add(_personalDataController.statusList);

                  if (open) {
                    _personalDataController.reportLocation();
                    _personalDataController.setReportMode(
                        isRescue: _homeController.accountModel.rescue == 1);
                  } else {
                    _personalDataController.reportCancel();
                    _personalDataController.update();
                  }
                }

                if (_isOn) {
                  PincodeInputPage.show(context, (xpin) {
                    Future.delayed(Duration(milliseconds: 300), () {
                      AlertVeiw.show(
                        context,
                        confirmText: "确认",
                        contentText: "",
                        contentWidget: Padding(
                          padding: EdgeInsets.fromLTRB(24.w, 29.w, 24.w, 17.w),
                          child: RichText(
                            text: TextSpan(
                              text: "关闭定位将影响",
                              style: TextStyle(
                                fontSize: 18.sp,
                                color: const Color(0xFF000000),
                                height: 1.5,
                                fontWeight: FontWeight.normal,
                              ),
                              children: [
                                TextSpan(
                                  text: "社区",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: "及",
                                ),
                                TextSpan(
                                  text: "累计在线时间",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: "的正常使用。",
                                ),
                              ],
                            ),
                          ),
                        ),
                        cancelText: "取消",
                        confirmAction: () {
                          _setting(false);
                        },
                      );
                    });
                  });
                } else {
                  bool _serviceEnabled =
                      await Permission.location.serviceStatus ==
                          ServiceStatus.enabled;
                  PermissionStatus _permissionStatus =
                      await Permission.location.status;

                  if (_serviceEnabled == false ||
                      _permissionStatus == PermissionStatus.permanentlyDenied) {
                    utilsToast(msg: "请先打开手机定位");
                    Future.delayed(Duration(seconds: 1), () {
                      openAppSettings();
                    });
                    return;
                  }

                  if (_permissionStatus == PermissionStatus.granted) {
                    _setting(true);
                  } else {
                    await Permission.location.request().then((value) {
                      if (value == PermissionStatus.granted) {
                        _setting(true);
                      }
                    });
                  }
                }
              } else
              // 蓝牙开关
              if (index == 1) {
                // void _setting(bool open) {
                //   _sharedPreferences.then((value) {
                //     _personalDataController.statusList[1] = open;
                //     value.setBool(kAppBluetoothStatus, open);
                //     _personalDataController.update();
                //   });
                // }

                // if (_isOn) {
                //   _setting(false);
                // } else {
                //   if (await Permission.bluetooth.request() ==
                //       PermissionStatus.granted) {
                //     _setting(true);
                //   } else {
                //     utilsToast(msg: "请先打开手机蓝牙");
                //     Future.delayed(Duration(seconds: 1), () {
                //       openAppSettings().then((value) {});
                //     });
                //     return;
                //   }
                // }
              } else
              // 通知开关
              if (index == 2) {
                void _setting(bool open) async {
                  _personalDataController.statusList[2] = open;
                  (await StorageUtils.sharedPreferences)
                      .setBool(kAppNotificationStatus, open);
                  _personalDataController.update();

                  if (open == true) {
                    await notification.init();
                    await notification.registerApns();
                  } else {
                    await notification.unregisterApns();
                  }
                }

                if (_isOn) {
                  _setting(false);
                } else {
                  PermissionStatus _permissionStatus =
                      await Permission.notification.status;
                  if (_permissionStatus == PermissionStatus.permanentlyDenied) {
                    utilsToast(msg: "请先打开手机通知");
                    Future.delayed(Duration(seconds: 1), () {
                      openAppSettings();
                    });
                    return;
                  }

                  if (_permissionStatus == PermissionStatus.granted) {
                    _setting(true);
                  } else {
                    await Permission.notification.request().then((value) {
                      if (value == PermissionStatus.granted) {
                        _setting(true);
                      }
                    });
                  }
                }
              }
            },
      borderRadius: BorderRadius.circular(31.w / 2),
      child: Image.asset(
        _isDisable
            ? "images/personal_switch_off@2x.png"
            : _isOn
                ? _onIcon
                : "images/personal_switch_off@2x.png",
        width: 51.w,
        height: 31.w,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: GetBuilder<AppHomeController>(
        id: "kUpdateAccountInfo",
        init: _homeController,
        builder: (controller) {
          int _level = _homeController.accountModel.level;
          if (_homeController.accountModel.real == 0) {
            _level = 3;
          }

          if (_level == 0 || _level == 3) {
            _disableItemList[2] = true;
            _disableItemList[3] = true;
            _disableItemList[4] = true;
          } else {
            _disableItemList[2] = false;
            _disableItemList[3] = false;
            _disableItemList[4] = false;
          }

          return Stack(
            children: [
              AppBar(
                toolbarHeight: 0,
                backgroundColor: Colors.transparent,
                systemOverlayStyle: SystemUiOverlayStyle(
                  statusBarBrightness: controller.accountModel.level == 2
                      ? Brightness.dark
                      : Brightness.light,
                ),
              ),
              ListView(
                physics: ClampingScrollPhysics(),
                padding: EdgeInsets.only(top: 0, bottom: 133.w),
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: false,
                children: [
                  PersonalInterestsHeader(homeController: controller),
                  GetBuilder<PersonalDataController>(
                    builder: (_) {
                      return Column(
                        children: [
                          PersonalListItem(
                            icon: "images/personal_security@2x.png",
                            label: "账号安全",
                            labelAction: () {
                              PincodeInputPage.show(context, (xpin) async {
                                var result =
                                    await Connectivity().checkConnectivity();
                                if (result != ConnectivityResult.none) {
                                  Future.delayed(Duration(milliseconds: 300),
                                      () {
                                    Get.to(AccountSettingPage(lockDown: xpin));
                                  });
                                } else {
                                  utilsToast(msg: "网络不佳");
                                }
                              });
                            },
                          ),
                          PersonalListItem(
                            icon: "images/personal_location@2x.png",
                            label: "定位开关",
                            disable: _disableItemList[0],
                            tipWidget: _permissionTipWidget(0),
                            actionWidget: _permissionOnOffWidget(0),
                          ),
                          // PersonalListItem(
                          //   icon: "images/personal_bluetooth@2x.png",
                          //   label: "蓝牙开关",
                          //   disable: _disableItemList[1],
                          //   tipWidget: _permissionTipWidget(1),
                          //   actionWidget: _permissionOnOffWidget(1),
                          // ),
                          PersonalListItem(
                            icon: "images/personal_notification@2x.png",
                            label: "消息通知",
                            disable: _disableItemList[2],
                            tipWidget: _permissionTipWidget(2),
                            actionWidget: _permissionOnOffWidget(2),
                          ),
                          PersonalListItem(
                            icon: "images/personal_clean@2x.png",
                            label: "一键清理聊天记录",
                            disable: _disableItemList[3],
                            labelAction: () {
                              AlertVeiw.show(
                                context,
                                confirmText: "清理",
                                contentText: "",
                                contentWidget: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                      24.w, 43.w, 24.w, 30.w),
                                  child: RichText(
                                    text: TextSpan(
                                      text: "是否清理",
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        color: const Color(0xFF000000),
                                        height: 1.5,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: "所有",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "聊天记录",
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                cancelText: "取消",
                                confirmAction: () {
                                  StorageUtils.emptyCurrnetChatRecord();
                                },
                              );
                            },
                          ),
                          // 紧急救援
                          Container(
                            margin: EdgeInsets.only(
                                left: 38.w, right: 38.w, top: 38.w),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.asset((_disableItemList[4] ||
                                        _personalDataController
                                            .sendingRescueInfo)
                                    ? "images/personal_rescue_disable@2x.png"
                                    : "images/personal_rescue@2x.png"),
                                Row(
                                  children: [
                                    Expanded(
                                      child: MaterialButton(
                                        onPressed: (_disableItemList[4] ||
                                                _personalDataController
                                                        .sendingRescueInfo ==
                                                    true)
                                            ? null
                                            : () async {
                                                if (_personalDataController
                                                        .rescueTimer ==
                                                    null) {
                                                  _startRescueCount();
                                                } else {
                                                  _cancelRescueCount();
                                                }
                                              },
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(15.w),
                                        ),
                                        height: 48.w,
                                        child: Text(
                                          _personalDataController
                                                  .sendingRescueInfo
                                              ? "紧急救援中"
                                              : _personalDataController
                                                          .rescueTimer !=
                                                      null
                                                  ? "取消救援 ${_personalDataController.rescueCountSecond} 秒"
                                                  : "紧急救援",
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            color: const Color(0xFFFFFFFF),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.only(top: 28.w),
                            alignment: Alignment.center,
                            child: InkWell(
                              onTap: () {
                                AlertVeiw.show(
                                  context,
                                  confirmText: "确认",
                                  contentText: "",
                                  contentWidget: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                        25.w, 33.w, 25.w, 16.w),
                                    child: RichText(
                                      text: TextSpan(
                                        text: "点击后将进行倒计时，",
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          color: const Color(0xFF000000),
                                          height: 1.5,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: "8秒内",
                                            style: TextStyle(
                                              color: kAppConfig.appThemeColor,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "可以取消，倒计时结束后各项定位数据马上实时上传。",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                "紧急救援使用说明",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: const Color(0xFFB3B3B3),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
