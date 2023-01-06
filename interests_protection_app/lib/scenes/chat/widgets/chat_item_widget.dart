import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/controllers/app_message_controller.dart';
import 'package:interests_protection_app/models/chat_record_model.dart';
import 'package:interests_protection_app/models/friend_model.dart';
import 'package:interests_protection_app/scenes/chat/widgets/chat_item_action_menu.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/file_preview_page.dart';

class ChatItemWidget extends StatelessWidget {
  final ChatRecordModel recordModel;
  final FriendModel? friendModel;
  final String chatRootPath;
  final void Function(bool isFile)? downloadAction;
  final void Function()? photoBrowerAction;
  final void Function()? deleteAction;
  final void Function()? resendAction;
  ChatItemWidget({
    Key? key,
    required this.recordModel,
    required this.chatRootPath,
    this.friendModel,
    this.downloadAction,
    this.deleteAction,
    this.resendAction,
    this.photoBrowerAction,
  }) : super(key: key);

  final AppHomeController _appHomeController = Get.find<AppHomeController>();

  // 长按菜单
  void _menuAction(int index) {
    if (index == 0) {
      Clipboard.setData(ClipboardData(text: recordModel.content));
    } else if (index == 1) {
      if (deleteAction != null) {
        deleteAction!();
      }
    }
  }

