import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/scenes/account/forgot_tab_page.dart';
import 'package:interests_protection_app/scenes/account/pincode_input_page.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/scenes/account/widgets/joggle_text_field.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:platform_device_id/platform_device_id.dart';

class AccountLoginPage extends StatefulWidget {
  const AccountLoginPage({Key? key}) : super(key: key);

  @override
  State<AccountLoginPage> createState() => _AccountLoginPageState();
}

class _AccountLoginPageState extends State<AccountLoginPage> {
  JoggleTextFieldController _phoneController = JoggleTextFieldController();
  JoggleTextFieldController _passwordController = JoggleTextFieldController();
  JoggleTextFieldController _pincodeController = JoggleTextFieldController();
  bool _loginActionAble = false;
  String _errorShowText = "";
  String _deviceId = ""; // 设备id
  String _areaCode = "+86";

  // 输入检验
  void _checkConfirmAvialble() {
    if (_errorShowText.length == 0 &&
        _phoneController.editingController.text.trim().length > 0 &&
        _passwordController.editingController.text.trim().length > 0 &&
        _pincodeController.editingController.text.trim().length > 0) {
      _loginActionAble = true;
    } else {
      _loginActionAble = false;
    }

    setState(() {});
  }

  // 获取设备id
  Future<void> _getDeviceId() async {
    String deviceId;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      deviceId = (await PlatformDeviceId.getDeviceId) ?? "";
    } catch (e) {
      deviceId = 'Failed to get deviceId.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _deviceId = deviceId;
      print("deviceId->$_deviceId");
    });
  }

  // 登录
  void _loginAction() {
    FocusScope.of(context).requestFocus(FocusNode());
    SVProgressHUD.show();

    var password =
        _passwordController.editingController.text.replaceAll(" ", "");
    var pin = _pincodeController.editingController.text;
    var key = "";
    var curve25519 = "";
    Future.wait([
      Future(() async {
        var keyMap = await CryptoUtils.cryptotion();
        password = CryptoUtils.md5(password);
        pin = await CryptoUtils.encryptPinCode(pin);
        key = await CryptoUtils.rsa(keyMap["ed"]);
        curve25519 = keyMap["x"]!;
      })
    ]).then((value) {
      AccountApi.login(params: {
        "mobile": "$_areaCode" +
            _phoneController.editingController.text.replaceAll(" ", ""),
        "password": password,
        "key": key,
        "pin": pin,
        "device_id": _deviceId,
      }).then((value) async {
        String token = value["token"];
        String salt = value["salt"];
        String userId = value["id"];
        bool newDevice = value["new_device"]; // 是否新设备登录
        bool xpin = !value["pin"]; // 是否 pin true: pin 码; false: 紧急 pin 码

        if (xpin == false) {
          StorageUtils.setPincode(pin);
        }

        // 已登录
        await Get.find<AppHomeController>().login(
          token: token,
          salt: salt,
          curve25519: curve25519,
          userId: userId,
          newDevice: newDevice,
          xpin: xpin,
        );
      }).catchError((error) {
        SVProgressHUD.dismiss();
      });
    }).catchError((error) {
      debugPrint("error:$error");
      SVProgressHUD.dismiss();
    });
  }

  @override
  void initState() {
    super.initState();

    Future(
      () async {
        _getDeviceId();
      },
    );

    String _phone = (Get.arguments ?? {})["phone"] ?? "";
    if (_phone.length > 0) {
      _phoneController.editingController.text = phoneFormat(_phone);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _pincodeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            AppBar(toolbarHeight: 0),
            // 背景
            Positioned(
              left: 0,
              bottom: 0,
              right: 0,
              child: Image.asset(
                "images/login_backgroud@3x.png",
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              bottom: MediaQuery.of(context).viewInsets.bottom,
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.only(left: 54.w, right: 54.w),
                physics: BouncingScrollPhysics(),
                children: [
                  SizedBox(height: 79.w + MediaQuery.of(context).padding.top),
                  Image.asset(
                    "images/login_logo@2x.png",
                    height: 130.w,
                  ),
                  SizedBox(height: 42.w),
                  // 手机号
                  JoggleTextField(
                    controller: _phoneController,
                    textFieldType: JoggleTextFieldType.mobile,
                    onEditingComplete: () {
                      _passwordController.focusNode.requestFocus();
                    },
                    textInputAction: TextInputAction.next,
                    areaCodeHandle: (areaCode) {
                      _areaCode = areaCode;
                      setState(() {});
                    },
                  ),
                  SizedBox(height: 11.w),
                  // 密码
                  JoggleTextField(
                    controller: _passwordController,
                    textFieldType: JoggleTextFieldType.password,
                    onEditingComplete: () {
                      _pincodeController.focusNode.requestFocus();
                    },
                    textInputAction: TextInputAction.next,
                    onChanged: (value) {
                      _checkConfirmAvialble();
                    },
                    onSubmitted: (value) {
                      FocusScope.of(context).requestFocus(FocusNode());

                      if (_pincodeController.editingController.text.length ==
                          0) {
                        Get.to(PincodeInputPage())?.then((value) {
                          if (value is String && value.length > 0) {
                            _pincodeController.editingController.text =
                                "$value";
                            _checkConfirmAvialble();

                            Future.delayed(Duration(milliseconds: 400), () {
                              if (_loginActionAble) {
                                _loginAction();
                              }
                            });
                          }
                        });
                      } else {
                        _loginAction();
                      }
                    },
                  ),
                  SizedBox(height: 11.w),
                  // pincode
                  JoggleTextField(
                    controller: _pincodeController,
                    textFieldType: JoggleTextFieldType.pincode,
                    onChanged: (value) {
                      _checkConfirmAvialble();

                      Future.delayed(Duration(milliseconds: 400), () {
                        if (_loginActionAble) {
                          _loginAction();
                        }
                      });
                    },
                  ),
                  // 错误提示
                  Container(
                    height: 46.w,
                    alignment: Alignment.topCenter,
                    padding: EdgeInsets.only(top: 15.w),
                    child: Text(
                      _errorShowText,
                      style: TextStyle(
                        color: kAppConfig.appErrorColor,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                  // 登录
                  MaterialButton(
                    onPressed: _loginActionAble == false
                        ? null
                        : () {
                            _loginAction();
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
                        "登录",
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
            // 忘记密码/PIN码
            Positioned(
              bottom: 30.w,
              child: MaterialButton(
                onPressed: () {
                  Get.to(ForgotTabPage(resetComplete: true));
                },
                padding: EdgeInsets.fromLTRB(15.w, 7.w, 15.w, 7.w),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                child: Text(
                  "忘记密码/PIN码",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF610505),
                    fontSize: 14.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
            // 注册
            Positioned(
              top: MediaQuery.of(context).padding.top + 12.w,
              right: 15.w,
              child: MaterialButton(
                onPressed: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                  Get.toNamed(RouteNameString.register);
                },
                color: const Color(0xFFFFFFFF),
                highlightColor: kAppConfig.appDisableColor,
                splashColor: kAppConfig.appDisableColor,
                elevation: 0,
                highlightElevation: 0,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                minWidth: 73.w,
                height: 35.w,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(40.w),
                  side: BorderSide(
                    width: 0.5.w,
                    color: kAppConfig.appThemeColor,
                  ),
                ),
                child: Text(
                  "注册",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: kAppConfig.appThemeColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
