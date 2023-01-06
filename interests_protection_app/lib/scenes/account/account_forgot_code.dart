import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/scenes/account/pincode_input_page.dart';
import 'package:interests_protection_app/scenes/account/register_complete_page.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';

class AccountForgotCode extends StatefulWidget {
  final int codeType;
  final bool? resetComplete;
  const AccountForgotCode({
    Key? key,
    required this.codeType,
    this.resetComplete,
  }) : super(key: key);

  @override
  State<AccountForgotCode> createState() => _AccountForgotCodeState();
}

class _AccountForgotCodeState extends State<AccountForgotCode> {
  late TextEditingController _phoneEditingController = TextEditingController();
  late FocusNode _phoneFocusNode = FocusNode();

  late TextEditingController _codeEditingController = TextEditingController();
  late FocusNode _codeFocusNode = FocusNode();

  late TextEditingController _passwordEditingController =
      TextEditingController();
  late FocusNode _passwordFocusNode = FocusNode();

  late TextEditingController _pincodeEditingController =
      TextEditingController();
  late FocusNode _pincodeFocusNode = FocusNode();

  bool _passwordObscureText = true; // 隐藏密码
  bool _pincodeObscureText = true;

  bool _confirmAviable = false;

  Timer? _timer;
  int _countSecond = 59;
  bool _resendCode = false;

