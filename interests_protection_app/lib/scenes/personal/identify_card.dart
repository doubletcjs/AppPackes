import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/utils/widgets/image_picker.dart';

class IdentifyCard extends StatefulWidget {
  final bool? background;
  final void Function(String path)? feedback;
  const IdentifyCard({
    super.key,
    required this.feedback,
    this.background,
  });

  @override
  State<IdentifyCard> createState() => _IdentifyCardState();
}

class _IdentifyCardState extends State<IdentifyCard> {
  late CameraController? _cameraController;

  // 错误弹框
  void _showCameraException(CameraException e) {
    utilsToast(msg: "Error: ${e.code}\n${e.description}");
  }

  // 初始化
  void _onNewCameraSelected(CameraDescription cameraDescription) async {
    if (_cameraController != null) {
      await _cameraController?.dispose();
    }
    _cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);

    // If the controller is updated then update the UI.
    _cameraController?.addListener(() {
      if (mounted) setState(() {});
      if (_cameraController!.value.hasError) {
        utilsToast(msg: "${_cameraController?.value.errorDescription}");
      }
    });

    try {
      await _cameraController?.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  // 拍照按钮
  void _onTakePictureButtonPressed() {
    void _takePicture(void Function(File? file) feedback) async {
      if (!_cameraController!.value.isInitialized) {
        utilsToast(msg: "未开启摄像头");
        return null;
      }

      if (_cameraController!.value.isTakingPicture) {
        return null;
      }

      try {
        XFile file = await _cameraController!.takePicture();
        var compressFile =
            await ImagePicker.imageCompress(File(file.path), rotate: -90);
        feedback(compressFile);
      } on CameraException catch (e) {
        _showCameraException(e);
        return null;
      }
    }

    _takePicture((file) {
      if (mounted) {
        if (widget.feedback != null && file != null) {
          widget.feedback!(file.path);
        }
      }
    });
  }

  Widget _takePictureLayout() {
    return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          color: Colors.blueAccent,
          alignment: Alignment.center,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: IconButton(
            iconSize: 50.w,
            onPressed: _cameraController != null &&
                    _cameraController!.value.isInitialized &&
                    !_cameraController!.value.isRecordingVideo
                ? _onTakePictureButtonPressed
                : null,
            icon: Icon(
              Icons.photo_camera,
              color: Colors.white,
            ),
          ),
        ));
  }

  // 身份证背景框
  Widget _cameraFloatImage() {
    return Positioned(
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.fromLTRB(50.w, 50.w, 50.w, 50.w),
        child: Image.asset((widget.background ?? false)
            ? 'images/bg_identify_idcard.png'
            : 'images/fg_identify_idcard.png'),
      ),
    );
  }

  // 相机视图
  Widget _cameraPreviewWidget() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return SizedBox();
    } else {
      return Container(
        child: AspectRatio(
          aspectRatio: (MediaQuery.of(context).size.width -
                  MediaQuery.of(context).padding.bottom) /
              (MediaQuery.of(context).size.height * (3 / 4) -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom),
          child: CameraPreview(_cameraController!),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _cameraController = null;
    try {
      availableCameras().then((value) {
        if (value.length > 0) {
          _onNewCameraSelected(value[0]); // 后置摄像头
        } else {
          utilsToast(msg: "未开启摄像头");
        }
      });
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                Expanded(
                  flex: 3, //flex用来设置当前可用空间的占优比
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _cameraPreviewWidget(), //相机视图
                      _cameraFloatImage(), //悬浮的身份证框图
                    ],
                  ),
                ),
                Expanded(
                  flex: 1, //flex用来设置当前可用空间的占优比
                  child: _takePictureLayout(), //拍照操作区域布局
                ),
              ],
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top,
              right: 5.w,
              child: MaterialButton(
                onPressed: () {
                  Get.back();
                },
                minWidth: 44.w,
                height: 44.w,
                padding: EdgeInsets.zero,
                child: Center(
                  child: Image.asset(
                    "images/scan_close@2x.png",
                    width: 24.w,
                    height: 24.w,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
