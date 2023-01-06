import 'package:interests_protection_app/networking/networking_client.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class NewsApi {
  /// 新闻列表
  static Future<dynamic> index({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "${kAppConfig.openApiUrl}/index",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 当前国家新闻
  static Future<dynamic> location({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "${kAppConfig.openApiUrl}/location",
      params: params,
      isShowErr: isShowErr,
    );
  }
}
