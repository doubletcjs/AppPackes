import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/scenes/contacts/tag_manager_page.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class FriendScanApplay extends StatefulWidget {
  final List<int> rawBytes;
  const FriendScanApplay({Key? key, required this.rawBytes}) : super(key: key);

  @override
  State<FriendScanApplay> createState() => _FriendScanApplayState();
}

class _FriendScanApplayState extends State<FriendScanApplay> {
  AppHomeController _appHomeController = Get.find<AppHomeController>();
  TextEditingController _textEditingController = TextEditingController();
  Map _qrcodeData = {};
  List<String> _friendTagList = [];

  // 发送好友申请
  void _sendApplay() {
    SVProgressHUD.show();
    AccountApi.applyFriends(params: {
      "friend_code": _qrcodeData["friendCode"],
      "content": _textEditingController.text,
      "tags": _friendTagList,
    }).then((value) async {
      List _list = await _appHomeController.accountDB!.query(
        kAppFriendTableName,
        where: "userId = '${_qrcodeData['userId']}'",
        limit: 1,
      );

      if (_list.length == 0) {
        _appHomeController.accountDB!.insert(
          kAppFriendTableName,
          {
            "tags": jsonEncode(_friendTagList),
            "userId": "${_qrcodeData['userId']}",
            "remark": _textEditingController.text,
          },
        );
      } else {
        _appHomeController.accountDB!.update(
          kAppFriendTableName,
          {
            "tags": jsonEncode(_friendTagList),
            "remark": _textEditingController.text,
          },
          where: "userId = '${_qrcodeData['userId']}'",
        );
      }

      SVProgressHUD.dismiss();
      Get.back();
    }).catchError((error) {
      SVProgressHUD.dismiss();
    });
  }

  @override
  void initState() {
    super.initState();

    _qrcodeData = jsonDecode(utf8.decode(widget.rawBytes));

    Future(() {
      if (mounted) {
        _appHomeController.friendsInfo(id: _qrcodeData["userId"]).then((model) {
          if (mounted && model.userId.length > 0) {
            _qrcodeData["nickname"] = model.nickname;
            setState(() {});
          }
        }).catchError((error) {});
      }
    });
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("申请添加"),
        leading: AppbarBack(),
        actions: [
          MaterialButton(
            onPressed: () {
              _sendApplay();
            },
            minWidth: 44.w,
            height: 44.w,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(44.w / 2),
            ),
            child: Text(
              "发送",
              style: TextStyle(
                fontSize: 15.sp,
                color: const Color(0xFF000000),
              ),
            ),
          ),
          SizedBox(width: 11.w),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: ListView(
          physics: BouncingScrollPhysics(),
          children: [
            Center(
              child: Column(
                children: [
                  SizedBox(height: 38.w),
                  networkImage(
                    kAppConfig.avatar(_qrcodeData["userId"]),
                    Size(48.w, 48.w),
                    BorderRadius.circular(5.w),
                    placeholder: "images/personal_placeholder@2x.png",
                  ),
                  SizedBox(height: 12.w),
                  Text(
                    "${_qrcodeData['nickname']}",
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  SizedBox(height: 29.w),
                ],
              ),
            ),
            MaterialButton(
              onPressed: null,
              height: 56.w,
              disabledColor: const Color(0xFFFFFFFF),
              elevation: 0,
              highlightElevation: 0,
              focusElevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: EdgeInsets.only(left: 17.w, right: 17.w),
              child: Row(
                children: [
                  Text(
                    "备注",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: const Color(0xFF808080),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: TextField(
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: const Color(0xFF000000),
                      ),
                      controller: _textEditingController,
                      decoration: InputDecoration(
                        hintText: "设置备注",
                        hintStyle: TextStyle(
                          fontSize: 15.sp,
                          color: kAppConfig.appPlaceholderColor,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.w),
            MaterialButton(
              onPressed: () {
                FocusScope.of(context).requestFocus(FocusNode());

                Navigator.of(context)
                    .push(MaterialPageRoute(
                  builder: (context) {
                    return TagManagerPage(
                      selectTabList: _friendTagList,
                    );
                  },
                  fullscreenDialog: true,
                ))
                    .then((value) {
                  if (value is List) {
                    _friendTagList = List<String>.from(value);
                    setState(() {});
                  }
                });
              },
              height: 56.w,
              color: const Color(0xFFFFFFFF),
              elevation: 0,
              highlightElevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              padding: EdgeInsets.only(left: 17.w, right: 17.w),
              child: Row(
                children: [
                  Text(
                    "标签",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: const Color(0xFF808080),
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Text(
                      "未设置",
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: kAppConfig.appPlaceholderColor,
                      ),
                    ),
                  ),
                  Image.asset(
                    "images/personal_arrow@2x.png",
                    width: 24.w,
                    height: 24.w,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
