import 'dart:convert';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/tickets_api.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/controllers/app_message_controller.dart';
import 'package:interests_protection_app/models/tickets_attach_model.dart';
import 'package:interests_protection_app/networking/file_upload_client.dart';
import 'package:interests_protection_app/scenes/tickets/tickets_record_page.dart';
import 'package:interests_protection_app/scenes/tickets/widgets/tickets_attachment_level.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class TicketsPublishPage extends StatefulWidget {
  const TicketsPublishPage({Key? key}) : super(key: key);

  @override
  State<TicketsPublishPage> createState() => _TicketsPublishPageState();
}

class _TicketsPublishPageState extends State<TicketsPublishPage> {
  final TextEditingController _nameEditingController = TextEditingController();
  final TextEditingController _contentEditingController =
      TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _contentFocusNode = FocusNode();
  final FocusNode _nameFocusNode = FocusNode();
  final int _maxContentLength = 400;
  bool _canSubmit = false;
  bool _isContentKeyboardShow = false;
  List<String> _categoryList = [];
  int _categoryIndex = -1;
  String _tag = "";

  final TextEditingController _idEditingController = TextEditingController();
  final TextEditingController _contactEditingController =
      TextEditingController();
  final TextEditingController _mobileEditingController =
      TextEditingController();

  List<TicketsAttachModel> _attachmentList = [];
  String _cryptFilePath = "";

  final List<String> _replyTypeList = [
    "接受回信",
    "不接受回信",
  ];
  int _replyTypeIndex = 0;

  bool _backgroudSubmit = false;
  // 清空图片缓存
  void _cleanCacheImages() {
    if (_backgroudSubmit == false) {
      void _action(List<TicketsAttachModel> images) {
        images.forEach((element) {
          try {
            File(element.path).deleteSync();
          } catch (e) {}
        });
      }

      List<TicketsAttachModel> _list = List<TicketsAttachModel>.from(
          _attachmentList.where((element) => element.isImage == true));
      if (_list.length > 0) {
        QueueUtil.get("kTicketsCleanImages")?.addTask(() {
          return _action(_list);
        });
      }
    }
  }

