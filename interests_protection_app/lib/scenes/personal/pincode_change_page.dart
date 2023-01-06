import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/scenes/account/forgot_tab_page.dart';
import 'package:interests_protection_app/scenes/account/pincode_input_page.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class PincodeChangePage extends StatefulWidget {
  const PincodeChangePage({Key? key}) : super(key: key);

  @override
  State<PincodeChangePage> createState() => _PincodeChangePageState();
}

class _PincodeChangePageState extends State<PincodeChangePage> {
  bool _obscureText = true;
  TextEditingController _newEditingController = TextEditingController();

  bool _changeActionAble = false;
  // 两次输入PIN码不能相同
  String _errorShowText = "";

  // 输入检验
  void _checkConfirmAvialble() {
    _errorShowText = "";
    setState(() {});

    StorageUtils.getPincode((pincode) async {
      String _newPin =
          await CryptoUtils.encryptPinCode(_newEditingController.text);
      String _oldPin = pincode;
      if (_newEditingController.text.length > 0 && _newPin == _oldPin) {
        _errorShowText = "两次输入PIN码不能相同";
        _changeActionAble = false;
        setState(() {});

        return;
      }

      if (_errorShowText.length == 0 && _newPin != _oldPin) {
        _changeActionAble = true;
      } else {
        _changeActionAble = false;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _newEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppConfig.appThemeColor,
        titleSpacing: 0,
        elevation: 0,
        toolbarHeight: 0,
        leadingWidth: 0,
        leading: SizedBox(),
      ),
      body: Column(
        children: [
          // bar
          Container(
            height: AppBar().preferredSize.height,
            width: MediaQuery.of(context).size.width,
            color: kAppConfig.appThemeColor,
            child: Row(
              children: [
                AppbarBack(iconColor: const Color(0xFFFFFFFF)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: kAppConfig.appThemeColor,
                alignment: Alignment.center,
                margin: EdgeInsets.only(bottom: 0.5.w),
                child: Column(
                  children: [
                    SizedBox(height: 6.w),
                    Text(
                      "修改PIN码",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 24.sp,
                      ),
                    ),
                    SizedBox(height: 7.w),
                    Text(
                      "PIN码由4位数字组成\n不能使用紧急PIN码修改PIN码",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF0A5A5),
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 21.w + 19.w),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 19.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.w),
                      topRight: Radius.circular(20.w),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
              ),
              alignment: Alignment.topCenter,
              padding: EdgeInsets.only(top: 13.w, left: 45.w, right: 45.w),
              child: Column(
                children: [
                  Container(
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAF7),
                      borderRadius: BorderRadius.circular(40.w),
                    ),
                    child: MaterialButton(
                      onPressed: () {
                        Get.to(PincodeInputPage())?.then((value) {
                          if (value is String && value.length > 0) {
                            _newEditingController.text = "$value";
                            _checkConfirmAvialble();
                          }
                        });
                      },
                      hoverColor: const Color(0xFFFAFAF7),
                      elevation: 0,
                      highlightElevation: 0,
                      hoverElevation: 0,
                      focusElevation: 0,
                      padding: EdgeInsets.only(left: 28.w, right: 20.w),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.w),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              enabled: false,
                              obscureText: _obscureText,
                              controller: _newEditingController,
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.normal,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "请输入新的PIN码",
                                hintStyle: TextStyle(
                                  color: kAppConfig.appPlaceholderColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _obscureText = !_obscureText;
                              setState(() {});
                            },
                            child: Image.asset(
                              !_obscureText
                                  ? "images/login_show@3x.png"
                                  : "images/login_hide@3x.png",
                              width: 16.w,
                              height: 16.w,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 34.w),
                  Container(
                    height: 45.w,
                    decoration: BoxDecoration(
                      color: _changeActionAble
                          ? kAppConfig.appThemeColor
                          : const Color(0xFFEDD5D5),
                      borderRadius: BorderRadius.circular(40.w),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: MaterialButton(
                            onPressed: _changeActionAble
                                ? () {
                                    SVProgressHUD.show();
                                    StorageUtils.getPincode((pincode) async {
                                      String _newPin =
                                          await CryptoUtils.encryptPinCode(
                                              _newEditingController.text);
                                      String _oldPin = pincode;

                                      AccountApi.replacePincode(params: {
                                        "pin": _newPin,
                                        "old_pin": _oldPin,
                                        "is_x": false,
                                      }).then((value) {
                                        StorageUtils.setPincode(_newPin);

                                        SVProgressHUD.dismiss();
                                        Get.back();

                                        utilsToast(msg: "PIN码修改成功");
                                      }).catchError((error) {
                                        SVProgressHUD.dismiss();
                                      });
                                    });
                                  }
                                : null,
                            padding: EdgeInsets.only(left: 28.w, right: 20.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(40.w),
                            ),
                            height: 45.w,
                            child: Text(
                              "确认",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFFFFFFF),
                                fontSize: 18.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 82.w - 16.w,
                    alignment: Alignment.center,
                    padding: EdgeInsets.only(top: 4.w),
                    child: Text(
                      _errorShowText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kAppConfig.appThemeColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.normal,
                        height: 1.5,
                      ),
                    ),
                  ),
                  MaterialButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) {
                          return ForgotTabPage(tab: 1);
                        },
                        fullscreenDialog: true,
                      ));
                    },
                    child: Text(
                      "忘记旧PIN码",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFB3B3B3),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
