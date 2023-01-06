import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class PersonalMobileSetting extends StatefulWidget {
  const PersonalMobileSetting({Key? key}) : super(key: key);

  @override
  State<PersonalMobileSetting> createState() => _PersonalMobileSettingState();
}

class _PersonalMobileSettingState extends State<PersonalMobileSetting> {
  final TextEditingController _editingController = TextEditingController();
  final AppHomeController _appHomeController = Get.find<AppHomeController>();
  bool _canSubmit = false;

  // 提交
  void _onSubmit() {
    void _submit() {
      _appHomeController.updateAccountInfo(
        params: {
          "emergency_phone": _editingController.text.replaceAll(" ", "")
        },
        finish: () {
          utilsToast(msg: "修改成功");
          Get.back();
        },
      );
    }

    if (_appHomeController.accountModel.emergencyPhone.length > 0) {
      AlertVeiw.show(
        context,
        confirmText: "确认",
        cancelText: "取消",
        contentText: "是否保存已修改的号码？",
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
    if (_editingController.text.replaceAll(" ", "").length == 11 &&
        _editingController.text.replaceAll(" ", "") !=
            _appHomeController.accountModel.emergencyPhone) {
      _canSubmit = true;
    } else {
      _canSubmit = false;
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _editingController.text =
        phoneFormat(_appHomeController.accountModel.emergencyPhone);
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
        title: Text("紧急联系电话"),
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
                  Text(
                    "紧急联系电话",
                    style: TextStyle(
                      color: const Color(0xFF808080),
                      fontSize: 15.sp,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: TextField(
                      controller: _editingController,
                      style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: 15.sp,
                      ),
                      maxLength: 16,
                      decoration: InputDecoration(
                        hintText: "设置紧急联系电话",
                        hintStyle: TextStyle(
                          color: const Color(0xFF808080),
                          fontSize: 15.sp,
                        ),
                        counterText: "",
                        border: InputBorder.none,
                      ),
                      inputFormatters: phoneInputFormatters(),
                      onChanged: (value) {
                        _checkAviable();
                      },
                      textInputAction: TextInputAction.done,
                      onSubmitted: (value) {
                        if (value.trim().length > 0 && _canSubmit) {
                          _onSubmit();
                        }
                      },
                    ),
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
