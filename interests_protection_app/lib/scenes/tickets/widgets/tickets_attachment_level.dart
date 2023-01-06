import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:interests_protection_app/models/tickets_attach_model.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/image_picker.dart';

class TicketsAttachmentLevel extends StatefulWidget {
  final void Function(String tag)? tagFeedback;
  final void Function(bool show)? attachmentLevelShow;
  final FocusNode? contentFocusNode;
  final FocusNode? nameFocusNode;
  final bool? cleanReset;
  final void Function(List<TicketsAttachModel> attachments)? attachmentFeedback;
  final bool? disableLevel;
  const TicketsAttachmentLevel({
    Key? key,
    this.contentFocusNode,
    this.nameFocusNode,
    required this.tagFeedback,
    required this.attachmentLevelShow,
    this.cleanReset,
    this.attachmentFeedback,
    this.disableLevel,
  }) : super(key: key);

  @override
  State<TicketsAttachmentLevel> createState() => _TicketsAttachmentLevelState();
}

class _TicketsAttachmentLevelState extends State<TicketsAttachmentLevel> {
  List<TicketsAttachModel> _attachmentList = [];
  List<String> _levelList = ["紧急", "较急", "常规"];
  List<Color> _levelColorList = [
    const Color(0xFFE64646),
    const Color(0xFFFFC300),
    const Color(0xFF43CF7C),
  ];
  int _levelIndex = 2;
  int _maxAttachmentCount = 4;
  double _contentHeight = 0;

  // 文件选择
  void _filePicker() {
    _contentHeight = 250.w;
    setState(() {
      if (widget.attachmentLevelShow != null) {
        widget.attachmentLevelShow!(_contentHeight > 0);
      }
    });

    // 图片处理
    void _handleAssetFile(List<File> list) {
      if (list.length == 0) {
        return;
      }

      SVProgressHUD.show();
      list.forEach((element) {
        int size = element.readAsBytesSync().length;
        String name = element.path
            .trim()
            .substring(element.path.trim().lastIndexOf("/") + 1);
        String extension =
            name.trim().substring(name.trim().lastIndexOf(".") + 1);

        TicketsAttachModel? _existModel = _attachmentList.firstWhereOrNull(
            (model) => model.path == element.path && model.fileName == name);
        if (_existModel == null &&
            _attachmentList.length < _maxAttachmentCount) {
          TicketsAttachModel _model = TicketsAttachModel.fromJson({});
          _model.path = element.path;
          _model.fileSize = getFileSize(size);
          _model.extension = extension;
          _model.fileName = name;
          _model.isImage = true;
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
            CupertinoActionSheetAction(
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
  void initState() {
    super.initState();

    if (widget.contentFocusNode != null) {
      widget.contentFocusNode!.addListener(() {
        if (widget.contentFocusNode!.hasFocus && _contentHeight > 0) {
          _contentHeight = 0;
          setState(() {});
        }
      });
    }

    if (widget.nameFocusNode != null) {
      widget.nameFocusNode!.addListener(() {
        if (widget.nameFocusNode!.hasFocus && _contentHeight > 0) {
          _contentHeight = 0;
          setState(() {});
        }
      });
    }

    Future.delayed(Duration(milliseconds: 100), () {
      if (widget.tagFeedback != null) {
        widget.tagFeedback!(_levelList[_levelIndex]);
      }
    });
  }

  bool _resetAction = false;
  @override
  void didUpdateWidget(covariant TicketsAttachmentLevel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.cleanReset ?? false) == true && _resetAction == false) {
      _resetAction = true;

      _attachmentList.clear();
      _levelIndex = 2;
      _contentHeight = 0;

      Future.delayed(Duration(milliseconds: 500), () {
        if (widget.tagFeedback != null) {
          widget.tagFeedback!(_levelList[_levelIndex]);
        }

        _resetAction = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Column(
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
                        ? SizedBox(
                            height: 53.w,
                            child: InkWell(
                              onTap: () {
                                if (_contentHeight == 0) {
                                  _contentHeight = 250.w;
                                } else {
                                  _contentHeight = 0;
                                }

                                setState(() {
                                  if (widget.attachmentLevelShow != null) {
                                    widget.attachmentLevelShow!(
                                        _contentHeight > 0);
                                  }
                                });
                              },
                              child: Row(
                                children: [
                                  Image.asset(
                                    "images/attachment_icon@2x.png",
                                    width: 16.w,
                                    height: 16.w,
                                  ),
                                  SizedBox(width: 2.w),
                                  Text(
                                    "${_attachmentList.length}/$_maxAttachmentCount",
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: const Color(0xFFB3B3B3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                (widget.disableLevel ?? false) == true
                    ? SizedBox()
                    : SizedBox(
                        height: 35.w,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          padding: EdgeInsets.only(right: 11.w),
                          itemBuilder: (context, index) {
                            return MaterialButton(
                              onPressed: () {
                                _levelIndex = index;
                                setState(() {
                                  Future.delayed(Duration(milliseconds: 100),
                                      () {
                                    if (widget.tagFeedback != null) {
                                      widget.tagFeedback!(
                                          _levelList[_levelIndex]);
                                    }
                                  });
                                });
                              },
                              padding: EdgeInsets.zero,
                              minWidth: 75.w,
                              height: 35.w,
                              color: _levelIndex == index
                                  ? _levelColorList[_levelIndex]
                                  : const Color(0xFFF7F7F7),
                              elevation: 0,
                              highlightElevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(35.w),
                              ),
                              child: Text(
                                _levelList[index],
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: _levelIndex == index
                                      ? const Color(0xFFFFFFFF)
                                      : const Color(0xFFB3B3B3),
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (context, index) {
                            return SizedBox(width: 10.w);
                          },
                          itemCount: _levelList.length,
                        ),
                      ),
              ],
            ),
          ),
          Container(
            height: _contentHeight,
            color: const Color(0xFFFFFFFF),
            child: GridView.builder(
              padding: EdgeInsets.fromLTRB(15.w, 0, 15.w, 0),
              physics: BouncingScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10.w,
                crossAxisSpacing: 10.w,
                childAspectRatio: 107.w / 157.w,
              ),
              itemBuilder: (context, index) {
                TicketsAttachModel _model = _attachmentList[index];
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

                return InkWell(
                  onTap: () {
                    AlertVeiw.show(
                      context,
                      confirmText: "删除",
                      contentText: "是否删除附件",
                      cancelText: "取消",
                      confirmAction: () {
                        _attachmentList.removeAt(index);
                        setState(() {
                          if (widget.attachmentFeedback != null) {
                            widget.attachmentFeedback!(_attachmentList);
                          }
                        });
                      },
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isImage
                          ? Image.file(
                              File(_model.path),
                              width: 34.w,
                              height: 34.w,
                            )
                          : Image.asset(
                              "images/$_postfix@2x.png",
                              width: 34.w,
                              height: 34.w,
                            ),
                      SizedBox(height: 10.w),
                      Text(
                        "${_model.fileName}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFF000000),
                        ),
                      ),
                      SizedBox(height: 10.w),
                      Text(
                        "${_model.fileSize}",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFB3B3B3),
                        ),
                      )
                    ],
                  ),
                );
              },
              itemCount: _attachmentList.length,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
