import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:highlight_text/highlight_text.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class FriendTagItem extends StatelessWidget {
  final FriendTagModel tag;
  final String? keyword;
  final void Function()? edittingFeedback;
  final void Function()? selectFeedback;
  final bool? selected;
  const FriendTagItem({
    Key? key,
    required this.tag,
    this.keyword,
    this.edittingFeedback,
    this.selectFeedback,
    this.selected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> _names =
        List.generate(tag.friends.length, (index) => index).map((index) {
      String _name = tag.friends[index].nickname;
      if (_name.length == 0) {
        _name = tag.friends[index].remark.length == 0
            ? tag.friends[index].userId
            : tag.friends[index].remark;
      }
      return _name;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(
            width: 0.5.w,
            color: const Color(0xFFF7F7F7),
          ),
        ),
      ),
      child: MaterialButton(
        onPressed: selectFeedback != null ? selectFeedback : edittingFeedback,
        padding: EdgeInsets.fromLTRB(16.w, 11.w, 16.w, 11.w),
        child: Row(
          children: [
            edittingFeedback != null
                ? Padding(
                    padding: EdgeInsets.only(right: 13.w),
                    child: Image.asset(
                      (selected ?? false) == true
                          ? "images/report_selected@2x.png"
                          : "images/report_select@2x.png",
                      width: 23.w,
                      height: 23.w,
                    ),
                  )
                : SizedBox(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          TextHighlight(
                            text: "${tag.label}",
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
                          ),
                          SizedBox(width: 4.w),
                          tag.friends.length > 0
                              ? Text(
                                  "(${tag.friends.length})",
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: const Color(0xFFA6A6A6),
                                    fontWeight: FontWeight.normal,
                                  ),
                                )
                              : SizedBox(),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 6.w),
                  tag.friends.length > 0
                      ? Text(
                          "${_names.join('，')}",
                          softWrap: true,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFFA6A6A6),
                            fontWeight: FontWeight.normal,
                          ),
                        )
                      : SizedBox(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
