import 'dart:convert';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/tickets_api.dart';
import 'package:interests_protection_app/models/tickets_detail_model.dart';
import 'package:interests_protection_app/scenes/tickets/tickets_detail_reply.dart';
import 'package:interests_protection_app/scenes/tickets/widgets/tickets_detail_header.dart';
import 'package:interests_protection_app/scenes/tickets/widgets/tickets_reply_file.dart';
import 'package:interests_protection_app/scenes/tickets/widgets/tickets_reply_item.dart';
import 'package:interests_protection_app/utils/refresh_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';
import 'package:interests_protection_app/utils/widgets/file_preview_page.dart';
import 'package:interests_protection_app/utils/widgets/photo_view_gallery.dart';
import 'package:objectid/objectid.dart';

class TicketsRecordDetail extends StatefulWidget {
  final String recordId;
  const TicketsRecordDetail({Key? key, required this.recordId})
      : super(key: key);

  @override
  State<TicketsRecordDetail> createState() => _TicketsRecordDetailState();
}

class _TicketsRecordDetailState extends State<TicketsRecordDetail> {
  RefreshUtilController _refreshController =
      RefreshUtilController(initialRefresh: true);
  TicketsDetailModel? _detailModel;
  late Directory? _fileCacheDirectory;

  void _requestDetail() {
    TicketsApi.getTickets(params: {"id": widget.recordId}).then((value) {
      _detailModel = null;
      if (value != null && (value ?? {}).length > 0) {
        _detailModel = TicketsDetailModel.fromJson(value ?? {});
        _detailModel!.id = widget.recordId;
      }

      setState(() {});
      _refreshController.refreshCompleted();

      if (_detailModel == null) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }
    }).catchError((error) {
      _refreshController.refreshFailed();

      if (error is Map && error["code"] == -998) {
        _refreshController.status = RefreshUtilStatus.networkFailure;
      } else if (_detailModel != null) {
        _refreshController.status = RefreshUtilStatus.emptyData;
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _fileCacheDirectory = null;
    StorageUtils.getUserTicketsPath().then((value) async {
      _fileCacheDirectory = Directory(value + "/${widget.recordId}");
      if (_fileCacheDirectory!.existsSync() == false) {
        _fileCacheDirectory!.createSync();
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.2.w,
        shadowColor: const Color(0xFFF2F2F2),
        title: Text("上报记录"),
        leading: AppbarBack(),
        actions: _detailModel == null
            ? []
            : [
                MaterialButton(
                  onPressed: () {
                    Get.to(TicketsDetailReply(detailModel: _detailModel!))
                        ?.then((value) {
                      if (value == "post") {
                        _refreshController.requestRefresh();
                      }
                    });
                  },
                  minWidth: 44.w,
                  height: 44.w,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(44.w / 2),
                  ),
                  child: Text(
                    "回复",
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: const Color(0xFF000000),
                    ),
                  ),
                ),
                SizedBox(width: 11.w),
              ],
      ),
      body: RefreshUtilWidget(
        refreshController: _refreshController,
        onRefresh: _requestDetail,
        child: ListView(
          physics: BouncingScrollPhysics(),
          shrinkWrap: true,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: false,
          padding: EdgeInsets.only(
            left: 17.w,
            right: 17.w,
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          children: _detailModel == null
              ? []
              : [
                  TicketsDetailHeader(detailModel: _detailModel!),
                  // 回复内容
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 23.w),
                      Text(
                        _detailModel!.content,
                        style: TextStyle(
                          fontSize: 15.sp,
                          color: const Color(0xFF000000),
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: 20.w),
                      Container(
                        width: 197.w,
                        height: 0.5.w,
                        color: const Color(0xFFCCCCCC),
                      ),
                      SizedBox(height: 4.w),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(),
                          Text(
                            timeLineFormat(
                              date: DateUtil.formatDate(
                                  ObjectId.fromHexString(_detailModel!.id)
                                      .timestamp,
                                  format: "yyyy-MM-dd HH:mm:ss"),
                            ),
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: const Color(0xFFA6A6A6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ...List.generate(_detailModel!.reply.length, (index) => index)
                      .map((index) {
                    return TicketsReplyItem(model: _detailModel!.reply[index]);
                  }).toList(),
                  SizedBox(height: 21.w),
                  ...List.generate(
                      (_fileCacheDirectory == null
                          ? 0
                          : _detailModel!.accessory.length),
                      (index) => index).map((index) {
                    TicketsAccessoryModel _model =
                        _detailModel!.accessory[index];
                    return TicketsReplyFile(
                      accessoryModel: _model,
                      recordId: _detailModel!.id,
                      fileDirectory: _fileCacheDirectory!,
                      fileOpenAction: (isImage) {
                        String _localFilePath =
                            _fileCacheDirectory!.path + "/${_model.file}";
                        if (isImage) {
                          PhotoViewGalleryPage.show(
                            context,
                            PhotoViewGalleryPage(
                              images: [
                                base64Encode(
                                    File(_localFilePath).readAsBytesSync())
                              ],
                              initIndex: 0,
                            ),
                          );
                        } else {
                          Get.to(
                            FilePreviewPage(
                              title: "文件预览",
                              localPath: _localFilePath,
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ],
        ),
      ),
    );
  }
}
