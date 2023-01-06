import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class NewsTopItem extends StatelessWidget {
  const NewsTopItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () {},
      padding: EdgeInsets.fromLTRB(20.w, 10.w, 20.w, 10.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        children: [
          Text(
            "美国曾经计划用核弹打击中国113座城市，其中有你的家乡美国曾经计划用核弹打击中国113座城市，其中有你的家乡",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF000000),
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5.w),
          Row(
            children: [
              Text(
                "央视网",
                style: TextStyle(
                  color: const Color(0xFFB3B3B3),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.normal,
                ),
              ),
              SizedBox(width: 7.w),
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1.w,
                    color: kAppConfig.appThemeColor,
                  ),
                  borderRadius: BorderRadius.circular(3.w),
                ),
                padding: EdgeInsets.fromLTRB(3.w, 3.w, 3.w, 1.w),
                child: Text(
                  "置顶",
                  style: TextStyle(
                    color: kAppConfig.appThemeColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.normal,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
