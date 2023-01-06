import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/scenes/account/pincode_input_page.dart';
import 'package:interests_protection_app/scenes/account/register_complete_page.dart';
import 'package:interests_protection_app/scenes/account/widgets/joggle_text_field.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';
import 'package:oktoast/oktoast.dart';

class RegisterSetpasswdPage extends StatefulWidget {
  const RegisterSetpasswdPage({Key? key}) : super(key: key);

  @override
  State<RegisterSetpasswdPage> createState() => _RegisterSetpasswdPageState();
}

class _RegisterSetpasswdPageState extends State<RegisterSetpasswdPage> {
  JoggleTextFieldController _passwordController = JoggleTextFieldController();
  JoggleTextFieldController _confirmPasswordController =
      JoggleTextFieldController();
  JoggleTextFieldController _pincodeController = JoggleTextFieldController();

  String _phone = "";
  String _captcha = "";
  String _invitationhCode = "";

  bool _registerActionAble = false;
  // 密码必须是8位或以上字母数字及特殊字符组合
  // 两次密码输入不一致
  String _errorShowText = "";

  // 输入检验
  void _checkConfirmAvialble() {
    _errorShowText = "";
    setState(() {});

    if (passwordRegExp(_passwordController.editingController.text) == false) {
      _errorShowText = "密码必须是8位或以上字母数字及特殊字符组合";
      setState(() {});

      return;
    }

    if (_passwordController.editingController.text.length > 0 &&
        _confirmPasswordController.editingController.text !=
            _passwordController.editingController.text) {
      _errorShowText = "两次密码输入不一致";
      setState(() {});

      return;
    }

    if (_passwordController.editingController.text.trim().length > 0 &&
        _confirmPasswordController.editingController.text ==
            _passwordController.editingController.text &&
        _pincodeController.editingController.text.trim().length > 0) {
      _registerActionAble = true;
    } else {
      _registerActionAble = false;
    }

    setState(() {});
  }

  // 提交注册
  void _registerSubmit() async {
    FocusScope.of(context).requestFocus(FocusNode());
    SVProgressHUD.show();

    String _encryptPinCode = await CryptoUtils.encryptPinCode(
        _pincodeController.editingController.text.replaceAll(" ", ""));

    var params = {
      "mobile": "+86" + _phone,
      "password": CryptoUtils.md5(_confirmPasswordController
          .editingController.text
          .replaceAll(" ", "")),
      "code": _captcha,
      "pin": _encryptPinCode,
      "invitation_code": _invitationhCode,
    };

    AccountApi.register(params: params).then((value) {
      SVProgressHUD.dismiss();
      Get.offAll(RegisterCompletePage(), arguments: {
        "phone": _phone,
        "real": (value ?? {})["real"] ?? false,
      });
    }).catchError((error) {
      SVProgressHUD.dismiss();
      if (error["code"] == 20106) {
        dismissAllToast();
        AlertVeiw.show(
          context,
          confirmText: "重新验证",
          contentText: "",
          contentWidget: Padding(
            padding: EdgeInsets.only(top: 40.w, bottom: 32.w),
            child: Center(
              child: Text(
                "验证码错误！",
                style: TextStyle(
                  color: kAppConfig.appThemeColor,
                  fontSize: 18.sp,
                ),
              ),
            ),
          ),
          confirmAction: () {
            Get.back(result: {
              "password": _confirmPasswordController.editingController.text,
              "pincode": _pincodeController.editingController.text,
            });
          },
          onWillPop: false,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    if (Get.arguments != null) {
      _phone = Get.arguments["phone"] ?? "";
      _captcha = Get.arguments["captcha"] ?? "";
      _invitationhCode = Get.arguments["invitationhCode"] ?? "";
      _passwordController.editingController.text =
          Get.arguments["password"] ?? "";
      _confirmPasswordController.editingController.text =
          Get.arguments["password"] ?? "";
      _pincodeController.editingController.text =
          Get.arguments["pincode"] ?? "";

      _checkConfirmAvialble();
    }
  }

  @override
  void dispose() {
    _confirmPasswordController.dispose();
    _passwordController.dispose();
    _pincodeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppbarBack(),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: MediaQuery.of(context).viewInsets.bottom,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.only(left: 54.w, right: 54.w),
                physics: BouncingScrollPhysics(),
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
                    : _captcha.length == 0
                        ? [
                            SizedBox(height: 31.w),
                            Text(
                              "未检测到合法验证码",
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
                              "注册账号",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 24.sp,
                              ),
                            ),
                            SizedBox(height: 53.w),
                            //  步骤
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: kAppConfig.appThemeColor,
                                    borderRadius:
                                        BorderRadius.circular(36.w / 2),
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
                                          color: kAppConfig.appThemeColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 36.w,
                                  height: 36.w,
                                  decoration: BoxDecoration(
                                    color: kAppConfig.appThemeColor,
                                    borderRadius:
                                        BorderRadius.circular(36.w / 2),
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
                            // 密码
                            JoggleTextField(
                              controller: _passwordController,
                              textFieldType: JoggleTextFieldType.password,
                              onEditingComplete: () {
                                _confirmPasswordController.focusNode
                                    .requestFocus();
                              },
                              onChanged: (value) {
                                _checkConfirmAvialble();
                              },
                            ),
                            SizedBox(height: 11.w),
                            // 确认密码
                            JoggleTextField(
                              controller: _confirmPasswordController,
                              textFieldType: JoggleTextFieldType.password,
                              placeholder: "请再次输入密码",
                              onEditingComplete: () {},
                              onChanged: (value) {
                                _checkConfirmAvialble();
                              },
                              onSubmitted: (value) {
                                FocusScope.of(context)
                                    .requestFocus(FocusNode());

                                Get.to(PincodeInputPage())?.then((value) {
                                  if (value is String && value.length > 0) {
                                    _pincodeController.editingController.text =
                                        "$value";
                                  }
                                });
                              },
                            ),
                            SizedBox(height: 11.w),
                            // pincode
                            JoggleTextField(
                              controller: _pincodeController,
                              textFieldType: JoggleTextFieldType.pincode,
                              onChanged: (value) {
                                _checkConfirmAvialble();
                              },
                            ),
                            SizedBox(height: 13.w),
                            // 完成注册
                            MaterialButton(
                              onPressed: _registerActionAble == false
                                  ? null
                                  : () {
                                      _registerSubmit();
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
                          ],
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
