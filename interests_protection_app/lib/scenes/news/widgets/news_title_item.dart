import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/models/news_list_model.dart';
import 'package:interests_protection_app/scenes/news/news_detail_page.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class NewsTitleItem extends StatelessWidget {
  final NewsListModel listModel;
  const NewsTitleItem({Key? key, required this.listModel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: () {
        Get.to(NewsDetailPage(), arguments: {
          "newsId": listModel.id,
        });
      },
      hoverColor: const Color(0xFFFFFFFF),
      elevation: 0,
      highlightElevation: 0,
      hoverElevation: 0,
      focusElevation: 0,
      padding: EdgeInsets.fromLTRB(27.w, 16.w, 20.w, 16.w),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      height: 67.w,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                Text(
                  "${listModel.title}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF000000),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.normal,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 18.w),
                // 日期、来源
                Text(
                  "${DateUtil.formatDateStr("${listModel.createdAt}", format: "yyyy.MM.dd HH:mm")}   ${listModel.origin}",
                  style: TextStyle(
                    color: const Color(0xFFA6A6A6),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 29.w),
          // 图片
          networkImage(
            listModel.cover,
            Size(98.w, 67.w),
            BorderRadius.circular(5.w),
          ),
        ],
      ),
    );
  }
}
