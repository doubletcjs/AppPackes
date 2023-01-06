import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/models/tickets_attach_model.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/image_picker.dart';

class FileAttachmentPicker extends StatefulWidget {
  final void Function(List<TicketsAttachModel> attachments)? attachmentFeedback;
  final bool? isComplaint;
  const FileAttachmentPicker({
    Key? key,
    this.attachmentFeedback,
    this.isComplaint,
  }) : super(key: key);

  @override
  State<FileAttachmentPicker> createState() => _FileAttachmentPickerState();
}

class _FileAttachmentPickerState extends State<FileAttachmentPicker> {
  List<TicketsAttachModel> _attachmentList = [];
  int _maxAttachmentCount = 4;

  // 文件选择
  void _filePicker() {
    // 图片处理
    void _handleAssetFile(List<File> list) {
      if (list.length == 0) {
        return;
      }

      SVProgressHUD.show();
      list.forEach((element) {
        String name = element.path
            .trim()
            .substring(element.path.trim().lastIndexOf("/") + 1);
        String extension =
            name.trim().substring(name.trim().lastIndexOf(".") + 1);
        int size = element.readAsBytesSync().length;

        TicketsAttachModel? _existModel = _attachmentList.firstWhereOrNull(
            (model) => model.path == element.path && model.fileName == name);
        if (_existModel == null &&
            _attachmentList.length < _maxAttachmentCount) {
          TicketsAttachModel _model = TicketsAttachModel.fromJson({});
          _model.path = element.path;
          _model.fileSize = getFileSize((size * 1024).toInt());
          _model.extension = extension;
          _model.fileName = name;
          _model.fileId = "${DateTime.now().millisecondsSinceEpoch}";
          _attachmentList.add(_model);
        }
      });

      setState(() {
        if (widget.attachmentFeedback != null) {
          widget.attachmentFeedback!(_attachmentList);
        }
      });

      Future.delayed(Duration(milliseconds: 300), () {
        SVProgressHUD.dismiss();
      });
    }

    _imagePick() {
      // 图片选择
      ImagePicker.pick(
        context,
        count: _maxAttachmentCount - _attachmentList.length,
      ).then((value) {
        if (value.length > 0) {
          _handleAssetFile(value);
        }
      });
    }

    _cameraPick() {
      // 拍照
      ImagePicker.openCamera(context).then((value) {
        if (value.length > 0) {
          _handleAssetFile(value);
        }
      });
    }

    void _filePick() {
      // 文件选择
      FilePicker.platform.pickFiles(allowMultiple: true).then((result) {
        if (result != null && result.count > 0) {
          result.files.forEach((element) {
            TicketsAttachModel? _existModel = _attachmentList.firstWhereOrNull(
                (model) =>
                    model.path == element.path &&
                    model.fileName == element.name);
            if (_existModel == null &&
                _attachmentList.length < _maxAttachmentCount) {
              TicketsAttachModel _model = TicketsAttachModel.fromJson({});
              _model.path = element.path ?? "";
              _model.fileSize = getFileSize(element.size);
              _model.extension = element.extension ?? "";
              _model.fileName = element.name;
              _model.fileId = "${DateTime.now().millisecondsSinceEpoch}";
              _attachmentList.add(_model);
            }
          });

          setState(() {
            if (widget.attachmentFeedback != null) {
              widget.attachmentFeedback!(_attachmentList);
            }
          });
        }
      });
    }

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: [
            (widget.isComplaint ?? false)
                ? SizedBox()
                : CupertinoActionSheetAction(
                    child: const Text("拍照"),
                    onPressed: () {
                      Navigator.pop(context);
                      _cameraPick();
                    },
                  ),
            CupertinoActionSheetAction(
              child: const Text("相册"),
              onPressed: () {
                Navigator.pop(context);
                _imagePick();
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("文件"),
              onPressed: () {
                Navigator.pop(context);
                _filePick();
              },
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            child: const Text("取消"),
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 53.w,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(width: 15.w),
                    _attachmentList.length > 0
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              TicketsAttachModel _model =
                                  _attachmentList[index];
                              String _extension = _model.extension;
                              String _postfix = "";
                              bool _isImage = false;
                              if (_extension.toLowerCase().contains("jpg") ||
                                  _extension.toLowerCase().contains("png") ||
                                  _extension.toLowerCase().contains("jpeg") ||
                                  _extension.toLowerCase().contains("gif")) {
                                _postfix = "image";
                                _isImage = true;
                              } else {
                                _postfix = _extension.toLowerCase();
                                if (_postfix != "doc" &&
                                    _postfix != "pdf" &&
                                    _postfix != "rar" &&
                                    _postfix != "xls") {
                                  _postfix = "file";
                                }
                              }

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(5.w),
                                    child: _isImage
                                        ? Image.file(
                                            File(_model.path),
                                            width: 40.w,
                                            height: 40.w,
                                            fit: BoxFit.cover,
                                          )
                                        : Image.asset(
                                            "images/$_postfix@2x.png",
                                            width: 40.w,
                                            height: 40.w,
                                            fit: BoxFit.cover,
                                          ),
                                  ),
                                  MaterialButton(
                                    onPressed: () {
                                      AlertVeiw.show(
                                        context,
                                        confirmText: "删除",
                                        contentText: "是否删除附件",
                                        cancelText: "取消",
                                        confirmAction: () {
                                          _attachmentList.removeAt(index);
                                          setState(() {
                                            if (widget.attachmentFeedback !=
                                                null) {
                                              widget.attachmentFeedback!(
                                                  _attachmentList);
                                            }
                                          });
                                        },
                                      );
                                    },
                                    minWidth: 40.w,
                                    height: 40.w,
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(5.w),
                                    ),
                                  ),
                                ],
                              );
                            },
                            separatorBuilder: (context, index) {
                              return SizedBox(width: 5.w);
                            },
                            itemCount: _attachmentList.length,
                          )
                        : SizedBox(),
                    _attachmentList.length == _maxAttachmentCount
                        ? SizedBox()
                        : Container(
                            width: 40.w,
                            height: 40.w,
                            margin: EdgeInsets.only(
                                left: _attachmentList.length > 0 ? 15.w : 0),
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                    "images/attachment_picker@2x.png"),
                              ),
                            ),
                            child: MaterialButton(
                              onPressed: () {
                                _filePicker();

                                setState(() {
                                  FocusScope.of(context)
                                      .requestFocus(FocusNode());
                                });
                              },
                              minWidth: 40.w,
                              height: 40.w,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.w),
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
