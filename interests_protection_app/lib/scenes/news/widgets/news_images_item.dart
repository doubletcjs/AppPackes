import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class NewsImagesItem extends StatelessWidget {
  const NewsImagesItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () {},
      padding: EdgeInsets.fromLTRB(0, 16.w, 0, 16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: Column(
        children: [
          // 标题
          Padding(
            padding: EdgeInsets.only(left: 27.w, right: 20.w),
            child: Text(
              "美国曾经计划用核弹打击中国113座城市，其中有你的家乡美国曾经计划用核弹打击中国113座城市，其中有你的家乡",
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF000000),
                fontSize: 15.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          SizedBox(height: 4.w),
          SizedBox(
            height: 67.w,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              padding: EdgeInsets.only(left: 27.w, right: 20.w),
              physics: BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                return networkImage(
                  "",
                  Size(98.w, 67.w),
                  BorderRadius.circular(5.w),
                );
              },
              separatorBuilder: (context, index) {
                return SizedBox(width: 15.w);
              },
              itemCount: 4,
            ),
          ),
        ],
      ),
    );
  }
}
