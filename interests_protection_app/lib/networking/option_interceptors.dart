//Option拦截器可以用来统一处理Option信息 可以在这里添加
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class OptionInterceptor extends InterceptorsWrapper {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    // host
    if (!options.path.startsWith("http")) {
      options.baseUrl = kAppConfig.apiUrl;
    }

    if (kAppConfig.apiHeader.length > 0) {
      options.headers.addAll(kAppConfig.apiHeader);
    }

    debugPrint("url: ${options.uri}");
    debugPrint("method: ${options.method}");
    debugPrint("headers: ${options.headers}");

    if (options.queryParameters.length > 0) {
      debugPrint(
          "date:${DateTime.now()} -- queryParameters: ${options.queryParameters}");
    }

    if (options.data != null) {
      debugPrint("body: ${options.data}");
    }

    super.onRequest(options, handler);
  }
}
