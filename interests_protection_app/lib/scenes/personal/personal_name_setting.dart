import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class PersonalNameSetting extends StatefulWidget {
  const PersonalNameSetting({Key? key}) : super(key: key);

  @override
  State<PersonalNameSetting> createState() => _PersonalNameSettingState();
}

class _PersonalNameSettingState extends State<PersonalNameSetting> {
  final TextEditingController _editingController = TextEditingController();
  final AppHomeController _appHomeController = Get.find<AppHomeController>();
  bool _canSubmit = false;

  // 以英文字母或汉字开头，限4-16个字符，一个汉字为2个字符。
  bool _nicknameCheck(String str) {
    if (str.length == 0) {
      return false;
    }

    var ta = str.split("");
    var strL = 0;
    var strFa = str.codeUnitAt(0);
    if ((strFa >= 65 && strFa <= 90) ||
        (strFa >= 97 && strFa <= 122) ||
        (strFa > 255)) {
      for (var i = 0; i < ta.length - 1; i++) {
        strL += 1;
        if (ta[i].codeUnitAt(0) > 255) {
          strL += 1;
        }

        if (strL >= 4 && strL <= 16) {
          return true;
        }
      }
    }

    return false;
  }

  // 提交
  void _onSubmit() {
    void _submit() {
      _appHomeController.updateAccountInfo(
        params: {"nickname": _editingController.text},
        finish: () {
          utilsToast(msg: "修改成功");
          Get.back();
        },
      );
    }

    if (_appHomeController.accountModel.nickname.length > 0) {
      AlertVeiw.show(
        context,
        confirmText: "确认",
        cancelText: "取消",
        contentText: "是否保存已修改的名字？",
        confirmAction: () {
          _submit();
        },
      );
    } else {
      _submit();
    }
  }

  // 校验
  void _checkAviable() {
    if (_nicknameCheck(_editingController.text) &&
        _editingController.text != _appHomeController.accountModel.nickname) {
      _canSubmit = true;
    } else {
      _canSubmit = false;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _editingController.text = _appHomeController.accountModel.nickname;
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text("设置名字"),
        leading: AppbarBack(),
        actions: [
          IconButton(
            onPressed: _canSubmit
                ? () {
                    _onSubmit();
                  }
                : null,
            padding: EdgeInsets.zero,
            icon: Text(
              "完成",
              style: TextStyle(
                fontSize: 15.sp,
                color: _canSubmit
                    ? const Color(0xFF000000)
                    : kAppConfig.appPlaceholderColor,
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
          padding: EdgeInsets.only(top: 14.w),
          physics: BouncingScrollPhysics(),
          children: [
            Container(
              height: 56.w,
              color: const Color(0xFFFFFFFF),
              padding: EdgeInsets.only(left: 16.w, right: 22.w),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _editingController,
                      style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: 15.sp,
                      ),
                      maxLength: 16,
                      decoration: InputDecoration(
                        hintText: "设置我的名字",
                        hintStyle: TextStyle(
                          color: const Color(0xFF808080),
                          fontSize: 15.sp,
                        ),
                        counterText: "",
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        _checkAviable();
                      },
                      onSubmitted: (value) {
                        if (value == " " || value.trim().length == 0) {
                          _editingController.clear();
                          _checkAviable();
                        } else if (value.trim().length > 0 && _canSubmit) {
                          _onSubmit();
                        }
                      },
                    ),
                  ),
                  GetBuilder<AppHomeController>(
                    init: _appHomeController,
                    id: "kUpdateAccountInfo",
                    builder: (controller) {
                      return controller.accountModel.real == 1
                          ? Container(
                              margin: EdgeInsets.only(left: 8.w),
                              padding: EdgeInsets.only(left: 10.w, right: 10.w),
                              height: 23.w,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 0.5.w,
                                  color: const Color(0xFFC99663),
                                ),
                                borderRadius: BorderRadius.circular(5.w),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                "已实名",
                                style: TextStyle(
                                  color: const Color(0xFFC99663),
                                  fontSize: 12.sp,
                                ),
                              ),
                            )
                          : SizedBox();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.w),
            Padding(
              padding: EdgeInsets.only(left: 16.w, right: 16.w),
              child: Text(
                "以英文字母或汉字开头，限4-16个字符，一个汉字为2个字符。",
                style: TextStyle(
                  color: const Color(0xFFB3B3B3),
                  fontSize: 14.sp,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
