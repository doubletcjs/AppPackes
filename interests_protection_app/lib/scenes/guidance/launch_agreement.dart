import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/scenes/personal/personal_agressment_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class LaunchAgreement extends StatefulWidget {
  final void Function(bool agree)? agreeAction;
  const LaunchAgreement({
    super.key,
    required this.agreeAction,
  });

  @override
  State<LaunchAgreement> createState() => _LaunchAgreementState();

  static show(
    BuildContext context, {
    required void Function(bool agree) agreeAction,
  }) {
    showGeneralDialog(
      context: context,
      barrierColor: const Color(0x7F000000),
      pageBuilder: (context, animation, secondaryAnimation) {
        return WillPopScope(
            child: LaunchAgreement(
              agreeAction: agreeAction,
            ),
            onWillPop: () {
              return Future(() => false);
            });
      },
    );
  }
}

class _LaunchAgreementState extends State<LaunchAgreement> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: const Color(0x14000000),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 29.w),
                Container(
                  margin: EdgeInsets.only(left: 30.w, right: 30.w),
                  padding: EdgeInsets.only(left: 29.w, right: 29.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFFFF),
                    borderRadius: BorderRadius.circular(15.w),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      SizedBox(height: 57.w),
                      Text(
                        "温馨提示",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 20.sp,
                        ),
                      ),
                      SizedBox(height: 7.w),
                      RichText(
                        text: TextSpan(
                          text: "感谢您信任并使用麒麟守护APP，依据最新法律法规监管要求，我们更新了",
                          style: TextStyle(
                            color: const Color(0xFF000000),
                            fontSize: 11.sp,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: "《用户隐私协议与声明》",
                              style: TextStyle(
                                color: kAppConfig.appThemeColor,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Get.to(PersonalAgressmentPage());
                                },
                            ),
                            TextSpan(
                              text: "。请仔细阅读用户隐私协议与声明，并确认了解我们对您的个人信息处理原则。",
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15.w),
                      Text(
                        "为确保应用各项功能正常使用和完成各项信息推送服务，APP内以及对接的第三方服务插件，将在通过您的同意后，收集设备ID(iOS设备号，安卓ID、国际移动设备识别码（IMEI）、网络设备硬件地址（MAC）等)、拍照、相册、麦克风、定位、软件版本号等隐私信息。",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 11.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 15.w),
                      Text(
                        "如果您同意以上条款，请点击下方同意按钮后使用我们的产品和服务，我们依法全力保护您的个人信息安全。",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 11.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 30.w),
                      Container(
                        height: 49.w,
                        decoration: BoxDecoration(
                          color: kAppConfig.appThemeColor,
                          borderRadius: BorderRadius.circular(5.w),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: MaterialButton(
                                height: 49.w,
                                minWidth: 0,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5.w),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();

                                  if (widget.agreeAction != null) {
                                    widget.agreeAction!(true);
                                  }
                                },
                                child: Text(
                                  "同意，继续使用",
                                  style: TextStyle(
                                    color: const Color(0xFFFFFFFF),
                                    fontSize: 15.sp,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12.w),
                      MaterialButton(
                        onPressed: () {
                          Navigator.of(context).pop();

                          if (widget.agreeAction != null) {
                            widget.agreeAction!(false);
                          }
                        },
                        height: 0,
                        minWidth: 0,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: EdgeInsets.zero,
                        child: Text(
                          "不同意",
                          style: TextStyle(
                            color: const Color(0xFFD9D9D9),
                            fontSize: 15.sp,
                          ),
                        ),
                      ),
                      SizedBox(height: 15.w),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              child: Image.asset(
                "images/agreement_logo@2x.png",
                height: 64.w,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
