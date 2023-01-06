import 'dart:async';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/scenes/account/register_setpasswd_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class AccountCaptchaPage extends StatefulWidget {
  const AccountCaptchaPage({Key? key}) : super(key: key);

  @override
  State<AccountCaptchaPage> createState() => _AccountCaptchaPageState();
}

class _AccountCaptchaPageState extends State<AccountCaptchaPage> {
  String _phone = "";
  String _invitationhCode = "";
  String _password = "";
  String _pincode = "";
  Timer? _timer;
  int _countSecond = 59;
  int _codeLength = 6;
  FocusNode _focusNode = FocusNode();
  TextEditingController _textEditingController = TextEditingController();

  // 获取验证码
  void _sendCode() {
    FocusScope.of(context).requestFocus(FocusNode());
    SVProgressHUD.show();
    // action 1 注册验证码; 3 重置 PIN 码; 4 重置密码
    AccountApi.sms(params: {
      "mobile": "+86" + _phone,
      "action": 1,
    }).then((value) {
      SVProgressHUD.dismiss();
      _focusNode.requestFocus();
      _startTimer();
    }).catchError((error) {
      SVProgressHUD.dismiss();
    });
  }

  // 开启倒计时
  void _startTimer() {
    _closeTimer();

    _countSecond = 59;
    setState(() {});
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countSecond < 0) {
        _closeTimer();
      } else {
        _countSecond -= 1;
        setState(() {});
      }
    });
  }

  // 关闭倒计时
  void _closeTimer({bool dispose = false}) {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }

    if (dispose == false) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    if (Get.arguments != null) {
      _phone = Get.arguments["phone"] ?? "";
      _invitationhCode = Get.arguments["invitationhCode"] ?? "";
    }

    if (_phone.length > 0) {
      _startTimer();

      Future(() {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _closeTimer(dispose: true);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppbarBack(),
      ),
      body: Container(
        alignment: Alignment.topCenter,
        color: Theme.of(context).scaffoldBackgroundColor,
        padding: EdgeInsets.only(left: 40.w, right: 40.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: _phone.length == 0
              ? [
                  SizedBox(height: 31.w),
                  Text(
                    "未检测到合法手机号",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF000000),
                      fontSize: 24.sp,
                    ),
                  ),
                ]
              : [
                  SizedBox(height: 31.w),
                  Text(
                    "输入验证码",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF000000),
                      fontSize: 24.sp,
                    ),
                  ),
                  Column(
                    children: _countSecond >= 1
                        ? [
                            SizedBox(height: 6.w),
                            Text(
                              "短信验证码已发送至  ${_phone.length >= 4 ? TextUtil.hideNumber(_phone, replacement: " **** ") : _phone}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFB3B3B3),
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 7.w),
                            Text(
                              "$_countSecond秒后 重新获取",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFB3B3B3),
                                fontSize: 14.sp,
                              ),
                            ),
                            SizedBox(height: 25.w),
                          ]
                        : [
                            SizedBox(height: 32.w),
                            InkWell(
                              onTap: () {
                                _sendCode();
                              },
                              child: Text(
                                "重新获取验证码",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0XFF00BAAD),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                            SizedBox(height: 25.w),
                          ],
                  ),
                  // 验证码输入
                  PinCodeTextField(
                    appContext: context,
                    length: _codeLength,
                    autoFocus: false,
                    focusNode: _focusNode,
                    animationType: AnimationType.scale,
                    keyboardType: TextInputType.number,
                    autoDisposeControllers: false,
                    showCursor: false,
                    controller: _textEditingController,
                    textStyle: TextStyle(
                      color: const Color(0xFF000000),
                      fontSize: 50.sp,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r"[0-9]"),
                      ),
                    ],
                    pinTheme: PinTheme(
                      shape: PinCodeFieldShape.underline,
                      borderRadius: BorderRadius.circular(5),
                      fieldHeight: 73.w,
                      borderWidth: 0.5.w,
                      fieldWidth: (MediaQuery.of(context).size.width -
                              80.w -
                              15.w * (_codeLength - 1)) /
                          _codeLength,
                      inactiveColor: kAppConfig.appPlaceholderColor,
                      activeColor: const Color(0xFF000000),
                      selectedColor: kAppConfig.appPlaceholderColor,
                    ),
                    onChanged: (value) {},
                    onCompleted: (captcha) {
                      _closeTimer();
                      Get.to(
                        RegisterSetpasswdPage(),
                        arguments: {
                          "phone": _phone,
                          "captcha": captcha,
                          "invitationhCode": _invitationhCode,
                          "password": _password,
                          "pincode": _pincode,
                        },
                      )?.then((value) {
                        if (value is Map) {
                          _password = value["password"];
                          _pincode = value["pincode"];
                          _textEditingController.clear();

                          _closeTimer();
                          _countSecond = 59;

                          setState(() {
                            Future.delayed(Duration(milliseconds: 200), () {
                              _sendCode();
                            });
                          });
                        }
                      });
                    },
                  ),
                ],
        ),
      ),
    );
  }
}
