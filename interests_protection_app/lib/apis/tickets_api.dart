import 'package:interests_protection_app/networking/networking_client.dart';

class TicketsApi {
  /// 获取工单分类
  static Future<dynamic> category({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "/tickets/category",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 提交工单
  static Future<dynamic> tickets({
    dynamic params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/tickets",
      params: params,
      isShowErr: isShowErr,
      defaultEncrypt: false,
    );
  }

  /// 工单列表
  static Future<dynamic> getTickets({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "/tickets",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 移除工单
  static Future<dynamic> ticketsDelete({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doDelete(
      "/tickets",
      queryParameters: params,
      isShowErr: isShowErr,
      defaultEncrypt: false,
    );
  }

  /// 回复工单
  static Future<dynamic> ticketsReply({
    dynamic params,
    Map<String, dynamic>? queryParameters,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/tickets/reply",
      params: params,
      queryParameters: queryParameters ?? {},
      isShowErr: isShowErr,
      defaultEncrypt: false,
    );
  }
}
