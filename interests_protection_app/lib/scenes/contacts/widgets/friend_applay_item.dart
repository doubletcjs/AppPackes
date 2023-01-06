import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class FriendApplayItem extends StatelessWidget {
  final FriendApplayModel applayModel;
  final void Function()? applayAction;
  final void Function()? deleteAction;
  const FriendApplayItem({
    Key? key,
    required this.applayModel,
    this.applayAction,
    this.deleteAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10.w),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(left: 14.w, right: 14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 头像
                networkImage(
                  applayModel.avatar,
                  Size(48.w, 48.w),
                  BorderRadius.circular(5.w),
                  memoryData: true,
                  placeholder: "images/personal_placeholder@2x.png",
                ),
                SizedBox(height: 8.w),
                // 用户名
                Text(
                  "${applayModel.nickname}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF1A1A1A),
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 6.w),
                // 日期
                Text(
                  timeLineFormat(date: applayModel.time),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: kAppConfig.appPlaceholderColor,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 10.w),
                // 通过
                Container(
                  decoration: BoxDecoration(
                    color: kAppConfig.appThemeColor,
                    borderRadius: BorderRadius.circular(10.w),
                  ),
                  width: 85.w,
                  height: 27.w,
                  child: MaterialButton(
                    onPressed: applayModel.applayState == 0
                        ? () {
                            if (applayAction != null) {
                              applayAction!();
                            }
                          }
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.w),
                    ),
                    child: Text(
                      applayModel.applayState == 1 ? "已通过" : "通过",
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 删除
          Positioned(
            top: 0,
            right: 0,
            child: MaterialButton(
              onPressed: () {
                if (deleteAction != null) {
                  deleteAction!();
                }
              },
              padding: EdgeInsets.zero,
              minWidth: 27.w,
              height: 27.w,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.w),
              ),
              child: Center(
                child: Image.asset(
                  "images/friend_applay_close@2x.png",
                  width: 7.w,
                  height: 7.w,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
