import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class FriendListItem extends StatelessWidget {
  final FriendModel friendModel;
  final String? keyword;
  final void Function()? feedback;
  const FriendListItem({
    Key? key,
    required this.friendModel,
    this.keyword,
    this.feedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: feedback,
      color: const Color(0xFFFFFFFF),
      hoverColor: const Color(0xFFFFFFFF),
      disabledColor: const Color(0xFFFFFFFF),
      elevation: 0,
      highlightElevation: 0,
      hoverElevation: 0,
      focusElevation: 0,
      padding: EdgeInsets.zero,
      height: 74.w,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 18.w),
            child: networkImage(
              friendModel.avatar,
              Size(48.w, 48.w),
              BorderRadius.circular(5.w),
              memoryData: true,
              placeholder: "images/personal_placeholder@2x.png",
            ),
          ),
          SizedBox(width: 13.w),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 0.5.w,
                    color: const Color(0xFFF7F7F7),
                  ),
                ),
              ),
              alignment: Alignment.centerLeft,
              height: 74.w,
              padding: EdgeInsets.only(right: 45.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  (keyword ?? "").length > 0
                      ? TextHighlight(
                          text: friendModel.remark.length == 0
                              ? friendModel.nickname.length > 0
                                  ? friendModel.nickname
                                  : friendModel.userId
                              : friendModel.remark,
                          words: (keyword ?? "").length > 0
                              ? {
                                  "$keyword": HighlightedWord(
                                    textStyle: TextStyle(
                                      color: kAppConfig.appThemeColor,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                }
                              : {},
                          textStyle: TextStyle(
                            color: const Color(0xFF000000),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          binding: HighlightBinding.first,
                        )
                      : Text(
                          friendModel.remark.length == 0
                              ? friendModel.nickname.length > 0
                                  ? friendModel.nickname
                                  : friendModel.userId
                              : friendModel.remark,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: const Color(0xFF000000),
                            fontSize: 18.sp,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                  friendModel.risk == 1
                      ? Text(
                          "[账号异常]",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: const Color(0xFFFF8D1A),
                          ),
                        )
                      : SizedBox(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
