import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/scenes/contacts/friend_scan_applay.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/image_picker.dart';
import 'package:scan/scan.dart';

class FriendScanPage extends StatefulWidget {
  const FriendScanPage({Key? key}) : super(key: key);

  @override
  State<FriendScanPage> createState() => _FriendScanPageState();
}

class _FriendScanPageState extends State<FriendScanPage> {
  ScanController _scanController = ScanController();

  void _handleQrcodeData(String data) {
    _scanController.pause();

    try {
      Map _qrcodeData = jsonDecode(data);
      // {"nickname":"Sam4985","friendCode":"bbfd85f7d1e2a7c868e0RFeA4","userId":"63047e6aa707b43249a58bb9"}
      if (_qrcodeData.containsKey("nickname") &&
          _qrcodeData.containsKey("friendCode") &&
          _qrcodeData.containsKey("userId")) {
        AppHomeController _appHomeController = Get.find<AppHomeController>();
        if (_qrcodeData["userId"] == _appHomeController.accountModel.userId) {
          AlertVeiw.show(
            context,
            confirmText: "确定",
            contentText: "不能添加自己",
            confirmAction: () {
              Future.delayed(Duration(milliseconds: 300), () {
                _scanController.resume();
              });
            },
          );
        } else {
          bool _isFriend = false;
          var _list = jsonDecode(_appHomeController.accountModel.friends);
          List _friendList = List.from(_list.runtimeType == String
              ? ("$_list".length == 0 ? [] : jsonDecode(_list))
              : _list);
          _friendList.forEach((element) {
            if (element["id"] == _qrcodeData["userId"]) {
              _isFriend = true;
            }
          });

          if (_isFriend == false) {
            Get.off(FriendScanApplay(rawBytes: utf8.encode(data)));
          } else {
            AlertVeiw.show(
              context,
              confirmText: "确定",
              contentText: "已是好友",
              confirmAction: () {
                Future.delayed(Duration(milliseconds: 300), () {
                  _scanController.resume();
                });
              },
            );
          }
        }
      } else {
        AlertVeiw.show(
          context,
          confirmText: "确定",
          contentText: "无法识别二维码",
          confirmAction: () {
            Future.delayed(Duration(milliseconds: 300), () {
              _scanController.resume();
            });
          },
        );
      }
    } catch (e) {
      AlertVeiw.show(
        context,
        confirmText: "确定",
        contentText: "无法识别二维码",
        confirmAction: () {
          Future.delayed(Duration(milliseconds: 300), () {
            _scanController.resume();
          });
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scanController.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.center,
        children: [
          ScanView(
            controller: _scanController,
            scanAreaScale: .7,
            scanLineColor: const Color(0xFFFFFFFF),
            onCapture: (data) {
              _handleQrcodeData(data);
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 5.w,
            child: MaterialButton(
              onPressed: () {
                Get.back();
              },
              minWidth: 44.w,
              height: 44.w,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(44.w / 2),
              ),
              child: Center(
                child: Image.asset(
                  "images/scan_close@2x.png",
                  width: 24.w,
                  height: 24.w,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top,
            right: 5.w,
            child: MaterialButton(
              onPressed: () {
                _scanController.pause();
                ImagePicker.pick(context, count: 1, compress: false).then(
                  (value) async {
                    if (value.length > 0) {
                      String? _result = await Scan.parse(value.first.path);
                      _handleQrcodeData(_result ?? "");
                    } else {
                      _scanController.resume();
                    }
                  },
                );
              },
              minWidth: 44.w,
              height: 44.w,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(44.w / 2),
              ),
              child: Center(
                child: Icon(
                  Icons.photo,
                  color: Colors.white,
                  size: 24.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
