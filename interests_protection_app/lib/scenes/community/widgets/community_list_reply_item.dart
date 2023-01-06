import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class CommunityListReplyItem extends StatelessWidget {
  final int index;
  const CommunityListReplyItem({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: index == 0 ? 5.w : 8.w, bottom: 8.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        border: index == 0
            ? Border()
            : Border(
                top: BorderSide(
                  width: 0.5.w,
                  color: const Color(0xFFE8E8E8),
                ),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          networkImage(
            "",
            Size(35.w, 35.w),
            BorderRadius.circular(5.w),
            placeholder: "images/personal_placeholder@2x.png",
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "李希",
                      style: TextStyle(
                        color: const Color(0xFF000000),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "6月29日 21:12",
                      style: TextStyle(
                        color: const Color(0xFF808080),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.w),
                Text(
                  "回复内容回复内容容回复容回复内容回复内容回复内容内容内容内容内容回复内容回复内容回复内容内容内容内容内容",
                  style: TextStyle(
                    color: const Color(0xFF383838),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
