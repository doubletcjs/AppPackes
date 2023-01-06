import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/tickets_api.dart';
import 'package:interests_protection_app/controllers/app_message_controller.dart';
import 'package:interests_protection_app/models/tickets_attach_model.dart';
import 'package:interests_protection_app/networking/file_upload_client.dart';
import 'package:interests_protection_app/scenes/tickets/widgets/file_attachment_picker.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class FeedbackComplaintPage extends StatefulWidget {
  final bool? feedback;
  const FeedbackComplaintPage({
    Key? key,
    this.feedback,
  }) : super(key: key);

  @override
  State<FeedbackComplaintPage> createState() => _FeedbackComplaintPageState();
}

class _FeedbackComplaintPageState extends State<FeedbackComplaintPage> {
  final TextEditingController _contentEditingController =
      TextEditingController();
  final int _maxContentLength = 400;
  bool _canSubmit = false;
  List<TicketsAttachModel> _attachmentList = [];
  String _cryptFilePath = "";
  String _category = "客服投诉";

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

  // 校验
  void _checkAviable() {
    if (_contentEditingController.text.trim().length > 0) {
      _canSubmit = true;
    } else {
      _canSubmit = false;
    }

    setState(() {});
  }

  // 后台提交
  void _backgroudSubmitTickets() {
    String category = _category;
    Map<String, dynamic> _params = {
      "category": category,
      "receive": true,
      "content": _contentEditingController.text,
      "tag": "常规",
      "accessory": [],
    };

    List _accessory = [];
    void _publishTickets({bool autoBack = false}) async {
      var _json =
          await CryptoUtils.publicKeyEncryptRequest(jsonEncode(_params));
      TicketsApi.tickets(params: _json).then((value) {
        if (autoBack == true) {
          Future.delayed(Duration(milliseconds: 300), () {
            utilsToast(msg: "$category发布成功");
            Get.back();
          });
        }
      }).catchError((error) {
        debugPrint("$category发布失败:$error");
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

      Future.delayed(Duration(milliseconds: 100), () {
        Get.back();
      });
    } else {
      FocusScope.of(context).requestFocus(FocusNode());
      _publishTickets(autoBack: true);
    }
  }

  // 提交
  void _onSubmit() async {
    _backgroudSubmit = true;
    setState(() {});

    QueueUtil.get("kTicketsOnSubmit")?.addTask(() {
      return _backgroudSubmitTickets();
    });
  }

  @override
  void initState() {
    super.initState();

    _category = widget.feedback == true ? "意见反馈" : "客服投诉";

    StorageUtils.getUserTicketsPath(isCrypt: true).then((value) {
      _cryptFilePath = value;
      setState(() {});
    });

    StorageUtils.getUserTicketsPath().then((value) {});
  }

  @override
  void dispose() {
    _contentEditingController.dispose();
    _cleanCacheImages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.feedback == true ? "意见反馈" : "投诉"),
        leading: AppbarBack(),
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
          // 内容
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 18.w, right: 30.w),
              color: const Color(0xFFFFFFFF),
              child: TextField(
                maxLength: _maxContentLength,
                controller: _contentEditingController,
                autofocus: true,
                maxLines: 4,
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 15.sp,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: widget.feedback == true
                      ? "您好，如果您对我们有任何建议，请在此留言。（400汉字以内）"
                      : "",
                  hintStyle: TextStyle(
                    color: kAppConfig.appPlaceholderColor,
                    fontSize: 15.sp,
                  ),
                  border: InputBorder.none,
                ),
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  _checkAviable();
                },
                onSubmitted: (value) {},
                onEditingComplete: () {
                  FocusScope.of(context).requestFocus(FocusNode());
                },
                onTap: () {},
              ),
            ),
          ),
          // 字数
          Container(
            color: const Color(0xFFFFFFFF),
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
          widget.feedback == true
              ? SizedBox(
                  height: 10.w + MediaQuery.of(context).padding.bottom,
                )
              : FileAttachmentPicker(
                  isComplaint: true,
                  attachmentFeedback: (attachments) {
                    _attachmentList = attachments;
                    setState(() {});
                  },
                ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