  // 发送状态
  Widget _sendStateWidget(BuildContext context, Color color) {
    return (recordModel.sendState == 1 || recordModel.sendState == -1)
        ? SizedBox()
        : Padding(
            padding: EdgeInsets.only(right: 8.w),
            child: recordModel.sendState == 2
                // 发送失败
                ? InkWell(
                    onTap: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) {
                          return CupertinoActionSheet(
                            actions: [
                              CupertinoActionSheetAction(
                                child: const Text("重发消息"),
                                onPressed: () {
                                  Navigator.pop(context);

                                  if (resendAction != null) {
                                    resendAction!();
                                  }
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
                    },
                    child: Icon(
                      Icons.error,
                      size: 16.w,
                      color: color,
                    ),
                  )
                // 发送中
                : SizedBox(
                    width: 10.w,
                    height: 10.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.w,
                      color: color,
                    ),
                  ),
          );
  }

  // 图片加载状态
  Widget _imageStateWidget(BuildContext context, {required String imagePath}) {
    return recordModel.sendState == 3
        ? SizedBox(
            width: 40.w,
            height: 40.w,
            child: Center(
              child: SizedBox(
                width: 18.w,
                height: 18.w,
                child: CircularProgressIndicator(),
              ),
            ),
          )
        : imagePath.length > 0
            ? ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 200.w,
                  maxHeight: 200.w,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.w),
                  child: InkWell(
                    onTap: () {
                      // 打开图片
                      if (photoBrowerAction != null) {
                        photoBrowerAction!();
                      }
                    },
                    child: Image.memory(File(imagePath).readAsBytesSync()),
                  ),
                ),
              )
            : recordModel.sendState == 2
                ? InkWell(
                    onTap: () {
                      if (downloadAction != null) {
                        downloadAction!(false);
                      }
                    },
                    child: Container(
                      width: 52.w,
                      height: 68.w,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(
                            "images/image@2x.png",
                          ),
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.refresh,
                          color: Colors.red,
                          size: 20.w,
                        ),
                      ),
                    ),
                  )
                : SizedBox();
  }

  // 文本
  Widget _textWitget(BuildContext context) {
    return recordModel.isMine == 1
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 文本内容
              ChatItemActionMenu(
                ignoring: recordModel.sendState == 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: kAppConfig.appThemeColor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10.w),
                      bottomLeft: Radius.circular(10.w),
                      bottomRight: Radius.circular(10.w),
                    ),
                  ),
                  constraints: BoxConstraints(maxWidth: 242.w),
                  padding: EdgeInsets.fromLTRB(11.w, 14.w, 12.w, 13.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 发送状态
                      _sendStateWidget(context, const Color(0xFFFFFFFF)),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: (recordModel.sendState == 1 ||
                                    recordModel.sendState == -1)
                                ? 219.w
                                : 195.w),
                        child: Text(
                          recordModel.content,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                menuAction: _menuAction,
              ),
              SizedBox(width: 9.w),
              // 头像
              networkImage(
                _appHomeController.accountModel.avatar,
                Size(40.w, 40.w),
                BorderRadius.circular(5.w),
                memoryData: true,
                placeholder: "images/personal_placeholder@2x.png",
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              friendModel == null
                  ? Image.asset(
                      "images/assistant_avatar@2x.png",
                      width: 40.w,
                      height: 44.w,
                    )
                  : GetBuilder<AppHomeController>(
                      id: "kFriendInfoUpdate",
                      init: _appHomeController,
                      builder: (controller) {
                        return networkImage(
                          friendModel!.avatar,
                          Size(40.w, 40.w),
                          BorderRadius.circular(5.w),
                          memoryData: true,
                          placeholder: "images/personal_placeholder@2x.png",
                        );
                      },
                    ),
              SizedBox(width: 8.w),
              // 过期信息
              recordModel.action == "lose" || recordModel.decrypt == 1
                  ? ChatItemActionMenu(
                      ignoring: false,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10.w),
                            bottomLeft: Radius.circular(10.w),
                            bottomRight: Radius.circular(10.w),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(11.w, 14.w, 12.w, 13.w),
                        child: Row(
                          children: [
                            Image.asset(
                              "images/identity_tip@2x.png",
                              width: 18.w,
                              height: 18.w,
                              color: kAppConfig.appErrorColor,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "消息已过期",
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: kAppConfig.appErrorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      menuAction: _menuAction,
                    )
                  // 文本内容
                  : ChatItemActionMenu(
                      ignoring: false,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10.w),
                            bottomLeft: Radius.circular(10.w),
                            bottomRight: Radius.circular(10.w),
                          ),
                        ),
                        constraints: BoxConstraints(maxWidth: 242.w),
                        padding: EdgeInsets.fromLTRB(11.w, 14.w, 12.w, 13.w),
                        child: Text(
                          recordModel.content,
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: const Color(0xFF000000),
                          ),
                        ),
                      ),
                      menuAction: _menuAction,
                      customActionList: ["复制", "删除"],
                    ),
            ],
          );
  }

  // 文件
  Widget _fileWitget(BuildContext context) {
    String _fileName = recordModel.filename;
    bool _isImage = false;
    String _postfix = "";
    String _filePath = "";
    String _fileSize = "";

    if (recordModel.isMine == 0) {
      // 已下载缓存文件
      _filePath = chatRootPath + "/download/${recordModel.content}";
    } else {
      // 本人发送缓存文件
      _filePath = chatRootPath + "/upload/${recordModel.content}";
    }

    if (_fileName.toLowerCase().contains(".jpg") ||
        _fileName.toLowerCase().contains(".png") ||
        _fileName.toLowerCase().contains(".jpeg") ||
        _fileName.toLowerCase().contains(".gif")) {
      _isImage = true;
      if (File(_filePath).existsSync() == false && recordModel.sendState != 3) {
        recordModel.sendState = 2;
        _filePath = "";
      }
    } else {
      _postfix =
          _fileName.trim().substring(_fileName.trim().lastIndexOf(".") + 1);
      if (_postfix != "doc" &&
          _postfix != "pdf" &&
          _postfix != "rar" &&
          _postfix != "xls") {
        _postfix = "file";
      }

      if (File(_filePath).existsSync()) {
        _fileSize = getFileSize(File(_filePath).readAsBytesSync().length);
      }
    }

    return recordModel.isMine == 1
        ? Row(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 文件名称
              ChatItemActionMenu(
                child: _isImage
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 发送状态
                          _sendStateWidget(context, kAppConfig.appThemeColor),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 200.w,
                              maxHeight: 200.w,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.w),
                              child: InkWell(
                                onTap: () {
                                  // 打开图片
                                  if (photoBrowerAction != null) {
                                    photoBrowerAction!();
                                  }
                                },
                                child: Image.file(File(_filePath)),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 发送状态
                          _sendStateWidget(context, kAppConfig.appThemeColor),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                            ),
                            child: MaterialButton(
                              onPressed: () {
                                // 打开文件
                                Get.to(
                                  FilePreviewPage(
                                    title: "文件预览",
                                    localPath: _filePath,
                                  ),
                                );
                              },
                              padding: EdgeInsets.fromLTRB(13.w, 6.w, 6.w, 6.w),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxWidth: 180.w),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _fileName,
                                          textAlign: TextAlign.end,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            color: const Color(0xFF000000),
                                            height: 1.5,
                                          ),
                                        ),
                                        _fileSize.length > 0
                                            ? Padding(
                                                padding:
                                                    EdgeInsets.only(top: 2.w),
                                                child: Text(
                                                  _fileSize,
                                                  textAlign: TextAlign.end,
                                                  style: TextStyle(
                                                    fontSize: 12.sp,
                                                    color:
                                                        const Color(0xFFA6A6A6),
                                                    fontWeight:
                                                        FontWeight.normal,
                                                  ),
                                                ),
                                              )
                                            : SizedBox(),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Image.asset(
                                    "images/$_postfix@2x.png",
                                    width: 34.w,
                                    height: 34.w,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                menuAction: (index) {
                  if (deleteAction != null) {
                    deleteAction!();
                  }
                },
                customActionList: ["删除"],
                ignoring: recordModel.sendState == 0,
              ),
              SizedBox(width: 9.w),
              // 头像
              Padding(
                padding: EdgeInsets.only(top: 4.w),
                child: networkImage(
                  _appHomeController.accountModel.avatar,
                  Size(40.w, 40.w),
                  BorderRadius.circular(5.w),
                  memoryData: true,
                  placeholder: "images/personal_placeholder@2x.png",
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              friendModel == null
                  ? Image.asset(
                      "images/assistant_avatar@2x.png",
                      width: 40.w,
                      height: 44.w,
                    )
                  : GetBuilder<AppHomeController>(
                      id: "kFriendInfoUpdate",
                      init: _appHomeController,
                      builder: (controller) {
                        return networkImage(
                          friendModel!.avatar,
                          Size(40.w, 40.w),
                          BorderRadius.circular(5.w),
                          memoryData: true,
                          placeholder: "images/personal_placeholder@2x.png",
                        );
                      },
                    ),
              SizedBox(width: 8.w),
              // 过期信息
              recordModel.action == "lose" || recordModel.decrypt == 1
                  ? ChatItemActionMenu(
                      ignoring: false,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(10.w),
                            bottomLeft: Radius.circular(10.w),
                            bottomRight: Radius.circular(10.w),
                          ),
                        ),
                        padding: EdgeInsets.fromLTRB(11.w, 14.w, 12.w, 13.w),
                        child: Row(
                          children: [
                            Image.asset(
                              "images/identity_tip@2x.png",
                              width: 18.w,
                              height: 18.w,
                              color: kAppConfig.appErrorColor,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              "消息已过期",
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: kAppConfig.appErrorColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      menuAction: _menuAction,
                    )
                  :
                  // 文件名称
                  ChatItemActionMenu(
                      child: _isImage
                          ? _imageStateWidget(context, imagePath: _filePath)
                          : Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                              ),
                              child: MaterialButton(
                                onPressed: recordModel.sendState == 3
                                    ? null
                                    : () {
                                        if (File(_filePath).existsSync() ==
                                            false) {
                                          // 下载文件
                                          if (downloadAction != null) {
                                            downloadAction!(true);
                                          }
                                        } else {
                                          // 打开文件
                                          Get.to(
                                            FilePreviewPage(
                                              title: "文件预览",
                                              localPath: _filePath,
                                            ),
                                          );
                                        }
                                      },
                                padding:
                                    EdgeInsets.fromLTRB(6.w, 6.w, 13.w, 6.w),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      "images/$_postfix@2x.png",
                                      width: 34.w,
                                      height: 34.w,
                                    ),
                                    SizedBox(width: 8.w),
                                    ConstrainedBox(
                                      constraints:
                                          BoxConstraints(maxWidth: 180.w),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _fileName,
                                            textAlign: TextAlign.start,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              color: const Color(0xFF000000),
                                              height: 1.5,
                                            ),
                                          ),
                                          _fileSize.length > 0
                                              ? Padding(
                                                  padding:
                                                      EdgeInsets.only(top: 2.w),
                                                  child: Text(
                                                    _fileSize,
                                                    textAlign: TextAlign.start,
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: const Color(
                                                          0xFFA6A6A6),
                                                      fontWeight:
                                                          FontWeight.normal,
                                                    ),
                                                  ),
                                                )
                                              : SizedBox(),
                                        ],
                                      ),
                                    ),
                                    // 下载中
                                    SizedBox(
                                        width: recordModel.sendState == 3
                                            ? 12.w
                                            : 0),
                                    recordModel.sendState == 3
                                        ? Center(
                                            child: SizedBox(
                                              width: 16.w,
                                              height: 16.w,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3.w,
                                              ),
                                            ),
                                          )
                                        : SizedBox(),
                                    // 下载失败
                                    SizedBox(
                                        width: recordModel.sendState == 2
                                            ? 12.w
                                            : 0),
                                    recordModel.sendState == 2
                                        ? Center(
                                            child: Icon(
                                              Icons.refresh,
                                              color: Colors.red,
                                              size: 20.w,
                                            ),
                                          )
                                        : SizedBox(),
                                  ],
                                ),
                              ),
                            ),
                      menuAction: (index) {
                        if (deleteAction != null) {
                          deleteAction!();
                        }
                      },
                      customActionList: ["删除"],
                      ignoring: recordModel.sendState == 3,
                    ),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppMessageController>(
      id: "${recordModel.eventId}",
      builder: (controller) {
        return recordModel.eventName == "customer_switch"
            ? // 客服切换提示
            Center(
                child: Text(
                  recordModel.content,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: kAppConfig.appPlaceholderColor,
                  ),
                ),
              )
            : Column(
                children: recordModel.action == "risk_warn"
                    ? [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5EAC6),
                            borderRadius: BorderRadius.circular(10.w),
                          ),
                          alignment: Alignment.center,
                          margin: EdgeInsets.only(left: 3.w, right: 3.w),
                          height: 40.w,
                          child: Text(
                            "当前用户可能非本人或异常，建议不进行通信！",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: kAppConfig.appThemeColor,
                            ),
                          ),
                        )
                      ]
                    : [
                        Column(
                          children: [
                            // 日期
                            Text(
                              // 欢迎信息
                              recordModel.action == "friend_add"
                                  ? "你已经添加该好友，现在可以开始聊天了。"
                                  : timeLineFormat(date: recordModel.time),
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: kAppConfig.appPlaceholderColor,
                              ),
                            ),
                            SizedBox(
                                height: recordModel.action == "friend_add"
                                    ? 0
                                    : 15.w),
                          ],
                        ),
                        recordModel.action == "text"
                            ? _textWitget(context)
                            : recordModel.action == "file"
                                ? _fileWitget(context)
                                : SizedBox(),
                      ],
              );
      },
    );
  }
}