  // 救援类型
  int _rescueTypeIndex = 0;
  List<String> _rescueTypeList = ["绑架", "人口贩卖", "其他"];
  void _rescueTypeDialog() {
    FocusScope.of(context).requestFocus(FocusNode());
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: List.generate(_rescueTypeList.length, (index) => index)
              .map((index) {
            return CupertinoActionSheetAction(
              child: Text("${_rescueTypeList[index]}"),
              onPressed: () {
                Navigator.pop(context);
                _rescueTypeIndex = index;
                setState(() {});
              },
            );
          }).toList(),
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

  // 回信类型
  void _replyTypeDialog() {
    FocusScope.of(context).requestFocus(FocusNode());
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: List.generate(_replyTypeList.length, (index) => index)
              .map((index) {
            return CupertinoActionSheetAction(
              child: Text("${_replyTypeList[index]}"),
              onPressed: () {
                Navigator.pop(context);
                _replyTypeIndex = index;
                setState(() {});
              },
            );
          }).toList(),
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

  // 上报类型
  void _ticketsTypeDialog() {
    if (_categoryList.length == 0) {
      _getTicketsCategory(
        finish: () {
          _ticketsTypeDialog();
        },
      );
      return;
    }

    FocusScope.of(context).requestFocus(FocusNode());
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          actions: List.generate(_categoryList.length, (index) => index)
              .map((index) {
            return CupertinoActionSheetAction(
              child: Text(
                "${_categoryList[index]}",
                style: TextStyle(
                  color: (_categoryList[index].contains("申请救援"))
                      ? kAppConfig.appThemeColor
                      : null,
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _categoryIndex = index;
                setState(() {
                  _checkAviable();
                });
              },
            );
          }).toList(),
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

  // 获取上报类型
  void _getTicketsCategory({void Function()? finish}) {
    SVProgressHUD.show();
    TicketsApi.category().then((value) {
      _categoryList = List<String>.from(value ?? []);
      _categoryList.removeWhere((element) => element.contains("意见反馈"));
      _categoryList.removeWhere((element) => element.contains("客服投诉"));
      if (Get.find<AppHomeController>().accountModel.level == 0 ||
          Get.find<AppHomeController>().accountModel.real == 0) {
        _categoryList.removeWhere((element) => element.contains("申请救援"));
      }

      setState(() {
        SVProgressHUD.dismiss();

        if (finish != null && _categoryList.length > 0) {
          finish();
        }
      });
    }).catchError((error) {
      SVProgressHUD.dismiss();
    });
  }

  // 校验
  void _checkAviable() {
    if (_categoryIndex >= 0 &&
        _contentEditingController.text.trim().length > 0 &&
        _tag.length > 0 &&
        _replyTypeIndex >= 0) {
      _canSubmit = true;
    } else {
      _canSubmit = false;
    }

    setState(() {});
  }

  // 后台提交
  void _backgroudSubmitTickets() {
    Map<String, dynamic> _params = (_categoryIndex >= 0 &&
            "${_categoryList[_categoryIndex]}".contains("申请救援"))
        ? {
            "category": _categoryList[_categoryIndex],
            "receive": false,
            "content": """ 
救援类型:${_rescueTypeList[_rescueTypeIndex]}
姓名:${_nameEditingController.text}
身份证:${_idEditingController.text}
联系人:${_contactEditingController.text}
联系人电话:${_mobileEditingController.text.replaceAll(" ", "")}
${_contentEditingController.text}
""",
            "tag": "紧急",
            "accessory": [],
          }
        : {
            "category": _categoryList[_categoryIndex],
            "receive": _replyTypeIndex == 1 ? false : true,
            "content": _contentEditingController.text,
            "tag": _tag,
            "accessory": [],
          };

    List _accessory = [];
    void _publishTickets() async {
      var _json =
          await CryptoUtils.publicKeyEncryptRequest(jsonEncode(_params));
      TicketsApi.tickets(params: _json).then((value) {
        utilsToast(msg: "工单发布成功");
      }).catchError((error) {
        debugPrint("工单发布失败:$error");
      });
    }

    if (_attachmentList.length > 0) {
      // 文件加密
      List<EncryptFileDataModel> _fileList = [];
      _attachmentList.forEach((element) {
        EncryptFileDataModel _fileDataModel = EncryptFileDataModel(
          fileType: element.extension,
          fileData: File(element.path).readAsBytesSync(),
          fileId: element.fileId,
          fileName: element.fileName,
        );

        _fileList.add(_fileDataModel);
      });

      // 清空图片缓存
      void _cleanCacheImages() {
        void _action(List<TicketsAttachModel> images) {
          images.forEach((element) {
            debugPrint("清空图片缓存");
            try {
              File(element.path).deleteSync();
            } catch (e) {}
          });
        }

        List<TicketsAttachModel> _list = List<TicketsAttachModel>.from(
            _attachmentList.where((element) => element.isImage == true));
        if (_list.length > 0) {
          QueueUtil.get("kTicketsCleanImages")?.addTask(() {
            return _action(_list);
          });
        }
      }

      Map<String, dynamic> _encryptParams = {
        "config": kAppConfig,
        "fileList": _fileList,
        "cryptFilePath": _cryptFilePath,
      };

      compute(AppMessageController.encryptFileList, _encryptParams)
          .then((value) {
        List<EncryptFileDataModel> _encryptFileList = value["files"];
        List<EncryptFileDataModel> _failure = value["failure"];
        if (_failure.length > 0) {
          debugPrint("加密失败:${_failure.length}");
        }

        String _encryptSalt = value["salt"];
        // 上传文件
        FileUploadClient.uploadFile(
          "${kAppConfig.apiUrl}/tickets/file",
          _encryptFileList,
          key: "file",
          params: {"salt": _encryptSalt},
        ).then((value) {
          _accessory = List.from(value["data"] ?? []);
          _params["accessory"] = _accessory;
          _publishTickets();
          _cleanCacheImages();
        }).catchError((error) {
          debugPrint("上传文件失败:$error");
          _cleanCacheImages();
        });
      }).catchError((error) {
        debugPrint("加密文件失败:$error");
        _cleanCacheImages();
      });
    } else {
      _publishTickets();
    }
  }

  // 提交
  void _onSubmit() async {
    if (_categoryIndex >= 0 &&
        "${_categoryList[_categoryIndex]}".contains("申请救援")) {
      if (isIdCard(_idEditingController.text) == false) {
        utilsToast(msg: "请输入合法的身份证号码！");
        return;
      }

      if (_mobileEditingController.text.replaceAll(" ", "").length != 11 ||
          RegexUtil.isMobileExact(
                  _mobileEditingController.text.replaceAll(" ", "")) ==
              false) {
        utilsToast(msg: "请输入合法的手机号码！");
        return;
      }
    }

    _backgroudSubmit = true;
    setState(() {
      Get.back();
    });

    QueueUtil.get("kTicketsOnSubmit")?.addTask(() {
      return _backgroudSubmitTickets();
    });
  }

  @override
  void initState() {
    super.initState();

    _getTicketsCategory();

    _contentFocusNode.addListener(() {
      setState(() {});
    });
    _nameFocusNode.addListener(() {
      setState(() {});
    });

    StorageUtils.getUserTicketsPath(isCrypt: true).then((value) {
      _cryptFilePath = value;
      setState(() {});
    });

    StorageUtils.getUserTicketsPath().then((value) {});
  }

  @override
  void dispose() {
    _cleanCacheImages();
    _nameEditingController.dispose();
    _contentEditingController.dispose();
    _scrollController.dispose();
    _contentFocusNode.removeListener(() {});
    _nameFocusNode.removeListener(() {});
    _contentFocusNode.dispose();
    _nameFocusNode.dispose();
    _idEditingController.dispose();
    _contactEditingController.dispose();
    _mobileEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        leadingWidth: 140.w,
        leading: Row(
          children: [
            AppbarBack(),
            SizedBox(width: 10.w),
            MaterialButton(
              onPressed: () {
                Get.to(TicketsRecordPage());
                FocusScope.of(context).requestFocus(FocusNode());
              },
              minWidth: 44.w,
              height: 44.w,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(44.w / 2),
              ),
              child: Image.asset(
                "images/report_record@2x.png",
                width: 25.w,
                height: 23.w,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // 提示
          GetBuilder<AppHomeController>(
            id: "kUpdateAccountInfo",
            builder: (controller) {
              return controller.accountModel.level == 0
                  ? Container(
                      height: 25.w,
                      color: const Color(0xFFFAFAFA),
                      alignment: Alignment.center,
                      child: Text(
                        "当前等级为非VIP会员仅提供信息上报功能",
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: const Color(0xFFB3B3B3),
                        ),
                      ),
                    )
                  : SizedBox();
            },
          ),
          Expanded(
            child: NotificationListener(
              onNotification: (notification) {
                if (notification is ScrollStartNotification &&
                    _scrollController.offset ==
                        _scrollController.position.maxScrollExtent &&
                    _isContentKeyboardShow == true &&
                    _scrollController.hasClients) {
                  _isContentKeyboardShow = false;
                  FocusScope.of(context).requestFocus(FocusNode());
                }

                return true;
              },
              child: ListView(
                controller: _scrollController,
                children: [
                  // 上报类型
                  Container(
                    height: 50.w,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: 0.5.w,
                            color: const Color(0xFFF2F2F2),
                          ),
                        ),
                      ),
                      child: MaterialButton(
                        onPressed: () {
                          _ticketsTypeDialog();
                        },
                        padding: EdgeInsets.only(left: 15.w, right: 15.w),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero),
                        child: Row(
                          children: [
                            Row(
                              children: [
                                Text(
                                  "上报类型",
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: const Color(0xFF808080),
                                  ),
                                ),
                                SizedBox(width: 5.w),
                                Text(
                                  "*",
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: const Color(0xFF808080),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: 19.w),
                            Expanded(
                              child: Text(
                                _categoryIndex == -1
                                    ? "未选择"
                                    : "${_categoryList[_categoryIndex]}",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  color: _categoryIndex == -1 ||
                                          ("${_categoryList[_categoryIndex]}"
                                              .contains("申请救援"))
                                      ? kAppConfig.appThemeColor
                                      : const Color(0xFF000000),
                                ),
                              ),
                            ),
                            Image.asset(
                              "images/report_type_arrow@2x.png",
                              width: 12.w,
                              height: 12.w,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 回信设置
                  (_categoryIndex >= 0 &&
                          "${_categoryList[_categoryIndex]}".contains("申请救援"))
                      ? SizedBox()
                      : Container(
                          height: 50.w,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 0.5.w,
                                  color: const Color(0xFFF2F2F2),
                                ),
                              ),
                            ),
                            child: MaterialButton(
                              onPressed: () {
                                _replyTypeDialog();
                              },
                              padding: EdgeInsets.only(left: 15.w, right: 15.w),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                              child: Row(
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "回信设置",
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          color: const Color(0xFF808080),
                                        ),
                                      ),
                                      SizedBox(width: 5.w),
                                      Text(
                                        "*",
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          color: const Color(0xFF808080),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(width: 19.w),
                                  Expanded(
                                    child: Text(
                                      _replyTypeIndex == -1
                                          ? "未选择"
                                          : "${_replyTypeList[_replyTypeIndex]}",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: _replyTypeIndex == -1
                                            ? kAppConfig.appThemeColor
                                            : const Color(0xFF000000),
                                      ),
                                    ),
                                  ),
                                  Image.asset(
                                    "images/report_type_arrow@2x.png",
                                    width: 12.w,
                                    height: 12.w,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                  // 昵称
                  (_categoryIndex >= 0 &&
                          "${_categoryList[_categoryIndex]}".contains("申请救援"))
                      ? Column(
                          children: [
                            // 救援类型
                            Container(
                              height: 50.w,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      width: 0.5.w,
                                      color: const Color(0xFFF2F2F2),
                                    ),
                                  ),
                                ),
                                child: MaterialButton(
                                  onPressed: () {
                                    _rescueTypeDialog();
                                  },
                                  padding:
                                      EdgeInsets.only(left: 15.w, right: 15.w),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero),
                                  child: Row(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "救援类型",
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              color: const Color(0xFF808080),
                                            ),
                                          ),
                                          SizedBox(width: 5.w),
                                          Text(
                                            "*",
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              color: const Color(0xFF808080),
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(width: 19.w),
                                      Expanded(
                                        child: Text(
                                          "${_rescueTypeList[_rescueTypeIndex]}",
                                          style: TextStyle(
                                            fontSize: 15.sp,
                                            color: const Color(0xFF000000),
                                          ),
                                        ),
                                      ),
                                      Image.asset(
                                        "images/report_type_arrow@2x.png",
                                        width: 12.w,
                                        height: 12.w,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // 您的姓名
                            Container(
                              height: 50.w,
                              padding: EdgeInsets.only(left: 15.w, right: 15.w),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      width: 0.5.w,
                                      color: const Color(0xFFF2F2F2),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "您的姓名",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: const Color(0xFF808080),
                                      ),
                                    ),
                                    SizedBox(width: 30.w),
                                    Expanded(
                                      child: TextField(
                                        controller: _nameEditingController,
                                        style: TextStyle(
                                          color: const Color(0xFF000000),
                                          fontSize: 15.sp,
                                        ),
                                        decoration: InputDecoration(
                                          counterText: "",
                                          border: InputBorder.none,
                                        ),
                                        textInputAction: TextInputAction.next,
                                        onChanged: (value) {
                                          _checkAviable();
                                        },
                                        onSubmitted: (value) {},
                                        onEditingComplete: () {
                                          FocusScope.of(context)
                                              .requestFocus(FocusNode());
                                        },
                                        onTap: () {
                                          _scrollController.jumpTo(50.w);
                                          _isContentKeyboardShow = false;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 身份证号
                            Container(
                              height: 50.w,
                              padding: EdgeInsets.only(left: 15.w, right: 15.w),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      width: 0.5.w,
                                      color: const Color(0xFFF2F2F2),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "身份证号",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: const Color(0xFF808080),
                                      ),
                                    ),
                                    SizedBox(width: 30.w),
                                    Expanded(
                                      child: TextField(
                                        controller: _idEditingController,
                                        style: TextStyle(
                                          color: const Color(0xFF000000),
                                          fontSize: 15.sp,
                                        ),
                                        decoration: InputDecoration(
                                          counterText: "",
                                          border: InputBorder.none,
                                        ),
                                        textInputAction: TextInputAction.next,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp("[0-9_X]")),
                                          LengthLimitingTextInputFormatter(18)
                                        ],
                                        onChanged: (value) {
                                          _checkAviable();
                                        },
                                        onSubmitted: (value) {},
                                        onEditingComplete: () {
                                          FocusScope.of(context)
                                              .requestFocus(FocusNode());
                                        },
                                        onTap: () {
                                          _scrollController.jumpTo(100.w);
                                          _isContentKeyboardShow = false;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 帮你联系谁
                            Container(
                              height: 50.w,
                              padding: EdgeInsets.only(left: 15.w, right: 15.w),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      width: 0.5.w,
                                      color: const Color(0xFFF2F2F2),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "帮你联系谁",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: const Color(0xFF808080),
                                      ),
                                    ),
                                    SizedBox(width: 30.w),
                                    Expanded(
                                      child: TextField(
                                        controller: _contactEditingController,
                                        style: TextStyle(
                                          color: const Color(0xFF000000),
                                          fontSize: 15.sp,
                                        ),
                                        decoration: InputDecoration(
                                          counterText: "",
                                          border: InputBorder.none,
                                        ),
                                        textInputAction: TextInputAction.next,
                                        onChanged: (value) {
                                          _checkAviable();
                                        },
                                        onSubmitted: (value) {},
                                        onEditingComplete: () {
                                          FocusScope.of(context)
                                              .requestFocus(FocusNode());
                                        },
                                        onTap: () {
                                          _scrollController.jumpTo(150.w);
                                          _isContentKeyboardShow = false;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // 联系人电话
                            Container(
                              height: 50.w,
                              padding: EdgeInsets.only(left: 15.w, right: 15.w),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      width: 0.5.w,
                                      color: const Color(0xFFF2F2F2),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      "联系人电话",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: const Color(0xFF808080),
                                      ),
                                    ),
                                    SizedBox(width: 30.w),
                                    Expanded(
                                      child: TextField(
                                        controller: _mobileEditingController,
                                        style: TextStyle(
                                          color: const Color(0xFF000000),
                                          fontSize: 15.sp,
                                        ),
                                        decoration: InputDecoration(
                                          counterText: "",
                                          border: InputBorder.none,
                                        ),
                                        textInputAction: TextInputAction.next,
                                        maxLength: 16,
                                        inputFormatters: phoneInputFormatters(),
                                        onChanged: (value) {
                                          _checkAviable();
                                        },
                                        keyboardType: TextInputType.phone,
                                        onSubmitted: (value) {},
                                        onEditingComplete: () {
                                          FocusScope.of(context)
                                              .requestFocus(FocusNode());
                                        },
                                        onTap: () {
                                          _scrollController.jumpTo(200.w);
                                          _isContentKeyboardShow = false;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          height: 50.w,
                          padding: EdgeInsets.only(left: 15.w, right: 15.w),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  width: 0.5.w,
                                  color: const Color(0xFFF2F2F2),
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "昵",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: const Color(0xFF808080),
                                      ),
                                    ),
                                    SizedBox(width: 30.w),
                                    Text(
                                      "称",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        color: const Color(0xFF808080),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 30.w),
                                Expanded(
                                  child: TextField(
                                    controller: _nameEditingController,
                                    focusNode: _nameFocusNode,
                                    style: TextStyle(
                                      color: const Color(0xFF000000),
                                      fontSize: 15.sp,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "输入昵称",
                                      hintStyle: TextStyle(
                                        color: const Color(0xFF808080),
                                        fontSize: 15.sp,
                                      ),
                                      counterText: "",
                                      border: InputBorder.none,
                                    ),
                                    textInputAction: TextInputAction.next,
                                    onChanged: (value) {
                                      _checkAviable();
                                    },
                                    onSubmitted: (value) {
                                      if (value == " " ||
                                          value.trim().length == 0) {
                                        _nameEditingController.clear();

                                        FocusScope.of(context)
                                            .requestFocus(_nameFocusNode);
                                      } else if (value.length > 0) {
                                        FocusScope.of(context)
                                            .requestFocus(_contentFocusNode);
                                      }
                                    },
                                    onEditingComplete: () {
                                      FocusScope.of(context)
                                          .requestFocus(FocusNode());
                                    },
                                    onTap: () {
                                      _scrollController.jumpTo(0);
                                      _isContentKeyboardShow = false;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  // 内容输入
                  GestureDetector(
                    onTap: () {
                      FocusScope.of(context).requestFocus(_contentFocusNode);

                      Future.delayed(Duration(milliseconds: 500), () {
                        if (_scrollController.hasClients &&
                            _scrollController.offset !=
                                _scrollController.position.maxScrollExtent) {
                          _scrollController.jumpTo(
                              _scrollController.position.maxScrollExtent);
                          _isContentKeyboardShow = true;
                        }
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.only(left: 15.w, right: 11.w),
                      alignment: Alignment.topCenter,
                      color: const Color(0xFFFFFFFF),
                      height: MediaQuery.of(context).size.height -
                          50.w * 3 -
                          MediaQuery.of(context).padding.top -
                          AppBar().preferredSize.height -
                          MediaQuery.of(context).viewInsets.bottom,
                      child: TextField(
                        maxLength: _maxContentLength,
                        controller: _contentEditingController,
                        focusNode: _contentFocusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 15.sp,
                        ),
                        decoration: InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                          hintText: "详情描述...",
                          hintStyle: TextStyle(
                            color: const Color(0xFFDBDBDB),
                            fontSize: 15.sp,
                          ),
                        ),
                        onChanged: (value) {
                          _checkAviable();
                        },
                        onSubmitted: (value) {},
                        onTap: () {
                          Future.delayed(Duration(milliseconds: 500), () {
                            if (_scrollController.hasClients &&
                                _scrollController.offset !=
                                    _scrollController
                                        .position.maxScrollExtent) {
                              _scrollController.jumpTo(
                                  _scrollController.position.maxScrollExtent);
                              _isContentKeyboardShow = true;
                              setState(() {});
                            }
                          });
                        },
                        onEditingComplete: () {
                          FocusScope.of(context).requestFocus(FocusNode());
                          _isContentKeyboardShow = false;
                        },
                      ),
                    ),
                  ),
                ],
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
          // 附件，紧急
          TicketsAttachmentLevel(
            contentFocusNode: _contentFocusNode,
            nameFocusNode: _nameFocusNode,
            disableLevel: (_categoryIndex >= 0 &&
                "${_categoryList[_categoryIndex]}".contains("申请救援")),
            tagFeedback: (tag) {
              _tag = tag;
              setState(() {});
            },
            attachmentFeedback: (attachments) {
              _attachmentList = attachments;
              setState(() {});
            },
            attachmentLevelShow: (show) {
              if (show) {
                FocusScope.of(context).requestFocus(FocusNode());
                _isContentKeyboardShow = false;
                _scrollController.jumpTo(0);
              } else {
                FocusScope.of(context).requestFocus(_contentFocusNode);
                _isContentKeyboardShow = true;
              }
            },
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
