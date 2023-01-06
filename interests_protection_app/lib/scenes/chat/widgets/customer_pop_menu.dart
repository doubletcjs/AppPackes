import 'package:custom_pop_up_menu/custom_pop_up_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
// import 'package:interests_protection_app/apis/message_api.dart';
// import 'package:interests_protection_app/controllers/app_home_controller.dart';
//
import 'package:interests_protection_app/scenes/personal/feedback_complaint_page.dart';
// import 'package:interests_protection_app/utils/storage_utils.dart';
// import 'package:interests_protection_app/utils/utils_tool.dart';

class CustomerPopMenu extends StatefulWidget {
  const CustomerPopMenu({Key? key}) : super(key: key);

  @override
  State<CustomerPopMenu> createState() => _CustomerPopMenuMenuState();
}

class _CustomerPopMenuMenuState extends State<CustomerPopMenu> {
  final CustomPopupMenuController _menuController = CustomPopupMenuController();

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPopupMenu(
      child: Padding(
        padding: EdgeInsets.only(right: 10.w),
        child: Image.asset(
          "images/assistant_menu@2x.png",
          width: 32.w,
          height: 32.w,
        ),
      ),
      menuBuilder: () {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10.w),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(10.w),
              border: Border.all(
                width: 0.5.w,
                color: const Color(0xFFE6E6E6),
              ),
            ),
            width: 108.w,
            child: Column(
              children: [
                // MaterialButton(
                //   onPressed: () {
                //     _menuController.hideMenu();

                //     MessageApi.customerInfo().then((value) async {
                //       String _nickname = (value ?? {})["nickname"] ?? "";
                //       if (kAppConfig.assistantNickName != _nickname &&
                //           _nickname.length > 0) {
                //         kAppConfig.assistantNickName = _nickname;
                //         StorageUtils.updateAssistantNickName();

                //         Get.find<AppHomeController>().messageHandler.add({
                //           StreamActionType.system:
                //               SystemStreamActionType.customerSwitch
                //         });
                //       }
                //     }).catchError((error) {});
                //   },
                //   padding: EdgeInsets.zero,
                //   materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                //   height: 42.w,
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.zero,
                //   ),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: [
                //       Image.asset(
                //         "images/assistant_switch@2x.png",
                //         width: 16.w,
                //         height: 16.w,
                //       ),
                //       SizedBox(width: 7.w),
                //       Text(
                //         "切换助理",
                //         style: TextStyle(
                //           fontSize: 13.sp,
                //           color: const Color(0xFF000000),
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                // Container(
                //   margin: EdgeInsets.only(left: 10.w, right: 10.w),
                //   height: 0.5.w,
                //   color: const Color(0xFFF7F7F7),
                // ),
                MaterialButton(
                  onPressed: () {
                    _menuController.hideMenu();
                    Get.to(FeedbackComplaintPage());
                  },
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  height: 42.w,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "images/assistant_report@2x.png",
                        width: 16.w,
                        height: 16.w,
                      ),
                      SizedBox(width: 7.w),
                      Text(
                        "我要投诉",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: const Color(0xFF000000),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      pressType: PressType.singleClick,
      showArrow: false,
      barrierColor: Colors.transparent,
      verticalMargin: 2.w,
      controller: _menuController,
    );
  }
}
