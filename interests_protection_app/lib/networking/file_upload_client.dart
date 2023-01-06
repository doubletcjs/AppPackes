import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide MultipartFile hide FormData;
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

class EncryptFileDataModel {
  String fileType = "";
  String? fileName;
  Uint8List fileData = Uint8List(0);
  String fileId = "";

  EncryptFileDataModel({
    required this.fileType,
    this.fileName,
    required this.fileData,
    required this.fileId,
  });
}

class FileUploadClient {
  ///上传文件
  static Future<dynamic> uploadFile(
    String path,
    List<EncryptFileDataModel>? fileDatas, {
    Map<String, dynamic>? params,
    Map<String, dynamic>? headers,
    bool isShowErr = true,
    String key = "files",
    Function(double progress)? progress,
  }) async {
    Completer completer = Completer();
    if (fileDatas == null || fileDatas.length == 0) {
      completer.completeError({
        "code": -999,
        "msg": "文件列表不能为空",
      });
    } else {
      //额外参数
      Map<String, dynamic> dataMap = {};
      dataMap.addAll(params ?? {});

      //处理请求头
      Map<String, dynamic> _requestHeaders = kAppConfig.apiHeader;
      _requestHeaders.addAll(headers ?? {});

      Dio dio = new Dio();
      Future<dynamic> _post() async {
        Options _options = Options(
          responseType: ResponseType.json,
          headers: _requestHeaders,
          contentType: "application/json; charset=utf-8",
        );

        //文件数组
        //https://github.com/flutterchina/dio/blob/master/README-ZH.md#formdata
        List<MapEntry<String, MultipartFile>> mFiles = [];
        for (var idx = 0; idx < fileDatas.length; idx++) {
          EncryptFileDataModel model = fileDatas[idx];
          MultipartFile multipartFile = MultipartFile.fromBytes(
            model.fileData,
            filename: (model.fileName ?? "").length > 0
                ? "${model.fileName}"
                : "file_$idx.${model.fileType}",
          );
          mFiles.add(MapEntry(key, multipartFile));
          debugPrint(
              "文件长度:${model.fileData.length} -- ${multipartFile.filename}");
        }

        //封装文件data
        FormData formData = FormData.fromMap(dataMap);
        formData.files.addAll(mFiles);

        return await dio.post(
          "$path",
          data: formData,
          queryParameters: params,
          options: _options,
          onSendProgress: (count, total) {
            if (progress != null) {
              progress(count / total);
            }

            debugPrint("上传进度:${count / total}");
          },
        );
      }

      _post().then((value) {
        if (value.statusCode == 401) {
          // token过期
          Get.find<AppHomeController>().logout();
          return;
        }

        completer.complete(value.data ?? {});
      }).catchError((err) {
        DioError dioError = err;
        debugPrint("dioError:${dioError.response}");

        if (dioError.response!.statusCode == 401) {
          // token过期
          Get.find<AppHomeController>().logout();
        }

        completer.completeError(dioError);
      });
    }

    return completer.future;
  }
}
