import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/routes/route_utils.dart';
import 'package:interests_protection_app/scenes/personal/widgets/name_auth_identity.dart';
import 'package:interests_protection_app/scenes/personal/widgets/name_auth_info.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class RealNameAuthPage extends StatefulWidget {
  final bool? fromRegister;
  const RealNameAuthPage({
    Key? key,
    this.fromRegister,
  }) : super(key: key);

  @override
  State<RealNameAuthPage> createState() => _RealNameAuthPageState();
}

class _RealNameAuthPageState extends State<RealNameAuthPage> {
  List<String> _stepNameList = ["上传身份证", "填写资料", "完成认证"];
  int _authStep = 0;
  bool _identityFill = false;
  bool _infoFill = false;

  String _name = "";
  String _identity = "";
  String _startDate = "";
  String _endDate = "";

  // 认证步骤
  Widget _authStepWidget() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: 19.w),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(26.w, 15.w, 23.w, 42.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 15.w,
                      height: 15.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(15.w / 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "1",
                        style: TextStyle(
                          color: kAppConfig.appThemeColor,
                          fontSize: 8.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Container(
                      width: 37.w,
                      height: 3.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(3.w / 2),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Container(
                      width: 37.w,
                      height: 3.w,
                      decoration: BoxDecoration(
                        color: _identityFill
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFFE69191),
                        borderRadius: BorderRadius.circular(3.w / 2),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Container(
                      width: 15.w,
                      height: 15.w,
                      decoration: BoxDecoration(
                        color: _authStep >= 1
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFFE69191),
                        borderRadius: BorderRadius.circular(15.w / 2),
                      ),
                      alignment: Alignment.center,
                      child: _authStep >= 1
                          ? Text(
                              "2",
                              style: TextStyle(
                                color: kAppConfig.appThemeColor,
                                fontSize: 8.sp,
                              ),
                            )
                          : SizedBox(),
                    ),
                    SizedBox(width: 3.w),
                    Container(
                      width: 37.w,
                      height: 3.w,
                      decoration: BoxDecoration(
                        color: _infoFill
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFFE69191),
                        borderRadius: BorderRadius.circular(3.w / 2),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Container(
                      width: 37.w,
                      height: 3.w,
                      decoration: BoxDecoration(
                        color: _authStep == 2
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFFE69191),
                        borderRadius: BorderRadius.circular(3.w / 2),
                      ),
                    ),
                    SizedBox(width: 3.w),
                    Container(
                      width: 15.w,
                      height: 15.w,
                      decoration: BoxDecoration(
                        color: _authStep == 2
                            ? const Color(0xFFFFFFFF)
                            : const Color(0xFFE69191),
                        borderRadius: BorderRadius.circular(15.w / 2),
                      ),
                      alignment: Alignment.center,
                      child: _authStep == 2
                          ? Text(
                              "3",
                              style: TextStyle(
                                color: kAppConfig.appThemeColor,
                                fontSize: 8.sp,
                              ),
                            )
                          : SizedBox(),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 40.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                      List.generate(_stepNameList.length, (index) => index)
                          .map((index) {
                    return Text(
                      _stepNameList[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 12.sp,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kAppConfig.appThemeColor,
        titleSpacing: 0,
        elevation: 0,
        leadingWidth: 0,
        toolbarHeight: 0,
        leading: SizedBox(),
      ),
      body: Column(
        children: [
          // bar
          Container(
            height: AppBar().preferredSize.height,
            width: MediaQuery.of(context).size.width,
            color: kAppConfig.appThemeColor,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: _authStep == 2
                      ? SizedBox()
                      : AppbarBack(iconColor: const Color(0xFFFFFFFF)),
                ),
                Text(
                  "实名认证",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFFFFFFFF),
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: kAppConfig.appThemeColor,
                alignment: Alignment.center,
                child: _authStepWidget(),
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
            child: _authStep == 1
                ? NameAuthInfo(
                    fillFeedback: (fill) {
                      _infoFill = fill;
                      setState(() {});
                    },
                    nextStepAction: () {
                      SVProgressHUD.show();
                      AccountApi.real(params: {
                        "name": _name,
                        "card": _identity,
                        "valid_date": "$_startDate-$_endDate",
                      }).then((value) {
                        AppHomeController _homeController =
                            Get.find<AppHomeController>();
                        _homeController.accountModel.real = 1;
                        _homeController.update();

                        _homeController.accountDB!.update(
                            kAppAccountTableName, {"real": 1},
                            where:
                                "userId = '${_homeController.accountModel.userId}'");

                        Future.delayed(Duration(milliseconds: 200), () {
                          _authStep = 2;
                          setState(() {});

                          SVProgressHUD.dismiss();
                        });
                      }).catchError((error) {
                        SVProgressHUD.dismiss();
                      });
                    },
                    infoFeedback: (name, identity, startDate, endDate) {
                      _name = name;
                      _identity = identity;
                      _startDate = startDate;
                      _endDate = endDate;

                      setState(() {});
                    },
                  )
                : _authStep == 2
                    ? Container(
                        padding: EdgeInsets.only(top: 18.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Image.asset(
                              "images/name_auth_complete@2x.png",
                              width: 88.w,
                              height: 88.w,
                            ),
                            SizedBox(height: 17.w),
                            Text(
                              "您已通过实名认证",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF000000),
                                fontSize: 20.sp,
                              ),
                            ),
                            SizedBox(height: 72.w),
                            Text(
                              "$_name",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFBDA24B),
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(height: 11.w),
                            Container(
                              width: 240.w,
                              height: 0.5.w,
                              color: const Color(0xFFF2F2F2),
                            ),
                            SizedBox(height: 13.w),
                            Text(
                              "$_identity",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFFBDA24B),
                                fontSize: 15.sp,
                              ),
                            ),
                            SizedBox(height: 56.w),
                            Container(
                              height: 48.w,
                              decoration: BoxDecoration(
                                color: kAppConfig.appThemeColor,
                                borderRadius: BorderRadius.circular(40.w),
                              ),
                              margin: EdgeInsets.only(left: 54.w, right: 54.w),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: MaterialButton(
                                      onPressed: () {
                                        if ((widget.fromRegister ?? false) ==
                                            true) {
                                          Get.offAllNamed(RouteNameString.home);
                                        } else {
                                          Get.back();
                                        }
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(40.w),
                                      ),
                                      height: 48.w,
                                      child: Text(
                                        "返回首页",
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
                          ],
                        ),
                      )
                    : NameAuthIdentity(
                        fillFeedback: (fill) {
                          _identityFill = fill;
                          setState(() {});
                        },
                        nextStepAction: () {
                          _authStep = 1;
                          setState(() {});
                        },
                      ),
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
