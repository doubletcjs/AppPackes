import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cryptography/cryptography.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart' hide Key;
import 'package:get/get.dart' hide Response;
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

// 系统错误码
int _systemErrorCode = -999;

// 请求回调类型
enum DioHttpResponseType {
  succeed,
  failure,
}

class ResponseModel {
  DioHttpResponseType responseType;
  dynamic resData;
  ResponseModel(this.responseType, this.resData);
}

///拦截器 数据初步处理
class ResponseInterceptor extends InterceptorsWrapper {
  Future<Map> _decryptResponseData(Map data) async {
    Completer<Map> _completer = Completer();

    if (data.containsKey("_")) {
      // 解密数据
      String _str = data["_"];
      String _salt = await CryptoUtils.serverDecryptSalt(
          base64Salt: kAppConfig.serverSalt);

      var cipherText = base64Decode(_str);
      // Choose the cipher
      final algorithm = AesGcm.with128bits();

      // Generate a random secret key.
      String _password = _salt;
      for (var i = 0; i < 16 - _salt.length; i++) {
        _password += "0";
      }

      final secretKey =
          await algorithm.newSecretKeyFromBytes(utf8.encode(_password));

      final secretBox = SecretBox.fromConcatenation(
        cipherText,
        nonceLength: algorithm.nonceLength,
        macLength: algorithm.macAlgorithm.macLength,
      );

      // Decrypt
      final clearText = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );

      final text = utf8.decode(clearText);
      Map _data = Map.from(jsonDecode(text));

      _completer.complete(_data);
    } else {
      _completer.complete(data);
    }

    return _completer.future;
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    dynamic _data = response.data;
    if (response.statusCode == 200) {
      List<int> _bytes = utf8.encode(_data.toString());
      debugPrint(
          "请求成功:${DateTime.now()} -- 接口返回数据长度:${_getPrintSize(_bytes.length)}");
      if (_data is Map) {
        _data = await _decryptResponseData(_data);
        if (_data["code"] == 0) {
          // 成功
          response.data = new ResponseModel(
            DioHttpResponseType.succeed,
            _data["data"] ?? {},
          );
        } else if (_data["code"] == 20101 || _data["code"] == 20100) {
          // token过期
          Get.find<AppHomeController>().logout();
          return;
        } else {
          // 失败
          response.data = new ResponseModel(
            DioHttpResponseType.failure,
            {
              "msg": _data["msg"],
              "code": _data["code"],
            },
          );
        }
      } else {
        response.data = new ResponseModel(
          DioHttpResponseType.succeed,
          _data,
        );
      }
    } else {
      if (response.statusCode == 401) {
        // token过期
        Get.find<AppHomeController>().logout();
        return;
      }

      debugPrint("请求失败:${DateTime.now()} -- 返回数据:$_data");
      if (_data is Map) {
        _data = await _decryptResponseData(_data);
        response.data = new ResponseModel(
          DioHttpResponseType.failure,
          _data["data"] ?? {},
        );
      } else {
        response.data = new ResponseModel(
          DioHttpResponseType.failure,
          {
            "msg": "$_data",
            "code": _systemErrorCode,
          },
        );
      }
    }

    super.onResponse(response, handler);
  }

  String _getPrintSize(limit, {int byte = 3}) {
    try {
      String size = "";
      //内存转换
      if (limit == 0) {
        return "-";
      } else if (limit < 1 * 1024) {
        //小于1KB，则转化成B
        size = "$limit";
        int length = size.indexOf(".") + byte;
        if (length > size.length) {
          length = size.length;
        }
        size = size.substring(0, length) + "B";
      } else if (limit < 1 * 1024 * 1024) {
        //小于1MB，则转化成KB
        size = "${limit / 1024}";
        int length = size.indexOf(".") + byte;
        if (length > size.length) {
          length = size.length;
        }
        size = size.substring(0, length) + "KB";
      } else if (limit < 0.1 * 1024 * 1024 * 1024) {
        //小于0.1GB，则转化成MB
        size = "${limit / (1024 * 1024)}";
        int length = size.indexOf(".") + byte;
        if (length > size.length) {
          length = size.length;
        }
        size = size.substring(0, length) + "MB";
      } else {
        //其他转化成GB
        size = "${limit / (1024 * 1024 * 1024)}".toString();
        int length = size.indexOf(".") + byte;
        if (length > size.length) {
          length = size.length;
        }
        size = size.substring(0, length) + "GB";
      }

      return size;
    } catch (e) {
      return "-";
    }
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    Response response = Response(
      requestOptions: RequestOptions(
        method: err.requestOptions.method,
        path: err.requestOptions.baseUrl + err.requestOptions.path,
      ),
    );

    if (err.type == DioErrorType.connectTimeout ||
        err.type == DioErrorType.receiveTimeout ||
        err.type == DioErrorType.sendTimeout) {
      response.data = new ResponseModel(
        DioHttpResponseType.failure,
        {
          "msg": "请求超时，请重新请求",
          "code": _systemErrorCode,
        },
      );
    } else {
      if (err.response != null) {
        if (err.response!.statusCode == 401) {
          // token过期
          Get.find<AppHomeController>().logout();
          return;
        }

        var data = err.response!.data;
        if (data != null && data is Map) {
          response.data = new ResponseModel(
            DioHttpResponseType.failure,
            {
              "msg": data["msg"],
              "code": data["code"],
            },
          );
        } else {
          response.data = new ResponseModel(
            DioHttpResponseType.failure,
            {
              "msg": "${err.message}",
              "code": _systemErrorCode,
            },
          );
        }
      } else {
        var result = await Connectivity().checkConnectivity();
        if (result == ConnectivityResult.none) {
          response.data = new ResponseModel(
            DioHttpResponseType.failure,
            {
              "msg": "未连接网络",
              "code": -998,
            },
          );
        } else {
          response.data = new ResponseModel(
            DioHttpResponseType.failure,
            {
              "msg": "${err.message}",
              "code": _systemErrorCode,
            },
          );
        }
      }
    }
    handler.resolve(response);
  }
}
