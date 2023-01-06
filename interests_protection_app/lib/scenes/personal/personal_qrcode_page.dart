import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PersonalQrcodePage extends StatefulWidget {
  const PersonalQrcodePage({Key? key}) : super(key: key);

  @override
  State<PersonalQrcodePage> createState() => _PersonalQrcodePageState();
}

class _PersonalQrcodePageState extends State<PersonalQrcodePage> {
  AppHomeController _appHomeController = Get.find<AppHomeController>();
  String _qrcodeDataString = "";
  final GlobalKey _globalKey = GlobalKey();

  // 二维码数据
  void _relaodQrcodeData() {
    Map _qrcodeData = {};
    _qrcodeData["nickname"] = _appHomeController.accountModel.nickname;
    _qrcodeData["friendCode"] = _appHomeController.accountModel.friendCode;
    _qrcodeData["userId"] = _appHomeController.accountModel.userId;

    _qrcodeDataString = jsonEncode(_qrcodeData);
  }

  // 刷新二维码
  void _resetFriendCode() {
    AlertVeiw.show(
      context,
      confirmText: "刷新",
      contentText: "是否刷新二维码",
      describeText: "刷新后你将会获得新的二维码，而此前的二维码均将失效。",
      cancelText: "取消",
      confirmAction: () {
        SVProgressHUD.show();
        AccountApi.resetFriendCode().then((value) {
          if (mounted) {
            _appHomeController.accountModel.friendCode = value["friend_code"];
            _appHomeController.update(["kUpdateAccountInfo"]);
            _relaodQrcodeData();
          }

          SVProgressHUD.dismiss();
        }).catchError((error) {
          SVProgressHUD.dismiss();
        });
      },
    );
  }

  // 保存二维码
  void _saveQRCode() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext
          ?.findRenderObject() as RenderRepaintBoundary;
      var image = await boundary.toImage(
          pixelRatio: MediaQuery.of(context).devicePixelRatio);
      ByteData byteData =
          await image.toByteData(format: ImageByteFormat.png) as ByteData;
      Uint8List pageBytes = byteData.buffer.asUint8List(); //图片data
      final result =
          await ImageGallerySaver.saveImage(Uint8List.fromList(pageBytes));
      if (result == null) {
        utilsToast(msg: "二维码保存失败!");
      } else {
        utilsToast(msg: "二维码保存成功!");
      }
    } catch (e) {
      //保存失败
      utilsToast(msg: "二维码保存失败!");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("我的二维码"),
        leading: AppbarBack(),
      ),
      body: GetBuilder<AppHomeController>(
        id: "kUpdateAccountInfo",
        init: _appHomeController,
        builder: (controller) {
          _relaodQrcodeData();
          return ListView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(15.w, 34.w, 15.w, 108.w),
            children: [
              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(20.w),
                  ),
                  padding: EdgeInsets.only(top: 21.w, bottom: 18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        controller.accountModel.nickname,
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 21.w),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImage(
                            data: _qrcodeDataString.length > 0
                                ? _qrcodeDataString
                                : controller.accountModel.friendCode,
                            size: 260.w,
                            padding: EdgeInsets.zero,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(25.w),
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFCCCCCC),
                                border: Border.all(
                                  width: 4.w,
                                  color: const Color(0xFFFFFFFF),
                                ),
                                borderRadius: BorderRadius.circular(25.w),
                              ),
                              width: 50.w,
                              height: 50.w,
                              child: networkImage(
                                controller.accountModel.avatar,
                                null,
                                BorderRadius.circular(25.w),
                                memoryData: true,
                                placeholder:
                                    "images/personal_placeholder@2x.png",
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 18.w),
                      Text(
                        "扫一扫上面的二维码图案，加我为朋友",
                        style: TextStyle(
                          color: const Color(0xFFB3B3B3),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20.w),
              // 刷新二维码
              MaterialButton(
                onPressed: () {
                  _resetFriendCode();
                },
                color: const Color(0xFFFFFFFF),
                elevation: 0,
                highlightElevation: 0,
                height: 55.w,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.w),
                ),
                child: Text(
                  "刷新二维码",
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MaterialButton(
            onPressed: () {
              _saveQRCode();
            },
            padding: EdgeInsets.zero,
            minWidth: 44.w,
            height: 44.w,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            color: const Color(0xFFFFFFFF),
            elevation: 0.6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(44.w / 2),
            ),
            child: Icon(
              Icons.get_app,
              size: 28.w,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 15.w,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
