import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class NewsFocusItem extends StatelessWidget {
  const NewsFocusItem({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      padding: EdgeInsets.only(bottom: 16.w),
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF7F7F7),
            height: 8.w,
          ),
          Container(
            color: const Color(0xFFFFFFFF),
            padding: EdgeInsets.only(top: 14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 21.w),
                  child: Image.asset(
                    "images/news_focus@2x.png",
                    width: 88.w,
                  ),
                ),
                SizedBox(height: 16.w),
                SizedBox(
                  height: 160.w,
                  child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(left: 21.w, right: 21.w),
                    physics: BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return MaterialButton(
                        onPressed: () {},
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.w),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            networkImage(
                              "",
                              Size(570.w / 2, 160.w),
                              BorderRadius.circular(10.w),
                            ),
                            Positioned(
                              left: 15.w,
                              right: 15.w,
                              bottom: 10.w,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "中国驻美大使馆：已陆续收到数十份台湾同胞求助信息",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: const Color(0xFFFFFFFF),
                                      fontSize: 17.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 6.w),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "新华社  2022.08.30",
                                        style: TextStyle(
                                          color: const Color(0xFFFFFFFF),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          // 评论
                                          Row(
                                            children: [
                                              Image.asset(
                                                "images/news_comment@2x.png",
                                                width: 12.w,
                                                height: 12.w,
                                              ),
                                              SizedBox(width: 2.w),
                                              Text(
                                                "12",
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFFFFFFFF),
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(width: 6.w),
                                          // 点赞
                                          Row(
                                            children: [
                                              Image.asset(
                                                "images/news_like@2x.png",
                                                width: 12.w,
                                                height: 12.w,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                "32",
                                                style: TextStyle(
                                                  color:
                                                      const Color(0xFFFFFFFF),
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.normal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    separatorBuilder: (context, index) {
                      return SizedBox(width: 14.w);
                    },
                    itemCount: 4,
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
