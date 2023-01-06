import 'package:interests_protection_app/networking/networking_client.dart';

class CommunityApi {
  /// 社区列表
  static Future<dynamic> index({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "/community/index",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 我的贴子
  static Future<dynamic> meIndex({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "/community/me",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 更换点赞状态
  static Future<dynamic> like({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPut(
      "/community/like",
      queryParameters: params,
      isShowErr: isShowErr,
    );
  }

  /// 发表帖子
  static Future<dynamic> post({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/community/index",
      params: params,
      isShowErr: isShowErr,
    );
  }
}
