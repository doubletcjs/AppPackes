import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/scenes/account/account_forgot_code.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class ForgotTabPage extends StatefulWidget {
  final bool? resetComplete; // true 时为未登录状态,注册、登录页
  final int? tab;
  const ForgotTabPage({Key? key, this.resetComplete, this.tab})
      : super(key: key);

  @override
  State<ForgotTabPage> createState() => _ForgotTabPageState();
}

class _ForgotTabPageState extends State<ForgotTabPage> {
  List<String> _tabList = ["忘记密码", "忘记PIN码"];
  int _currentTab = 0;

  @override
  void initState() {
    super.initState();

    _currentTab = widget.tab ?? 0;
  }

  @override
  void dispose() {
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
            enableFeedback: false,
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_tabList.length, (index) => index)
                    .map((index) {
                  return Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 32.w),
                    child: InkWell(
                      onTap: () {
                        FocusScope.of(context).requestFocus(FocusNode());

                        _currentTab = index;
                        setState(() {});
                      },
                      child: Column(
                        children: [
                          Text(
                            "${_tabList[index]}",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF000000),
                              fontSize: 18.sp,
                            ),
                          ),
                          SizedBox(height: 10.w),
                          _currentTab == index
                              ? Container(
                                  width: 82.w,
                                  height: 3.w,
                                  color: kAppConfig.appThemeColor,
                                )
                              : SizedBox(width: 82.w, height: 3.w),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              Expanded(
                child: IndexedStack(
                  index: _currentTab,
                  children: [
                    AccountForgotCode(
                      codeType: 0,
                      resetComplete: widget.resetComplete,
                    ),
                    AccountForgotCode(
                      codeType: 1,
                      resetComplete: widget.resetComplete,
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
