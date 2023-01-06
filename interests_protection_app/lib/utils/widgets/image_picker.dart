import 'dart:async';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

import 'package:path_provider/path_provider.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

class ImagePicker {
  static Future<File> imageCompress(
    File _file, {
    int maxSize = 800, // 宽度
    int quality = 80,
    int rotate = 0,
  }) async {
    Completer<File> _completer = Completer();
    if (_file.readAsBytesSync().length > 1024 * 500 || rotate != 0) {
      debugPrint("压缩前大小:${getFileSize(_file.readAsBytesSync().length)}");
      // 压缩图片
      var imageData = await FlutterImageCompress.compressWithFile(
        _file.path,
        minWidth: maxSize,
        quality: quality,
        rotate: rotate,
        autoCorrectionAngle: false,
      );

      if (imageData != null) {
        debugPrint("压缩后大小:${getFileSize(imageData.length)}");

        if (GetPlatform.isIOS) {
          final compressFile = await File(_file.path).writeAsBytes(imageData);
          _completer.complete(compressFile);
        } else if (GetPlatform.isAndroid) {
          // 安卓移动图片到临时文件夹
          getTemporaryDirectory().then((directory) async {
            var _tempDirectory =
                Directory(directory.path + "/imageTempDirectory");
            if (_tempDirectory.existsSync() == false) {
              _tempDirectory.createSync();
            }

            String filename = _file.path.split("/").last;
            var imagePath = _tempDirectory.path + "/$filename";
            File _tempFile = File(imagePath);
            if (_tempFile.existsSync() == true) {
              _tempFile.deleteSync();
            }
            _tempFile = await _tempFile.writeAsBytes(imageData);
            _completer.complete(_tempFile);
          }).catchError((error) {
            debugPrint("error:$error");
            _completer.complete(_file);
          });
        } else {
          _completer.complete(_file);
        }
      } else {
        _completer.complete(_file);
      }
    } else {
      _completer.complete(_file);
    }

    return _completer.future;
  }

  static Future<List<File>> pick(
    BuildContext context, {
    int count = 9,
    int maxSize = 800, // 宽度
    int quality = 80,
    bool compress = true,
  }) async {
    Completer<List<File>> _completer = Completer();
    List<File> _fileList = [];

    List<AssetEntity> _entityList = await AssetPicker.pickAssets(
          context,
          pickerConfig: AssetPickerConfig(
            maxAssets: count,
            requestType: RequestType.image,
          ),
        ).catchError((error) {}) ??
        [];

    if (_entityList.length > 0) {
      Future.delayed(Duration(milliseconds: 100), () async {
        SVProgressHUD.show();
        for (var i = 0; i < _entityList.length; i++) {
          var element = _entityList[i];
          File? _file = await element.file;
          if (_file != null) {
            if (compress) {
              File _compressFile = await imageCompress(
                _file,
                maxSize: maxSize,
                quality: quality,
              );

              _fileList.add(_compressFile);
            } else {
              _fileList.add(_file);
            }
          }

          if (i == _entityList.length - 1) {
            _completer.complete(_fileList);
            SVProgressHUD.dismiss();
          }
        }
      });
    } else {
      _completer.complete(_fileList);
    }

    return _completer.future;
  }

  static Future<List<File>> openCamera(
    BuildContext context, {
    int maxSize = 800, // 宽度
    int quality = 80,
    bool compress = true,
  }) async {
    Completer<List<File>> _completer = Completer();
    List<File> _fileList = [];

    AssetEntity? _entity = await CameraPicker.pickFromCamera(
      context,
      pickerConfig: CameraPickerConfig(),
    ).catchError((error) {});

    if (_entity != null) {
      File? _file = await _entity.file;
      if (_file != null) {
        if (compress) {
          SVProgressHUD.show();
          File _compressFile = await imageCompress(
            _file,
            maxSize: maxSize,
            quality: quality,
          );

          _fileList.add(_compressFile);
          SVProgressHUD.dismiss();
          _completer.complete(_fileList);
        } else {
          _fileList.add(_file);
          _completer.complete(_fileList);
        }
      } else {
        _completer.complete(_fileList);
      }
    } else {
      _completer.complete(_fileList);
    }

    return _completer.future;
  }

  static void cleanTempDirectory() {
    // 安卓移动图片到临时文件夹
    if (GetPlatform.isAndroid) {
      getTemporaryDirectory().then((directory) {
        var _tempDirectory = Directory(directory.path + "/imageTempDirectory");
        if (_tempDirectory.existsSync()) {
          _tempDirectory.deleteSync(recursive: true);
        }
      }).catchError((error) {});
    }
  }

  static optionDialog(
    BuildContext context,
    int? count,
    void Function(List<File> images)? finish,
  ) {
    void _pickAction(int index) {
      if (index == 1) {
        // 图库库
        ImagePicker.pick(context, count: count ?? 1).then((value) {
          if (finish != null) {
            finish(value);
          }
        });
      } else if (index == 0) {
        // 拍照
        ImagePicker.openCamera(context).then((value) {
          if (finish != null) {
            finish(value);
          }
        });
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
}
