import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/tickets_data_controller.dart';
import 'package:interests_protection_app/models/tickets_detail_model.dart';

class TicketsReplyFile extends StatefulWidget {
  final TicketsAccessoryModel accessoryModel;
  final String recordId;
  final Directory fileDirectory;
  final void Function(bool isImage)? fileOpenAction;
  const TicketsReplyFile({
    Key? key,
    required this.accessoryModel,
    required this.recordId,
    required this.fileDirectory,
    this.fileOpenAction,
  }) : super(key: key);

  @override
  State<TicketsReplyFile> createState() => _TicketsReplyFileState();
}

class _TicketsReplyFileState extends State<TicketsReplyFile> {
  String _postfix = "";
  TicketsDataController _ticketsDataController =
      Get.find<TicketsDataController>();

  @override
  void initState() {
    super.initState();

    String _extension = "${widget.accessoryModel.file}"
        .trim()
        .substring("${widget.accessoryModel.file}".trim().lastIndexOf(".") + 1);
    if (_extension.toLowerCase().contains("jpg") ||
        _extension.toLowerCase().contains("png") ||
        _extension.toLowerCase().contains("jpeg") ||
        _extension.toLowerCase().contains("gif")) {
      _postfix = "image";
    } else {
      _postfix = _extension.toLowerCase();
      if (_postfix != "doc" && _postfix != "rar" && _postfix != "xls") {
        _postfix = "file";
      }
    }

    _ticketsDataController.checkStatus(widget.accessoryModel, widget.recordId);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(10.w),
      ),
      height: 63.w,
      margin: EdgeInsets.only(bottom: 10.w),
      child: GetBuilder<TicketsDataController>(
        id: "${widget.accessoryModel.file}",
        init: _ticketsDataController,
        builder: (controller) {
          TicketsAccessoryModel? _existModel = controller.accessoryStatusList
              .firstWhereOrNull(
                  (element) => element.file == widget.accessoryModel.file);
          if (_existModel != null) {
            // 处理中
            widget.accessoryModel.status = _existModel.status;
          }

          return MaterialButton(
            onPressed: widget.accessoryModel.status == 1
                ? null
                : () {
                    if (widget.accessoryModel.status == 2) {
                      // 打开文件
                      if (widget.fileOpenAction != null) {
                        widget.fileOpenAction!(_postfix == "image");
                      }
                    } else {
                      // 下载、解密文件
                      _ticketsDataController
                          .fileDownload(widget.accessoryModel);
                    }
                  },
            padding: EdgeInsets.only(
                left: 14.w,
                right: widget.accessoryModel.status == 2 ? 14.w : 8.w),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.w),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      (widget.accessoryModel.status == 2 && _postfix == "image")
                          ? Image.file(
                              File(widget.fileDirectory.path +
                                  "/${widget.accessoryModel.file}"),
                              width: 30.w,
                              height: 34.w,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              "images/$_postfix@2x.png",
                              width: 34.w,
                              height: 34.w,
                            ),
                      SizedBox(
                        width: (widget.accessoryModel.status == 2 &&
                                _postfix == "image")
                            ? 8.w
                            : 4.w,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${widget.accessoryModel.name}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: const Color(0xFF000000),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            Text(
                              widget.accessoryModel.length,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: const Color(0xFFA6A6A6),
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                widget.accessoryModel.status == 1
                    ? SizedBox(
                        width: 45.w,
                        height: 45.w,
                        child: Center(
                          child: SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.w,
                            ),
                          ),
                        ),
                      )
                    : widget.accessoryModel.status == 0
                        ? Image.asset(
                            "images/report_download@2x.png",
                            width: 45.w,
                            height: 45.w,
                          )
                        : SizedBox(),
              ],
            ),
          );
        },
      ),
    );
  }
}
