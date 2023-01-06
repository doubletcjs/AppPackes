// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/models/tickets_detail_model.dart';

class TicketsDetailHeader extends StatefulWidget {
  final TicketsDetailModel detailModel;
  const TicketsDetailHeader({Key? key, required this.detailModel})
      : super(key: key);

  @override
  State<TicketsDetailHeader> createState() => _TicketsDetailHeaderState();
}

class _TicketsDetailHeaderState extends State<TicketsDetailHeader> {
  final Map<String, Color> _levelColorMap = {
    "紧急": const Color(0xFFE64646),
    "较急": const Color(0xFFFFC300),
    "常规": const Color(0xFF43CF7C),
  };

  // final List<String> _replyTypeList = [
  //   "接受回信",
  //   "不接受回信",
  // ];
  int _replyTypeIndex = 0;

  @override
  void initState() {
    super.initState();

    _replyTypeIndex = widget.detailModel.receive ? 0 : 1;
  }

  // 回信类型
  // void _replyTypeDialog() {
  //   showCupertinoModalPopup(
  //     context: context,
  //     builder: (context) {
  //       return CupertinoActionSheet(
  //         actions: List.generate(_replyTypeList.length, (index) => index)
  //             .map((index) {
  //           return CupertinoActionSheetAction(
  //             child: Text("${_replyTypeList[index]}"),
  //             onPressed: () {
  //               Navigator.pop(context);
  //               _replyTypeIndex = index;
  //               setState(() {});
  //             },
  //           );
  //         }).toList(),
  //         cancelButton: CupertinoActionSheetAction(
  //           child: const Text("取消"),
  //           isDefaultAction: true,
  //           onPressed: () {
  //             Navigator.pop(context);
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 11.w, bottom: 15.w),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            width: 0.5.w,
            color: const Color(0xFFF7F7F7),
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                "${widget.detailModel.category}",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF000000),
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                height: 13.w,
                margin: EdgeInsets.only(left: 4.w),
                padding: EdgeInsets.only(left: 6.w, right: 6.w),
                decoration: BoxDecoration(
                  color: _levelColorMap[widget.detailModel.tag],
                  borderRadius: BorderRadius.circular(13.w / 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  "${widget.detailModel.tag}",
                  style: TextStyle(
                    fontSize: 9.sp,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    "回信设置：",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: const Color(0xFF000000),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  InkWell(
                    // onTap: () {
                    //   _replyTypeDialog();
                    // },
                    onTap: null,
                    child: Text(
                      _replyTypeIndex == 1 ? "不接受" : "接受",
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: const Color(0xFF000000),
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Row(
                    children: [
                      Text(
                        "附",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF000000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 30.w),
                      Text(
                        "件：",
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF000000),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${widget.detailModel.accessory.length}",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: const Color(0xFF000000),
                      fontWeight: FontWeight.normal,
                      decoration: widget.detailModel.accessory.length == 0
                          ? null
                          : TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
