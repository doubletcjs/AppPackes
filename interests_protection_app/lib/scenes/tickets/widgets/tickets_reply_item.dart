import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/models/tickets_detail_model.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class TicketsReplyItem extends StatelessWidget {
  final TicketsReplyModel model;
  const TicketsReplyItem({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
            width: 0.5.w,
            color: const Color(0xFFF2F2F2),
          ),
        ),
      ),
      padding: EdgeInsets.only(top: 24.w, bottom: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model.content,
            style: TextStyle(
              fontSize: 15.sp,
              color: const Color(0xFF000000),
              height: 1.5,
            ),
          ),
          SizedBox(height: 20.w),
          Container(
            width: 197.w,
            height: 0.5.w,
            color: const Color(0xFFCCCCCC),
          ),
          SizedBox(height: 4.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                model.uid.length > 0 ? "系统回复" : "我的回复",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFFA6A6A6),
                ),
              ),
              Text(
                timeLineFormat(date: model.createdAt),
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFFA6A6A6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