  // 开始倒计时
  void _startTimer() {
    _closeTimer();

    _countSecond = 59;
    _resendCode = false;
    setState(() {});

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_countSecond < 0) {
        _resendCode = true;
        _closeTimer();
      } else {
        _countSecond -= 1;
        setState(() {});
      }
    });
  }

  // 关闭计时器
  void _closeTimer({bool dispose = false}) {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }

    if (dispose == false) {
      setState(() {});
    }
  }

  // 输入检验
  void _checkConfirmAvialble() {
    if (_phoneEditingController.text.replaceAll(" ", "").length > 0 &&
        _codeEditingController.text.trim().length > 0 &&
        (widget.codeType == 1
            ? _pincodeEditingController.text.trim().length > 0
            : _passwordEditingController.text.trim().length > 0)) {
      _confirmAviable = true;
    } else {
      _confirmAviable = false;
    }

    setState(() {});
  }

  // 输入框
  Widget _inputWidget(
    TextEditingController controller,
    FocusNode focusNode,
    String placeholder,
  ) {
    bool _obscureText = controller == _pincodeEditingController
        ? _pincodeObscureText
        : _passwordObscureText;

    return Container(
      height: 48.w,
      padding: EdgeInsets.only(left: 29.w, right: 16.w),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(48.w / 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: controller == _pincodeEditingController
                  ? () {
                      FocusScope.of(context).requestFocus(FocusNode());

                      Get.to(PincodeInputPage())?.then((value) {
                        if (value is String && value.length > 0) {
                          _pincodeEditingController.text = "$value";
                          setState(() {});

                          _checkConfirmAvialble();
                        }
                      });
                    }
                  : null,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                enabled: controller == _codeEditingController
                    ? (_phoneEditingController.text.trim().length > 0 &&
                            _didSendCode == true
                        ? true
                        : false)
                    : controller == _pincodeEditingController
                        ? false
                        : true,
                style: TextStyle(
                  color: const Color(0xFF666666),
                  fontSize: 20.sp,
                ),
                obscureText: controller == _pincodeEditingController
                    ? _pincodeObscureText
                    : controller == _passwordEditingController
                        ? _passwordObscureText
                        : false,
                keyboardType: controller == _passwordEditingController
                    ? TextInputType.text
                    : TextInputType.numberWithOptions(decimal: true),
                textInputAction: (controller == _passwordEditingController ||
                        controller == _pincodeEditingController)
                    ? TextInputAction.done
                    : TextInputAction.next,
                inputFormatters: (controller == _codeEditingController ||
                        controller == _pincodeEditingController)
                    ? [
                        FilteringTextInputFormatter.allow(
                          RegExp(r"[0-9]"),
                        ), //只能输入数字
                        FilteringTextInputFormatter.deny(RegExp('[\\s]')) // 空格
                      ]
                    : (controller == _phoneEditingController)
                        ? phoneInputFormatters()
                        : [
                            FilteringTextInputFormatter.deny(
                                RegExp('[\\s]')) // 空格
                          ],
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: placeholder,
                  hintStyle: TextStyle(
                    color: kAppConfig.appPlaceholderColor,
                    fontSize: 15.sp,
                  ),
                ),
                onChanged: (value) {
                  _checkConfirmAvialble();
                },
                onEditingComplete: () {},
                onSubmitted: (value) {},
              ),
            ),
          ),
          SizedBox(width: 11.w),
          controller == _phoneEditingController
              ? (_phoneEditingController.text.trim().length > 0
                  ? InkWell(
                      onTap: () {
                        _phoneEditingController.clear();
                        setState(() {});
                      },
                      child: Image.asset(
                        "images/login_clean@2x.png",
                        width: 16.w,
                        height: 16.w,
                      ),
                    )
                  : Container())
              : controller == _codeEditingController
                  ? (_phoneEditingController.text.replaceAll(" ", "").length > 0
                      ? (_countSecond >= 1 && _timer != null
                          ? Text(
                              "$_countSecond${'S'}",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFB3B3B3),
                                fontSize: 14.sp,
                              ),
                            )
                          : (_resendCode == true
                              ? InkWell(
                                  onTap: () {
                                    _sendCode();
                                  },
                                  child: Text(
                                    "重新发送",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0XFF00BAAD),
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                )
                              : InkWell(
                                  onTap: () {
                                    _sendCode();
                                  },
                                  child: Text(
                                    "发送",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0XFF00BAAD),
                                      fontSize: 15.sp,
                                    ),
                                  ),
                                )))
                      : Container())
                  : InkWell(
                      onTap: () {
                        if (controller == _pincodeEditingController) {
                          _pincodeObscureText = !_pincodeObscureText;
                        } else {
                          _passwordObscureText = !_passwordObscureText;
                        }
                        setState(() {});
                      },
                      child: Image.asset(
                        !_obscureText
                            ? "images/login_show@3x.png"
                            : "images/login_hide@3x.png",
                        width: 16.w,
                        height: 16.w,
                      ),
                    ),
        ],
      ),
    );
  }

  // 获取验证码
  bool _didSendCode = false;
  void _sendCode() {
    FocusScope.of(context).requestFocus(FocusNode());
    SVProgressHUD.show();
    // action 1 注册验证码; 3 重置 PIN 码; 4 重置密码
    AccountApi.sms(params: {
      "mobile": "+86" + _phoneEditingController.text.replaceAll(" ", ""),
      "action": widget.codeType == 1 ? 3 : 4,
    }).then((value) {
      SVProgressHUD.dismiss();
      _didSendCode = true;
      setState(() {});

      _startTimer();
    }).catchError((error) {
      SVProgressHUD.dismiss();
    });
  }

  // 重置密码
  void _resetPassword() async {
    FocusScope.of(context).requestFocus(FocusNode());
    SVProgressHUD.show();

    var params = {
      "mobile": "+86" + _phoneEditingController.text.replaceAll(" ", ""),
      "code": _codeEditingController.text.replaceAll(" ", ""),
      "password":
          CryptoUtils.md5(_passwordEditingController.text.replaceAll(" ", "")),
    };

    AccountApi.resetPassword(params: params).then((value) {
      SVProgressHUD.dismiss();
      if ((widget.resetComplete ?? false) == false) {
        Get.back();
      } else {
        Get.offAll(
          RegisterCompletePage(resetAction: true),
          arguments: {
            "phone": _phoneEditingController.text.replaceAll(" ", ""),
          },
        );
      }
    }).catchError((error) {
      SVProgressHUD.dismiss();
    });
  }

  // 重置PIN码
  void _resetPincode() {
    void _action() async {
      FocusScope.of(context).requestFocus(FocusNode());
      SVProgressHUD.show();
      String _encryptPinCode = await CryptoUtils.encryptPinCode(
          _pincodeEditingController.text.replaceAll(" ", ""));

      var params = {
        "mobile": "+86" + _phoneEditingController.text.replaceAll(" ", ""),
        "code": _codeEditingController.text.replaceAll(" ", ""),
        "pin": _encryptPinCode,
      };

      AccountApi.resetPincode(params: params).then((value) {
        StorageUtils.setPincode(_encryptPinCode);

        SVProgressHUD.dismiss();
        if ((widget.resetComplete ?? false) == false) {
          StorageUtils.emptyCurrnetChatRecord();
          Get.back();
          utilsToast(msg: "PIN码重置成功");
        } else {
          Get.offAll(
            RegisterCompletePage(resetAction: true),
            arguments: {
              "phone": _phoneEditingController.text.replaceAll(" ", ""),
            },
          );
        }
      }).catchError((error) {
        SVProgressHUD.dismiss();
      });
    }

    if (widget.resetComplete == true) {
      _action();
    } else {
      AlertVeiw.show(
        context,
        confirmText: "继续",
        contentText: "",
        contentWidget: Padding(
          padding: EdgeInsets.fromLTRB(24.w, 43.w, 24.w, 30.w),
          child: RichText(
            text: TextSpan(
              text: "重置PIN将会清空",
              style: TextStyle(
                fontSize: 18.sp,
                color: const Color(0xFF000000),
                height: 1.5,
                fontWeight: FontWeight.normal,
              ),
              children: [
                TextSpan(
                  text: "所有",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: "聊天记录,是否继续?",
                ),
              ],
            ),
          ),
        ),
        cancelText: "取消",
        confirmAction: () {
          _action();
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _phoneFocusNode.addListener(() {
      setState(() {});
    });

    _codeFocusNode.addListener(() {
      setState(() {});
    });

    _passwordFocusNode.addListener(() {
      setState(() {});
    });

    _pincodeFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneEditingController.dispose();
    _phoneFocusNode.removeListener(() {});
    _phoneFocusNode.dispose();

    _codeEditingController.dispose();
    _codeFocusNode.removeListener(() {});
    _codeFocusNode.dispose();

    _passwordEditingController.dispose();
    _passwordFocusNode.removeListener(() {});
    _passwordFocusNode.dispose();

    _pincodeEditingController.dispose();
    _pincodeFocusNode.removeListener(() {});
    _pincodeFocusNode.dispose();

    _closeTimer(dispose: true);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(left: 54.w, right: 54.w),
      physics: BouncingScrollPhysics(),
      children: [
        SizedBox(height: 26.w),
        _inputWidget(_phoneEditingController, _phoneFocusNode, "请输入手机号"),
        SizedBox(height: 11.w),
        _inputWidget(_codeEditingController, _codeFocusNode, "请输入验证码"),
        SizedBox(height: 11.w),
        widget.codeType == 1
            ? _inputWidget(
                _pincodeEditingController, _pincodeFocusNode, "请输入新的PIN码")
            : _inputWidget(
                _passwordEditingController, _passwordFocusNode, "请输入新的密码"),
        SizedBox(height: 25.w),
        // 确认
        MaterialButton(
          onPressed: _confirmAviable == false
              ? null
              : () {
                  if (widget.codeType == 1) {
                    _resetPincode();
                  } else {
                    _resetPassword();
                  }
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
              "确认",
              style: TextStyle(
                color: const Color(0xFFFFFFFF),
                fontSize: 18.sp,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
