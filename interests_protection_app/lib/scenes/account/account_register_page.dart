import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/scenes/account/account_captcha_page.dart';
import 'package:interests_protection_app/scenes/account/forgot_tab_page.dart';
import 'package:interests_protection_app/scenes/account/widgets/joggle_text_field.dart';
import 'package:interests_protection_app/scenes/personal/personal_agressment_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:oktoast/oktoast.dart';

class AccountRegisterPage extends StatefulWidget {
  const AccountRegisterPage({Key? key}) : super(key: key);

  @override
  State<AccountRegisterPage> createState() => _AccountRegisterPageState();
}

class _AccountRegisterPageState extends State<AccountRegisterPage> {
  JoggleTextFieldController _phoneController = JoggleTextFieldController();
  TextEditingController _codeController = TextEditingController();
  bool _codeActionAble = false;
  bool _agreementCheck = false;
  String _areaCode = "+86";

  String _errorShowText = "";

  // 同意协议弹框
  void _showAgreementDialog() {
    showGeneralDialog(
      context: context,
      barrierColor: const Color(0x7F000000),
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(20.w),
                child: Container(
                  width: 295.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(20.w),
                  ),
                  padding: EdgeInsets.fromLTRB(19.w, 24.w, 19.w, 23.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "隐私政策",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 18.sp,
                        ),
                      ),
                      SizedBox(height: 9.w),
                      Text(
                        "请先同意《用户隐私协议与声明》",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFFB3B3B3),
                          fontSize: 14.sp,
                        ),
                      ),
                      SizedBox(height: 23.w),
                      Row(
                        children: [
                          // 取消
                          Expanded(
                            child: MaterialButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              padding: EdgeInsets.zero,
                              height: 44.w,
                              elevation: 0,
                              highlightElevation: 0,
                              color: const Color(0xFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22.w),
                                side: BorderSide(
                                  width: 1.w,
                                  color: kAppConfig.appPlaceholderColor,
                                ),
                              ),
                              child: Text(
                                "取消",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF000000),
                                  fontSize: 15.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 17.w),
                          // 同意
                          Expanded(
                            child: MaterialButton(
                              onPressed: () {
                                Navigator.of(context).pop();

                                _agreementCheck = true;
                                setState(() {});
                              },
                              padding: EdgeInsets.zero,
                              height: 44.w,
                              color: kAppConfig.appThemeColor,
                              elevation: 0,
                              highlightElevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22.w),
                              ),
                              child: Text(
                                "同意",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFFFFFFFF),
                                  fontSize: 15.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 账号已存在
  void _accountExistDialog() {
    showGeneralDialog(
      context: context,
      barrierColor: const Color(0x7F000000),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Center(
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(20.w),
              child: Container(
                width: 295.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(20.w),
                ),
                padding: EdgeInsets.fromLTRB(19.w, 23.w, 19.w, 23.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 9.w, right: 9.w),
                      child: Text(
                        "该账号已存在，若确认是您本人注册可直接登录或点击忘记密码，若非您本人注册，请退出重新注册。",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 23.w),
                    Row(
                      children: [
                        // 忘记密码
                        Expanded(
                          child: MaterialButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Get.to(ForgotTabPage(resetComplete: true));
                            },
                            padding: EdgeInsets.zero,
                            height: 44.w,
                            elevation: 0,
                            highlightElevation: 0,
                            color: const Color(0xFFFFFFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22.w),
                              side: BorderSide(
                                width: 1.w,
                                color: kAppConfig.appPlaceholderColor,
                              ),
                            ),
                            child: Text(
                              "忘记密码",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 17.w),
                        // 立即登录
                        Expanded(
                          child: MaterialButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              Get.back();
                            },
                            padding: EdgeInsets.zero,
                            height: 44.w,
                            color: kAppConfig.appThemeColor,
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
                              "立即登录",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFFFFFFF),
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // 获取验证码
  void _sendCode() {
    FocusScope.of(context).requestFocus(FocusNode());
    SVProgressHUD.show();
    // action 1 注册验证码; 3 重置 PIN 码; 4 重置密码
    AccountApi.sms(params: {
      "mobile": "$_areaCode" +
          _phoneController.editingController.text.replaceAll(" ", ""),
      "action": 1,
    }).then((value) {
      SVProgressHUD.dismiss();

      Get.to(
        AccountCaptchaPage(),
        arguments: {
          "phone": _phoneController.editingController.text.replaceAll(" ", ""),
          "invitationhCode": _codeController.text.replaceAll(" ", ""),
        },
      );
    }).catchError((error) {
      SVProgressHUD.dismiss();
      if (error["code"] == 20201) {
        dismissAllToast();
        _accountExistDialog();
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: SizedBox(),
        toolbarHeight: 72.w,
        actions: [
          IconButton(
            onPressed: () {
              Get.back();
            },
            padding: EdgeInsets.zero,
            icon: Image.asset(
              "images/register_close@2x.png",
              width: 21.w,
              height: 21.w,
            ),
          ),
          SizedBox(width: 10.w),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Container(
          alignment: Alignment.topCenter,
          color: Theme.of(context).scaffoldBackgroundColor,
          padding: EdgeInsets.only(left: 54.w, right: 54.w),
          child: Column(
            children: [
              Text(
                "注册账号",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 24.sp,
                ),
              ),
              SizedBox(height: 53.w),
              // 步骤
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: kAppConfig.appThemeColor,
                      borderRadius: BorderRadius.circular(36.w / 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "1",
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 84.w,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6.w,
                            color: kAppConfig.appThemeColor,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 6.w,
                            color: kAppConfig.appPlaceholderColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      color: kAppConfig.appPlaceholderColor,
                      borderRadius: BorderRadius.circular(36.w / 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "2",
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 18.sp,
                      ),
                    ),
                  ),
                ],
              ),
              // 错误提示
              Container(
                height: 53.w,
                alignment: Alignment.center,
                padding: EdgeInsets.only(top: 6.w),
                child: Text(
                  _errorShowText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kAppConfig.appErrorColor,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              // 输入手机号
              JoggleTextField(
                controller: _phoneController,
                textFieldType: JoggleTextFieldType.mobile,
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                areaCodeHandle: (areaCode) {
                  _areaCode = areaCode;
                  setState(() {});
                },
                onChanged: (value) {
                  if (_errorShowText.length == 0 &&
                      value.replaceAll(" ", "").length == 11) {
                    _codeActionAble = true;
                  } else {
                    _codeActionAble = false;
                  }

                  setState(() {});
                },
                onSubmitted: (value) {
                  FocusScope.of(context).requestFocus(FocusNode());

                  if (_errorShowText.length == 0 &&
                      value.replaceAll(" ", "").length == 11) {
                    _codeActionAble = true;
                  } else {
                    _codeActionAble = false;
                  }

                  setState(() {});

                  if (_agreementCheck == false) {
                    _showAgreementDialog();
                    return;
                  }

                  _sendCode();
                },
              ),
              SizedBox(height: 13.w),
              // 邀请码
              Container(
                height: 48.w,
                padding: EdgeInsets.only(left: 22.w, right: 22.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(48.w / 2),
                ),
                child: Row(
                  children: [
                    Text(
                      "邀请码",
                      style: TextStyle(
                        color: const Color(0xFFC4C4C4),
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _codeController,
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 20.sp,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(
                              RegExp('[\\s]')), // 空格
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          if (_codeActionAble) {
                            _sendCode();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 19.w),
              // 获取验证码
              MaterialButton(
                onPressed: _codeActionAble == false
                    ? null
                    : () {
                        FocusScope.of(context).requestFocus(FocusNode());

                        if (_agreementCheck == false) {
                          _showAgreementDialog();
                          return;
                        }

                        _sendCode();
                      },
                color: kAppConfig.appThemeColor,
                disabledColor: kAppConfig.appDisableColor,
                elevation: 0,
                highlightElevation: 0,
                height: 95.w / 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(95.w / 4),
                ),
                child: Center(
                  child: Text(
                    "完成注册",
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF),
                      fontSize: 18.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 62.w),
              // 用户协议
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());

                      _agreementCheck = !_agreementCheck;
                      setState(() {});
                    },
                    child: Row(
                      children: [
                        Image.asset(
                          _agreementCheck
                              ? "images/register_checked@2x.png"
                              : "images/register_check@2x.png",
                          width: 16.w,
                          height: 16.w,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          "我已阅读",
                          style: TextStyle(
                            color: const Color(0xFFB3B3B3),
                            fontSize: 15.sp,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            FocusScope.of(context).requestFocus(FocusNode());
                            Get.to(PersonalAgressmentPage());
                          },
                          child: Text(
                            "《用户隐私协议与声明》",
                            style: TextStyle(
                              color: kAppConfig.appErrorColor,
                              fontSize: 15.sp,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
