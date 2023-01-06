import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class FileDownloadClient {
  static Future<dynamic> fileDownload({
    required String requestPath,
    required String saveBinPath,
    required Map<String, dynamic> headers,
    Map<String, dynamic>? params,
    Function(double progress)? progress,
  }) async {
    Completer completer = Completer();

    //额外参数
    Map<String, dynamic> dataMap = {};
    dataMap.addAll(params ?? {});

    //处理请求头
    Map<String, dynamic> _requestHeaders = headers;
    Options _options = Options(headers: _requestHeaders);

    try {
      Response response = await Dio().download(
        requestPath,
        saveBinPath,
        options: _options,
        queryParameters: params,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            ///当前下载的百分比例
            debugPrint("下载进度:${(received / total * 100).toStringAsFixed(0)}%");

            if (progress != null) {
              progress(received / total);
            }
          }
        },
      );

      if (response.statusCode == 401) {
        // token过期
        Get.find<AppHomeController>().logout();
        return;
      } else if (response.statusCode == 200) {
        completer.complete(saveBinPath);
      } else {
        completer.completeError({
          "code": response.statusCode,
          "msg": response.statusMessage,
        });

        utilsToast(msg: response.statusMessage ?? "下载失败");
      }
    } catch (e) {
      debugPrint("Dio().download error:$e");
      completer.completeError(e);
      utilsToast(msg: "$e");
    }

    return completer.future;
  }
}
