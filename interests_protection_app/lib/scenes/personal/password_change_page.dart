import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/scenes/account/forgot_tab_page.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class PasswordChangePage extends StatefulWidget {
  const PasswordChangePage({Key? key}) : super(key: key);

  @override
  State<PasswordChangePage> createState() => _PasswordChangePageState();
}

class _PasswordChangePageState extends State<PasswordChangePage> {
  bool _oldObscureText = true;
  bool _newObscureText = true;
  TextEditingController _oldEditingController = TextEditingController();
  TextEditingController _newEditingController = TextEditingController();
  FocusNode _oldFocusNode = FocusNode();
  FocusNode _newFocusNode = FocusNode();

  bool _changeActionAble = false;
  // 须包含数字、字母、符号中至少2种元素密码长度须8-16位
  // 两次输入密码不能相同
  String _errorShowText = "";

  // 输入检验
  void _checkConfirmAvialble(bool checkOld) {
    _errorShowText = "";
    setState(() {});

    if (checkOld) {
      if (passwordRegExp(_oldEditingController.text) == false) {
        _errorShowText = "须包含数字、字母、符号3种元素\n密码长度须8-16位";
        _changeActionAble = false;
        setState(() {});

        return;
      }

      if (_newEditingController.text.length > 0 &&
          passwordRegExp(_newEditingController.text) == false) {
        _errorShowText = "须包含数字、字母、符号3种元素\n密码长度须8-16位";
        _changeActionAble = false;
        setState(() {});

        return;
      }
    } else {
      if (passwordRegExp(_newEditingController.text) == false) {
        _errorShowText = "须包含数字、字母、符号3种元素\n密码长度须8-16位";
        _changeActionAble = false;
        setState(() {});

        return;
      }
    }

    if (_oldEditingController.text.length > 0 &&
        _newEditingController.text.length > 0 &&
        _newEditingController.text == _oldEditingController.text) {
      _errorShowText = "两次输入密码不能相同";
      _changeActionAble = false;
      setState(() {});

      return;
    }

    if (_oldEditingController.text.length > 0 &&
        _newEditingController.text.length > 0 &&
        _newEditingController.text != _oldEditingController.text) {
      _changeActionAble = true;
    } else {
      _changeActionAble = false;
    }

    setState(() {});
  }

  void _onSubmit() {
    SVProgressHUD.show();
    AccountApi.password(params: {
      "password": CryptoUtils.md5(_newEditingController.text.trim()),
      "old_password": CryptoUtils.md5(_oldEditingController.text.trim()),
    }).then((value) {
      SVProgressHUD.dismiss();
      Get.back();
    }).catchError((error) {
      SVProgressHUD.dismiss();
    });
  }

  @override
  void dispose() {
    _oldEditingController.dispose();
    _newEditingController.dispose();
    _oldFocusNode.dispose();
    _newFocusNode.dispose();
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
                      "修改密码",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 24.sp,
                      ),
                    ),
                    SizedBox(height: 7.w),
                    Text(
                      "须包含数字、字母、符号3种元素\n密码长度须8-16位",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFF0A5A5),
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 21.w + 20.w),
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
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                ),
                alignment: Alignment.topCenter,
                padding: EdgeInsets.only(top: 13.w, left: 45.w, right: 45.w),
                child: ListView(
                  children: [
                    Container(
                      height: 45.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAF7),
                        borderRadius: BorderRadius.circular(40.w),
                      ),
                      padding: EdgeInsets.only(left: 28.w, right: 20.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _oldEditingController,
                              obscureText: _oldObscureText,
                              maxLength: 16,
                              focusNode: _oldFocusNode,
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.normal,
                              ),
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "请输入旧密码",
                                hintStyle: TextStyle(
                                  color: kAppConfig.appPlaceholderColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                ),
                                counterText: "",
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                    RegExp('[\\s]')), // 空格
                              ],
                              onChanged: (value) {
                                _checkConfirmAvialble(true);
                              },
                              onSubmitted: (value) {
                                if (value.trim().length > 0 &&
                                    passwordRegExp(
                                        _oldEditingController.text)) {
                                  _newFocusNode.requestFocus();
                                } else {
                                  _oldFocusNode.requestFocus();
                                }
                              },
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _oldObscureText = !_oldObscureText;
                              setState(() {});
                            },
                            child: Image.asset(
                              !_oldObscureText
                                  ? "images/login_show@3x.png"
                                  : "images/login_hide@3x.png",
                              width: 16.w,
                              height: 16.w,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15.w),
                    Container(
                      height: 45.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAF7),
                        borderRadius: BorderRadius.circular(40.w),
                      ),
                      padding: EdgeInsets.only(left: 28.w, right: 20.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              obscureText: _newObscureText,
                              controller: _newEditingController,
                              maxLength: 16,
                              focusNode: _newFocusNode,
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 15.sp,
                                fontWeight: FontWeight.normal,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "请输入新的密码",
                                hintStyle: TextStyle(
                                  color: kAppConfig.appPlaceholderColor,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                ),
                                counterText: "",
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.deny(
                                    RegExp('[\\s]')), // 空格
                              ],
                              onChanged: (value) {
                                _checkConfirmAvialble(false);
                              },
                              onSubmitted: (value) {
                                if (_changeActionAble) {
                                  _onSubmit();
                                } else {
                                  _newFocusNode.requestFocus();
                                }
                              },
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              _newObscureText = !_newObscureText;
                              setState(() {});
                            },
                            child: Image.asset(
                              !_newObscureText
                                  ? "images/login_show@3x.png"
                                  : "images/login_hide@3x.png",
                              width: 16.w,
                              height: 16.w,
                            ),
                          ),
                        ],
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
                                      _onSubmit();
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
                    Align(
                      child: MaterialButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) {
                                return ForgotTabPage();
                              },
                              fullscreenDialog: true,
                            ),
                          );
                        },
                        child: Text(
                          "忘记旧密码",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFB3B3B3),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
