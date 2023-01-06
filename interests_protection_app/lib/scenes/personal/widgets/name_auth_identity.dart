import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:interests_protection_app/apis/account_api.dart';
import 'package:interests_protection_app/scenes/personal/identify_card.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/alert_veiw.dart';
import 'package:interests_protection_app/utils/widgets/image_picker.dart';

class NameAuthIdentity extends StatefulWidget {
  final void Function(bool fill)? fillFeedback;
  final void Function()? nextStepAction;
  const NameAuthIdentity({
    Key? key,
    required this.fillFeedback,
    required this.nextStepAction,
  }) : super(key: key);

  @override
  State<NameAuthIdentity> createState() => _NameAuthIdentityState();
}

class _NameAuthIdentityState extends State<NameAuthIdentity> {
  bool _identityFill = false;
  String _foreground = "";
  String _background = "";
  Directory? _tempDirectory;

  List<String> _identityTipList = [
    "标准拍摄",
    "边框缺失",
    "照片模糊",
    "闪光强烈",
  ];
  List<String> _identityTipIconList = [
    "images/identity_tip1@2x.png",
    "images/identity_tip2@2x.png",
    "images/identity_tip3@2x.png",
    "images/identity_tip4@2x.png",
  ];

  // 上传身份证
  void _selectIdentityImage(int identityIndex) {
    FocusScope.of(context).requestFocus(FocusNode());

    // 图片处理
    void _handleAssetFile(String path) async {
      if (path.length == 0) {
        return;
      }

      bool _rotate = false;
      Future<File> _rotationImageFile(String imagePath) async {
        Completer<File> _completer = Completer();
        final originalFile = File(path);
        final originalImage = Image.file(originalFile);
        // 预先获取图片信息
        originalImage.image.resolve(ImageConfiguration()).addListener(
          ImageStreamListener((ImageInfo info, bool _) async {
            final height = info.image.height;
            final width = info.image.width;

            if (height > width) {
              _rotate = true;
              var compressFile = await ImagePicker.imageCompress(
                originalFile,
                rotate: -90,
                maxSize: width.toInt(),
              );
              _completer.complete(compressFile);
            } else {
              _completer.complete(originalFile);
            }
          }),
        );

        return _completer.future;
      }

      String _sourcePath = (await _rotationImageFile(path)).path;
      ImageCropper().cropImage(
        sourcePath: _sourcePath,
        aspectRatio: CropAspectRatio(ratioX: 158, ratioY: 100),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Cropper',
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Cropper',
            rectHeight: 100,
            rectWidth: 158,
            aspectRatioPickerButtonHidden: true,
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            rotateButtonsHidden: !_rotate,
          ),
        ],
      ).then((value) async {
        try {
          File(_sourcePath).deleteSync();
        } catch (e) {}

        if (value != null) {
          SVProgressHUD.show();
          List<int> _imageData = File(value.path).readAsBytesSync();
          String _imageBase64 = base64Encode(_imageData);
          if (identityIndex == 0) {
            _foreground = _imageBase64;
          } else {
            _background = _imageBase64;
          }
          setState(() {});

          Future.delayed(Duration(milliseconds: 300), () {
            SVProgressHUD.dismiss();

            if (_foreground.length > 0 && _background.length > 0) {
              _identityFill = true;
              setState(() {});

              if (widget.fillFeedback != null) {
                widget.fillFeedback!(_identityFill);
              }
            }
          });
        }
      }).catchError((error) {
        try {
          File(_sourcePath).deleteSync();
        } catch (e) {}
      });
    }

    void _pickAction(int index) {
      if (index == 1) {
        // 图库库
        ImagePicker.pick(context, count: 1).then((value) {
          if (value.length > 0) {
            _handleAssetFile(value.first.path);
          }
        });
      } else if (index == 0) {
        // 拍照
        Get.to(
          IdentifyCard(
            background: identityIndex == 1,
            feedback: (path) {
              _handleAssetFile(path);
            },
          ),
          transition: Transition.downToUp,
          popGesture: false,
          fullscreenDialog: true,
        );
      }
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
                _pickAction(0);
              },
            ),
            CupertinoActionSheetAction(
              child: const Text("从手机相册选择"),
              onPressed: () {
                Navigator.pop(context);
                _pickAction(1);
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
  void dispose() {
    if (_tempDirectory != null) {
      if (_tempDirectory!.existsSync()) {
        _tempDirectory!.deleteSync(recursive: true);
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w, 14.w),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            border: Border(
              bottom: BorderSide(
                width: 6.w,
                color: const Color(0xFFFAFAFA),
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.w),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _foreground.length > 0
                                ? Image.memory(
                                    base64Decode(_foreground),
                                    width: 164.w,
                                    height: 99.w,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    "images/identity_foreground@2x.png",
                                    width: 164.w,
                                    height: 99.w,
                                  ),
                            MaterialButton(
                              onPressed: () {
                                _selectIdentityImage(0);
                              },
                              minWidth: 164.w,
                              height: 99.w,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      _foreground.length > 0
                          ? Positioned(
                              right: 6.w,
                              bottom: 5.w,
                              child: Image.asset(
                                "images/identity_edit@2x.png",
                                width: 19.w,
                                height: 19.w,
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.w),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            _background.length > 0
                                ? Image.memory(
                                    base64Decode(_background),
                                    width: 164.w,
                                    height: 99.w,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    "images/identity_background@2x.png",
                                    width: 164.w,
                                    height: 99.w,
                                  ),
                            MaterialButton(
                              onPressed: () {
                                _selectIdentityImage(1);
                              },
                              minWidth: 164.w,
                              height: 99.w,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      _background.length > 0
                          ? Positioned(
                              right: 6.w,
                              bottom: 5.w,
                              child: Image.asset(
                                "images/identity_edit@2x.png",
                                width: 19.w,
                                height: 19.w,
                              ),
                            )
                          : SizedBox(),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 14.w),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 6.w),
                    child: Image.asset(
                      "images/identity_tip@2x.png",
                      width: 10.w,
                      height: 10.w,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      "证件必须是清晰彩色原件电子版本。可以是扫描件或者数码拍摄照片。仅支持jpg、png、jpeg的图片格式。",
                      style: TextStyle(
                        color: const Color(0xFFB3B3B3),
                        fontSize: 10.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(15.w, 12.w, 15.w, 0),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "身份证拍摄示例",
                style: TextStyle(
                  color: const Color(0xFF000000),
                  fontSize: 12.sp,
                ),
              ),
              SizedBox(height: 13.w),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                    List.generate(_identityTipList.length, (index) => index)
                        .map((index) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.asset(
                        _identityTipIconList[index],
                        width: 80.w,
                        height: 60.w,
                      ),
                      SizedBox(height: 7.w),
                      Text(
                        "${_identityTipList[index]}",
                        style: TextStyle(
                          color: const Color(0xFF000000),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
              SizedBox(height: 44.w),
              Container(
                height: 48.w,
                decoration: BoxDecoration(
                  color: _identityFill
                      ? kAppConfig.appThemeColor
                      : const Color(0xFFEDD5D5),
                  borderRadius: BorderRadius.circular(40.w),
                ),
                margin: EdgeInsets.only(left: 39.w, right: 39.w),
                child: Row(
                  children: [
                    Expanded(
                      child: MaterialButton(
                        onPressed: _identityFill
                            ? () {
                                SVProgressHUD.show();
                                AccountApi.realPhoto(
                                  params: {
                                    "front":
                                        "data:image/png;base64," + _foreground,
                                    "back":
                                        "data:image/png;base64," + _background,
                                  },
                                  isShowErr: false,
                                ).then((value) {
                                  SVProgressHUD.dismiss();

                                  if (widget.nextStepAction != null) {
                                    widget.nextStepAction!();
                                  }
                                }).catchError((error) {
                                  _identityFill = false;
                                  _foreground = "";
                                  _background = "";
                                  setState(() {});

                                  if (widget.fillFeedback != null) {
                                    widget.fillFeedback!(_identityFill);
                                  }

                                  SVProgressHUD.dismiss();

                                  AlertVeiw.show(
                                    context,
                                    confirmText: "确认",
                                    contentText: "",
                                    contentWidget: Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        31.w,
                                        36.w,
                                        25.w,
                                        26.w,
                                      ),
                                      child: Text(
                                        "请按照身份证拍摄示例，上传有效身份证的正反面。",
                                        style: TextStyle(
                                          fontSize: 15.sp,
                                          color: const Color(0xFF000000),
                                          height: 1.5,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  );
                                });
                              }
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(40.w),
                        ),
                        height: 48.w,
                        child: Text(
                          "下一步",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFFFFFFF),
                            fontSize: 18.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
