import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/models/tickets_list_model.dart';
import 'package:interests_protection_app/scenes/tickets/tickets_record_detail.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:objectid/objectid.dart';

class TicketsRecordItem extends StatelessWidget {
  final bool edittingRecord;
  final bool? selected;
  final void Function()? selectAction;
  final void Function()? detailAction;
  final TicketsListModel model;
  TicketsRecordItem({
    Key? key,
    required this.edittingRecord,
    required this.model,
    this.selected,
    this.selectAction,
    this.detailAction,
  }) : super(key: key);

  final Map<String, Color> _levelColorMap = {
    "紧急": const Color(0xFFE64646),
    "较急": const Color(0xFFFFC300),
    "常规": const Color(0xFF43CF7C),
  };

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
      child: MaterialButton(
        onPressed: () {
          if (edittingRecord) {
            if (selectAction != null) {
              selectAction!();
            }
          } else {
            Get.to(TicketsRecordDetail(recordId: model.id))?.then((value) {
              if (detailAction != null) {
                detailAction!();
              }
            });
          }
        },
        padding: edittingRecord
            ? EdgeInsets.fromLTRB(
                8.w,
                20.w,
                10.w,
                20.w,
              )
            : EdgeInsets.fromLTRB(
                25.w,
                20.w,
                15.w,
                20.w,
              ),
        child: Row(
          children: [
            edittingRecord
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
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        model.unread
                            ? Container(
                                width: 8.w,
                                height: 8.w,
                                margin: EdgeInsets.only(right: 11.w),
                                decoration: BoxDecoration(
                                  color: kAppConfig.appThemeColor,
                                  borderRadius: BorderRadius.circular(4.w),
                                ),
                              )
                            : SizedBox(),
                        Text(
                          "${model.category}",
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: const Color(0xFF000000),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          height: 13.w,
                          margin: EdgeInsets.only(left: 4.w),
                          padding: EdgeInsets.only(left: 6.w, right: 6.w),
                          decoration: BoxDecoration(
                            color: _levelColorMap[model.tag],
                            borderRadius: BorderRadius.circular(13.w / 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${model.tag}",
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        timeLineFormat(
                          date: DateUtil.formatDate(
                              ObjectId.fromHexString(model.id).timestamp,
                              format: "yyyy-MM-dd HH:mm:ss"),
                        ),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: kAppConfig.appPlaceholderColor,
                        ),
                      ),
                      edittingRecord
                          ? SizedBox()
                          : Image.asset(
                              "images/report_arrow@2x.png",
                              width: 24.w,
                              height: 24.w,
                            ),
                    ],
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
