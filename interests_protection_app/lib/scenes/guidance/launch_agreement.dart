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
                        "????????????",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 20.sp,
                        ),
                      ),
                      SizedBox(height: 7.w),
                      RichText(
                        text: TextSpan(
                          text: "????????????????????????????????????APP?????????????????????????????????????????????????????????",
                          style: TextStyle(
                            color: const Color(0xFF000000),
                            fontSize: 11.sp,
                            height: 1.5,
                          ),
                          children: [
                            TextSpan(
                              text: "?????????????????????????????????",
                              style: TextStyle(
                                color: kAppConfig.appThemeColor,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Get.to(PersonalAgressmentPage());
                                },
                            ),
                            TextSpan(
                              text: "?????????????????????????????????????????????????????????????????????????????????????????????????????????",
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 15.w),
                      Text(
                        "???????????????????????????????????????????????????????????????????????????APP????????????????????????????????????????????????????????????????????????????????????ID(iOS??????????????????ID?????????????????????????????????IMEI?????????????????????????????????MAC??????)???????????????????????????????????????????????????????????????????????????",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 11.sp,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 15.w),
                      Text(
                        "????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????",
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
                                  "?????????????????????",
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
                          "?????????",
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
