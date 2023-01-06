import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dio/native_imp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svprogresshud/flutter_svprogresshud.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

import 'option_interceptors.dart';
import 'response_interceptor.dart';

// 必须是顶层函数
_parseAndDecode(String response) {
  return jsonDecode(response);
}

_parseJson(String text) {
  return compute(_parseAndDecode, text);
}

class NetworkingClient extends DioForNative {
  //单例
  static NetworkingClient? _instance;
  factory NetworkingClient() => _instance ?? NetworkingClient._init();
  //初始化
  NetworkingClient._init() {
    (transformer as DefaultTransformer).jsonDecodeCallback = _parseJson;
    options = BaseOptions(
      responseType: ResponseType.json,
      connectTimeout: 15000,
    );
    //处理头部
    interceptors.add(OptionInterceptor());
    //处理响应
    interceptors.add(ResponseInterceptor());
  }

  Future<dynamic> doGet<T>(
    String path, {
    bool isShowErr = true,
    Map<String, dynamic>? params,
    Options? options,
    Map<String, dynamic>? headers,
  }) async {
    Response<T> response = await get<T>(
      path,
      queryParameters: params,
      options: options ?? _handleHeader(headers ?? {}),
    );
    return await _handleResponse(response, isShowError: isShowErr);
  }

  Future<dynamic> doDelete<T>(
    String path, {
    bool isShowErr = true,
    dynamic params,
    Map<String, dynamic>? queryParameters,
    Options? options,
    Map<String, dynamic>? headers,
    bool defaultEncrypt = true,
  }) async {
    Response response = await delete<T>(
      path,
      data: defaultEncrypt ? await CryptoUtils.encryptRequest(params) : params,
      queryParameters: queryParameters ?? {},
      options: options ?? _handleHeader(headers ?? {}),
    );
    return await _handleResponse(response, isShowError: isShowErr);
  }

  Future<dynamic> doPost<T>(
    String path, {
    bool isShowErr = true,
    dynamic params,
    Options? options,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    bool defaultEncrypt = true,
  }) async {
    Response response = await post<T>(
      path,
      data: defaultEncrypt ? await CryptoUtils.encryptRequest(params) : params,
      queryParameters: queryParameters ?? {},
      options: options ?? _handleHeader(headers ?? {}),
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return await _handleResponse(response, isShowError: isShowErr);
  }

  Future<dynamic> doPut<T>(
    String path, {
    bool isShowErr = true,
    dynamic params,
    Options? options,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    void Function(int, int)? onSendProgress,
    void Function(int, int)? onReceiveProgress,
    bool defaultEncrypt = true,
  }) async {
    Response response = await put<T>(
      path,
      data: defaultEncrypt ? await CryptoUtils.encryptRequest(params) : params,
      queryParameters: queryParameters ?? {},
      options: options ?? _handleHeader(headers ?? {}),
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
    return await _handleResponse(response, isShowError: isShowErr);
  }

  Future<dynamic> _handleResponse(
    Response? response, {
    bool isShowError = true,
  }) {
    Completer completer = Completer();
    ResponseModel _response = response?.data;

    if (_response.responseType == DioHttpResponseType.succeed) {
      completer.complete(_response.resData ?? {});
    } else {
      if (isShowError) {
        SVProgressHUD.dismiss();

        utilsToast(msg: (_response.resData ?? {})["msg"]);
      }

      debugPrint("api:${response?.realUri}" +
          " -- error:${json.encode(_response.resData ?? {})}");
      completer.completeError(_response.resData ?? {});
    }
    return completer.future;
  }

  Options _handleHeader(Map<String, dynamic>? headers) {
    return Options(
      headers: headers ?? {},
    );
  }
}
