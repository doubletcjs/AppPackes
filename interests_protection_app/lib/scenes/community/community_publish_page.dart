import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/apis/community_api.dart';
import 'package:interests_protection_app/controllers/personal_data_controller.dart';
import 'package:interests_protection_app/networking/file_upload_client.dart';
import 'package:interests_protection_app/scenes/community/widgets/community_image_picker.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/appbar_back.dart';

class CommunityPublishPage extends StatefulWidget {
  const CommunityPublishPage({super.key});

  @override
  State<CommunityPublishPage> createState() => _CommunityPublishPageState();
}

class _CommunityPublishPageState extends State<CommunityPublishPage> {
  final TextEditingController _contentEditingController =
      TextEditingController();
  final FocusNode _contentFocusNode = FocusNode();
  final int _maxContentLength = 400;
  List<File> _imageFileList = [];

  bool _canSubmit = false;
  bool _cleanReset = false;

  // 清空图片缓存
  void _cleanCacheImages() {
    void _action(List<File> images) {
      images.forEach((element) {
        try {
          File(element.path).deleteSync();
        } catch (e) {}
      });
    }

    if (_imageFileList.length > 0) {
      QueueUtil.get("kCommunityCleanImages")?.addTask(() {
        return _action(_imageFileList);
      });
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

  // 提交
  void _onSubmit() async {
    SVProgressHUD.show();

    Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
    Geolocator.getCurrentPosition(
      desiredAccuracy: GetPlatform.isAndroid
          ? LocationAccuracy.high
          : LocationAccuracy.bestForNavigation,
      forceAndroidLocationManager: true,
      timeLimit: Duration(seconds: 10),
    ).then(
      (value) {
        Get.find<PersonalDataController>().localPosition = value;

        String latitude = value.latitude.toStringAsFixed(8);
        String longitude = value.longitude.toStringAsFixed(8);

        if (latitude.length > 0 && longitude.length > 0) {
          Map<String, dynamic> _params = {
            "content": _contentEditingController.text,
            "lat": latitude,
            "lon": longitude,
          };

          void _publish() {
            CommunityApi.post(params: _params).then((value) {
              _contentEditingController.clear();
              _imageFileList.clear();
              _cleanReset = true;
              _canSubmit = false;
              setState(() {
                _cleanCacheImages();
              });

              Future.delayed(Duration(milliseconds: 400), () {
                SVProgressHUD.dismiss();
                _cleanReset = false;
                setState(() {
                  Get.back(result: true);
                });
              });
            }).catchError((error) {
              SVProgressHUD.dismiss();
            });
          }

          if (_imageFileList.length > 0) {
            List<EncryptFileDataModel> _fileList = [];
            _imageFileList.forEach((element) {
              String name = element.path
                  .trim()
                  .substring(element.path.trim().lastIndexOf("/") + 1);
              String extension =
                  name.trim().substring(name.trim().lastIndexOf(".") + 1);

              EncryptFileDataModel _fileDataModel = EncryptFileDataModel(
                fileType: extension,
                fileData: File(element.path).readAsBytesSync(),
                fileId: "${DateTime.now().millisecondsSinceEpoch}",
                fileName: name,
              );

              _fileList.add(_fileDataModel);
            });

            // 上传文件
            FileUploadClient.uploadFile(
              "${kAppConfig.apiUrl}/community/file",
              _fileList,
              key: "file",
            ).then((value) {
              List _images = List.from(value["data"] ?? []);
              _params["images"] = _images;
              _publish();
            }).catchError((error) {
              debugPrint("上传文件失败:$error");
            });
          } else {
            _publish();
          }
        } else {
          utilsToast(msg: "无法获取当前位置,请稍后再试!");
          SVProgressHUD.dismiss();
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();

    _contentFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _contentFocusNode.removeListener(() {});
    _contentFocusNode.dispose();
    _contentEditingController.dispose();
    _cleanCacheImages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("发布内容"),
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
        mainAxisSize: MainAxisSize.max,
        children: [
          // 内容
          Expanded(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(_contentFocusNode);
              },
              onPanUpdate: (details) {
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: Container(
                padding: EdgeInsets.only(left: 18.w, right: 15.w),
                color: const Color(0xFFFFFFFF),
                alignment: Alignment.topCenter,
                child: TextField(
                  maxLength: _maxContentLength,
                  controller: _contentEditingController,
                  focusNode: _contentFocusNode,
                  autofocus: true,
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
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
                  onSubmitted: (value) {},
                  onEditingComplete: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              15.w,
              10.w,
              15.w,
              13.w,
            ),
            child: Row(
              children: [
                Expanded(
                  child: CommunityImagePicker(
                    feedback: (imageFileList) {
                      _imageFileList = imageFileList;
                    },
                    cleanReset: _cleanReset,
                  ),
                ),
                Container(
                  width: 63.w - 15.w,
                  alignment: Alignment.centerRight,
                  child: Text(
                    "${_contentEditingController.text.length}/$_maxContentLength",
                    style: TextStyle(
                      color: kAppConfig.appPlaceholderColor,
                      fontSize: 9.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
              height: (_imageFileList.length > 1 &&
                          _contentFocusNode.hasFocus &&
                          mounted
                      ? (_imageFileList.length < 3
                          ? MediaQuery.of(context).viewInsets.bottom
                          : (MediaQuery.of(context).viewInsets.bottom -
                                      64.w * (_imageFileList.length / 3) <
                                  0
                              ? MediaQuery.of(context).viewInsets.bottom
                              : (MediaQuery.of(context).viewInsets.bottom -
                                  64.w * (_imageFileList.length / 3))))
                      : MediaQuery.of(context).viewInsets.bottom) +
                  MediaQuery.of(context).padding.bottom),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
