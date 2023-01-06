import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class TagSelectionItem extends StatelessWidget {
  final List<String> tagList;
  final void Function() onTab;
  final void Function(int index)? onDelete;
  const TagSelectionItem(
      {super.key,
      required this.tagList,
      required this.onTab,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: MaterialButton(
        onPressed: onTab,
        padding: EdgeInsets.only(left: 16.w, right: 16.w),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 16.w, bottom: 16.w),
              child: Text(
                "标签",
                style: TextStyle(
                  color: const Color(0xFF808080),
                  fontSize: 15.sp,
                ),
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: tagList.length == 0
                        ? Padding(
                            padding: EdgeInsets.only(top: 16.w, bottom: 16.w),
                            child: Text(
                              "未设置",
                              style: TextStyle(
                                color: kAppConfig.appPlaceholderColor,
                                fontSize: 15.sp,
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.only(top: 16.w, bottom: 16.w),
                            child: Wrap(
                              spacing: 10.w,
                              runSpacing: 10.w,
                              children: List.generate(
                                      tagList.length, (index) => index)
                                  .map((index) {
                                return MaterialButton(
                                  onPressed: () {
                                    if (onDelete != null) {
                                      onDelete!(index);
                                    }
                                  },
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  color: const Color(0xFFFFFFFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10.w),
                                  ),
                                  elevation: 0,
                                  highlightElevation: 0,
                                  height: 0,
                                  minWidth: 0,
                                  child: Container(
                                    padding:
                                        EdgeInsets.fromLTRB(14.w, 0, 14.w, 0),
                                    constraints:
                                        BoxConstraints(minHeight: 28.w),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10.w),
                                      border: Border.all(
                                        width: 0.5.w,
                                        color: const Color(0xFF000000),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                            top: 3.w,
                                            bottom: 3.w,
                                          ),
                                          child: ConstrainedBox(
                                            constraints:
                                                BoxConstraints(maxWidth: 220.w),
                                            child: Text(
                                              "${tagList[index]}",
                                              style: TextStyle(
                                                color: const Color(0xFF000000),
                                                fontSize: 15.sp,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                  SizedBox(width: 12.w),
                  Image.asset(
                    "images/personal_arrow@2x.png",
                    width: 24.w,
                    height: 24.w,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
