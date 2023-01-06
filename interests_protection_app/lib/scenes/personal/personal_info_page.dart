import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/scenes/personal/personal_mobile_setting.dart';
import 'package:interests_protection_app/scenes/personal/personal_name_setting.dart';
import 'package:interests_protection_app/scenes/personal/personal_qrcode_page.dart';
import 'package:interests_protection_app/scenes/personal/widgets/personal_list_item.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';
import 'package:interests_protection_app/utils/widgets/image_picker.dart';

class PersonalInfoPage extends StatelessWidget {
  PersonalInfoPage({Key? key}) : super(key: key);

  final AppHomeController _appHomeController = Get.find<AppHomeController>();

  // 我的头像
  void _changeAvatar(BuildContext context) {
    // 图片处理
    void _handleAssetFile(List<File> list) {
      if (list.length == 0) {
        return;
      }

      ImageCropper().cropImage(
        sourcePath: list.first.path,
        aspectRatio: CropAspectRatio(ratioX: 300, ratioY: 300),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Cropper',
            rectHeight: 300,
            rectWidth: 300,
            aspectRatioPickerButtonHidden: true,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      ).then((value) async {
        try {
          File(list.first.path).deleteSync();
        } catch (e) {}
        if (value != null) {
          SVProgressHUD.show();
          List<int> _imageData = await value.readAsBytes();
          String _imageBase64 = base64Encode(_imageData);
          _appHomeController.updateAccountInfo(
            params: {"avatar": "data:image/png;base64," + _imageBase64},
            finish: () {
              utilsToast(msg: "修改成功");
            },
          );
        }
      }).catchError((error) {
        try {
          File(list.first.path).deleteSync();
        } catch (e) {}
      });
    }

    void _pickAction(int index) {
      if (index == 1) {
        // 图库库
        ImagePicker.pick(context, count: 1).then((value) {
          if (value.length > 0) {
            _handleAssetFile(value);
          }
        });
      } else if (index == 0) {
        // 拍照
        ImagePicker.openCamera(context).then((value) {
          if (value.length > 0) {
            _handleAssetFile(value);
          }
        });
      }
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: const Text("拍照"),
              onPressed: () {
                Navigator.pop(context);
                _pickAction(0);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("从手机相册选择"),
              onPressed: () {
                Navigator.pop(context);
                _pickAction(1);
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text("取消"),
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  // 性别
  void _changeGender(BuildContext context) {
    void _setGender(String gender) {
      _appHomeController.updateAccountInfo(
        params: {"sex": gender},
        finish: () {
          utilsToast(msg: "修改成功");
        },
      );
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              child: const Text("男"),
              onPressed: () {
                Navigator.pop(context);
                _setGender("男");
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("女"),
              onPressed: () {
                Navigator.pop(context);
                _setGender("女");
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text("取消"),
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("个人资料"),
        leading: AppbarBack(),
      ),
      body: GetBuilder<AppHomeController>(
        id: "kUpdateAccountInfo",
        init: _appHomeController,
        builder: (controller) {
          return ListView(
            physics: BouncingScrollPhysics(),
            children: [
              Container(
                margin: EdgeInsets.only(top: 14.w),
                child: PersonalListItem(
                  leading: Text(
                    "我的头像",
                    style: TextStyle(
                      color: const Color(0xFF000000),
                      fontSize: 15.sp,
                    ),
                  ),
                  labelAction: () {
                    _changeAvatar(context);
                  },
                  height: 70.w,
                  actionWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      networkImage(
                        controller.accountModel.avatar,
                        Size(48.w, 48.w),
                        BorderRadius.circular(5.w),
                        memoryData: true,
                        placeholder: "images/personal_placeholder@2x.png",
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
              ),
              PersonalListItem(
                leading: Text(
                  "我的名字",
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                labelAction: () {
                  Get.to(PersonalNameSetting());
                },
                height: 56.w,
                actionWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 160.w),
                      child: Text(
                        controller.accountModel.nickname.length == 0
                            ? "未设置"
                            : controller.accountModel.nickname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: const Color(0xFFB3B3B3),
                          fontSize: 15.sp,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Image.asset(
                      "images/personal_arrow@2x.png",
                      width: 24.w,
                      height: 24.w,
                    ),
                  ],
                ),
              ),
              PersonalListItem(
                leading: Text(
                  "我的二维码",
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                labelAction: () {
                  Get.to(PersonalQrcodePage());
                },
                height: 56.w,
                actionWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      "images/personal_qrcode@2x.png",
                      width: 24.w,
                      height: 24.w,
                    ),
                    SizedBox(width: 7.w),
                    Image.asset(
                      "images/personal_arrow@2x.png",
                      width: 24.w,
                      height: 24.w,
                    ),
                  ],
                ),
              ),
              PersonalListItem(
                leading: Text(
                  "性别",
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                labelAction: () {
                  _changeGender(context);
                },
                height: 56.w,
                actionWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.accountModel.sex.length == 0
                          ? "未设置"
                          : controller.accountModel.sex,
                      style: TextStyle(
                        color: const Color(0xFFB3B3B3),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Image.asset(
                      "images/personal_arrow@2x.png",
                      width: 24.w,
                      height: 24.w,
                    ),
                  ],
                ),
              ),
              PersonalListItem(
                leading: Text(
                  "紧急联系电话",
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                labelAction: () {
                  Get.to(PersonalMobileSetting());
                },
                hideBorder: true,
                height: 56.w,
                actionWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      controller.accountModel.emergencyPhone.length == 0
                          ? "未设置"
                          : phoneFormat(controller.accountModel.emergencyPhone),
                      style: TextStyle(
                        color: const Color(0xFFB3B3B3),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    SizedBox(width: 7.w),
                    Image.asset(
                      "images/personal_arrow@2x.png",
                      width: 24.w,
                      height: 24.w,
                    ),
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
