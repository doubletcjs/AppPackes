import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/tickets_api.dart';
import 'package:interests_protection_app/models/tickets_detail_model.dart';
import 'package:interests_protection_app/scenes/tickets/widgets/tickets_detail_header.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class TicketsDetailReply extends StatefulWidget {
  final TicketsDetailModel detailModel;
  const TicketsDetailReply({Key? key, required this.detailModel})
      : super(key: key);

  @override
  State<TicketsDetailReply> createState() => _TicketsDetailReplyState();
}

class _TicketsDetailReplyState extends State<TicketsDetailReply> {
  final TextEditingController _contentEditingController =
      TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final int _maxContentLength = 400;
  bool _canSubmit = false;

  // 校验
  void _checkAviable() {
    if (_contentEditingController.text.trim().length > 0) {
      _canSubmit = true;
    } else {
      _canSubmit = false;
    }

    setState(() {});
  }

  // 提交回复
  void _onSubmit() {
    SVProgressHUD.show();
    TicketsApi.ticketsReply(params: {
      "content": _contentEditingController.text,
    }, queryParameters: {
      "id": widget.detailModel.id,
    }).then((value) {
      _contentEditingController.clear();
      setState(() {});

      Future.delayed(Duration(milliseconds: 300), () {
        SVProgressHUD.dismiss();
        Get.back(result: "post");
      });
    }).catchError((error) {
      SVProgressHUD.dismiss();
    });
  }

  @override
  void dispose() {
    _contentEditingController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 60.w,
        elevation: 0.2.w,
        shadowColor: const Color(0xFFF2F2F2),
        title: Text("回复"),
        leading: Row(
          children: [
            SizedBox(width: 10.w),
            MaterialButton(
              onPressed: () {
                Get.back();
              },
              minWidth: 44.w,
              height: 44.w,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(44.w / 2),
              ),
              child: Text(
                "取消",
                style: TextStyle(
                  fontSize: 15.sp,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
          ],
        ),
        actions: [
          MaterialButton(
            onPressed: _canSubmit
                ? () {
                    _onSubmit();
                  }
                : null,
            minWidth: 44.w,
            height: 44.w,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(44.w / 2),
            ),
            child: Text(
              "提交",
              style: TextStyle(
                fontSize: 15.sp,
                color: _canSubmit
                    ? const Color(0xFF000000)
                    : kAppConfig.appPlaceholderColor,
              ),
            ),
          ),
          SizedBox(width: 11.w),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.only(left: 17.w, right: 17.w),
            child: TicketsDetailHeader(detailModel: widget.detailModel),
          ),
          // 内容
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 18.w, right: 30.w),
              color: const Color(0xFFFFFFFF),
              child: TextField(
                maxLength: _maxContentLength,
                controller: _contentEditingController,
                focusNode: _contentFocusNode,
                maxLines: null,
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 15.sp,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  _checkAviable();
                },
                onSubmitted: (value) {
                  if (_canSubmit) {
                    _onSubmit();
                  }
                },
              ),
            ),
          ),
          // 字数
          Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.only(left: 24.w, right: 11.w),
            child: Text(
              "${_contentEditingController.text.length}/$_maxContentLength",
              style: TextStyle(
                color: kAppConfig.appPlaceholderColor,
                fontSize: 9.sp,
              ),
            ),
          ),
          // 日期
          Padding(
            padding: EdgeInsets.only(left: 18.w, right: 30.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 197.w,
                  height: 0.5.w,
                  color: const Color(0xFF000000),
                ),
                SizedBox(height: 4.w),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "我发送的上报",
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: const Color(0xFFA6A6A6),
                      ),
                    ),
                    Text(
                      "2021年3月4日  19:24",
                      style: TextStyle(
                        fontSize: 15.sp,
                        color: const Color(0xFFA6A6A6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // FileAttachmentPicker(),
          SizedBox(height: 4.w + MediaQuery.of(context).padding.bottom),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
