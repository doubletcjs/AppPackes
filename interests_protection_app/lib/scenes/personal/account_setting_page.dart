import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/scenes/personal/password_change_page.dart';
import 'package:interests_protection_app/scenes/personal/pincode_change_page.dart';
import 'package:interests_protection_app/scenes/personal/widgets/personal_list_item.dart';
import 'package:interests_protection_app/scenes/personal/xpincode_change_page.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class AccountSettingPage extends StatefulWidget {
  final bool? lockDown;
  const AccountSettingPage({super.key, this.lockDown});

  @override
  State<AccountSettingPage> createState() => _AccountSettingPageState();
}

class _AccountSettingPageState extends State<AccountSettingPage> {
  String _xpin = "未设置";

  void _loadXPIN(bool update) {
    String _x = Get.find<AppHomeController>().accountModel.xpin;
    if (_x.length > 0) {
      CryptoUtils.decryptXPIN(
              _x, Get.find<AppHomeController>().accountModel.userId)
          .then((value) {
        if (value.length > 0) {
          _xpin = value;

          if (update) {
            setState(() {});
          }
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _loadXPIN(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("账号安全"),
        leading: AppbarBack(),
      ),
      body: IgnorePointer(
        ignoring: (widget.lockDown ?? false),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.only(top: 14.w),
                children: [
                  PersonalListItem(
                    leading: Text(
                      "修改PIN码",
                      style: TextStyle(
                        color: widget.lockDown == true
                            ? const Color(0xFFC4C4C4)
                            : const Color(0xFF000000),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    labelAction: () {
                      Get.to(PincodeChangePage());
                    },
                    height: 56.w,
                  ),
                  PersonalListItem(
                    leading: Text(
                      "修改密码",
                      style: TextStyle(
                        color: widget.lockDown == true
                            ? const Color(0xFFC4C4C4)
                            : const Color(0xFF000000),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    labelAction: () {
                      Get.to(PasswordChangePage());
                    },
                    height: 56.w,
                  ),
                  PersonalListItem(
                    leading: Text(
                      "紧急PIN码",
                      style: TextStyle(
                        color: widget.lockDown == true
                            ? const Color(0xFFC4C4C4)
                            : const Color(0xFF000000),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    labelAction: () {
                      Get.to(XpincodeChangePage(xpin: _xpin))?.then(
                        (value) => _loadXPIN(true),
                      );
                    },
                    height: 56.w,
                    hideBorder: true,
                    actionWidget: Row(
                      children: [
                        widget.lockDown == true
                            ? SizedBox()
                            : GetBuilder<AppHomeController>(
                                id: "kUpdateAccountInfo",
                                builder: (controller) {
                                  _loadXPIN(false);
                                  return Text(
                                    "$_xpin",
                                    style: TextStyle(
                                      color: const Color(0xFFB3B3B3),
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  );
                                },
                              ),
                        SizedBox(width: 4.w),
                        Image.asset(
                          "images/personal_arrow@2x.png",
                          width: 24.w,
                          height: 24.w,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: 56.w,
                    color: const Color(0xFFFFFFFF),
                    margin: EdgeInsets.only(top: 19.w),
                    child: MaterialButton(
                      onPressed: () {
                        AlertVeiw.show(
                          context,
                          confirmText: "确认",
                          contentText: "",
                          contentWidget: Padding(
                            padding:
                                EdgeInsets.fromLTRB(29.w, 24.w, 20.w, 19.w),
                            child: Column(
                              children: [
                                Text(
                                  "注销账号",
                                  style: TextStyle(
                                    fontSize: 18.sp,
                                    color: kAppConfig.appThemeColor,
                                  ),
                                ),
                                SizedBox(height: 11.w),
                                Text(
                                  "注意！注销账号后，您将无法登录、使用该账号及账号原验证手机相关产品与服务；您将清空聊天记录、动态、通讯录等一切信息。",
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: const Color(0xFFB3B3B3),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          cancelText: "取消",
                          confirmWidget: MaterialButton(
                            onPressed: () {
                              Navigator.of(context).pop();

                              SVProgressHUD.show();
                              AccountApi.logoff().then((value) {
                                SVProgressHUD.dismiss();
                                Future.delayed(Duration(milliseconds: 200), () {
                                  Get.find<AppHomeController>().cancel();
                                });
                              }).catchError((error) {
                                SVProgressHUD.dismiss();
                              });
                            },
                            padding: EdgeInsets.zero,
                            height: 44.w,
                            color: const Color(0xFFFFFFFF),
                            elevation: 0,
                            highlightElevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22.w),
                              side: BorderSide(
                                width: 1.w,
                                color: kAppConfig.appPlaceholderColor,
                              ),
                            ),
                            child: Text(
                              "注销",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFCFCFCF),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ),
                          confirmAction: () {
                            SVProgressHUD.show();
                            AccountApi.logout().then((value) {
                              SVProgressHUD.dismiss();
                              Future.delayed(Duration(milliseconds: 200), () {
                                Get.find<AppHomeController>().logout();
                              });
                            }).catchError((error) {
                              SVProgressHUD.dismiss();
                            });
                          },
                        );
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: EdgeInsets.zero,
                      child: Text(
                        "注销账号",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFFC4C4C4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width,
              height: 56.w + MediaQuery.of(context).padding.bottom,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom,
              ),
              color: const Color(0xFFFFFFFF),
              child: MaterialButton(
                onPressed: () {
                  AlertVeiw.show(
                    context,
                    confirmText: "确认",
                    contentText: "是否退出登录",
                    cancelText: "取消",
                    confirmAction: () {
                      SVProgressHUD.show();
                      AccountApi.logout().then((value) {
                        SVProgressHUD.dismiss();
                        Future.delayed(Duration(milliseconds: 200), () {
                          Get.find<AppHomeController>().logout();
                        });
                      }).catchError((error) {
                        SVProgressHUD.dismiss();
                      });
                    },
                  );
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: EdgeInsets.zero,
                child: Text(
                  "退出登录",
                  style: TextStyle(
                    fontSize: 15.sp,
                    color: widget.lockDown == true
                        ? const Color(0xFFC4C4C4)
                        : const Color(0xFF000000),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
