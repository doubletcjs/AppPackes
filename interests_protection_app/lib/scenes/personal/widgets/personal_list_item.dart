import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class PersonalListItem extends StatelessWidget {
  final String? label;
  final String? icon;
  final void Function()? labelAction;
  final Widget? actionWidget;
  final Widget? tipWidget;
  final bool? disable;
  final double? height;
  final Widget? leading;
  final bool? hideBorder;
  const PersonalListItem({
    Key? key,
    this.icon,
    this.label,
    this.labelAction,
    this.actionWidget,
    this.tipWidget,
    this.disable,
    this.height,
    this.leading,
    this.hideBorder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: disable == true ? null : labelAction,
      padding: EdgeInsets.only(left: 15.w, right: 15.w),
      color: const Color(0xFFFFFFFF),
      disabledColor: const Color(0xFFFFFFFF),
      hoverColor: const Color(0xFFFFFFFF),
      elevation: 0,
      highlightElevation: 0,
      hoverElevation: 0,
      focusElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        height: height ?? 48.w,
        decoration: BoxDecoration(
          border: hideBorder == true
              ? Border()
              : Border(
                  bottom: BorderSide(
                    width: 0.5.w,
                    color: const Color(0xFFF2F2F2),
                  ),
                ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            leading ??
                Row(
                  children: [
                    Image.asset(
                      "$icon",
                      width: 24.w,
                      height: 24.w,
                      color: disable == true
                          ? kAppConfig.appPlaceholderColor
                          : null,
                    ),
                    SizedBox(width: 12.w),
                    Row(
                      children: [
                        Text(
                          label ?? "",
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: disable == true
                                ? kAppConfig.appPlaceholderColor
                                : const Color(0xFF000000),
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        tipWidget ?? SizedBox(),
                      ],
                    ),
                  ],
                ),
            actionWidget ??
                Image.asset(
                  "images/personal_arrow@2x.png",
                  width: 24.w,
                  height: 24.w,
                ),
          ],
        ),
      ),
    );
  }
}
