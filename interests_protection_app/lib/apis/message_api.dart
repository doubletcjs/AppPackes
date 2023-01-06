import 'package:interests_protection_app/networking/networking_client.dart';

class MessageApi {
  /// 发送消息
  static Future<dynamic> sendTextMessage(
    bool customer, {
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      customer ? "/message/customer" : "/message",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 获取当前客服
  static Future<dynamic> customerInfo({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "/customer/info",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 上报信息
  /// unread: 已读消息，内容：最后已读的消息 ID
  /// location: 定位，内容：经纬度，用英文,逗号分隔。如：经纬度：113.49220,23.88188
  /// destroy: 删除消息，内容：消息 ID
  static Future<dynamic> report({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/message/report",
      params: params,
      isShowErr: isShowErr,
    );
  }
}
