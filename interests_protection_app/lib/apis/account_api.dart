import 'package:interests_protection_app/networking/networking_client.dart';

class AccountApi {
  /// 获取验证码
  static Future<dynamic> sms({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/user/sms",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 用户注册
  static Future<dynamic> register({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/user/register",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 用户登录
  static Future<dynamic> login({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/user/login",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 退出登录
  static Future<dynamic> logout({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doDelete(
      "/user/logout",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 注销用户
  static Future<dynamic> logoff({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doDelete(
      "/user/logoff",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 更换 PIN 码
  static Future<dynamic> replacePincode({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPut(
      "/user/pin",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 校验 PIN 码
  static Future<dynamic> checkPincode({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/user/pin",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 重置密码
  static Future<dynamic> resetPincode({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPut(
      "/user/reset-pin",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 重置 PIN 码
  static Future<dynamic> resetPassword({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPut(
      "/user/reset-password",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 获取用户信息
  static Future<dynamic> userInfo({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "/user/info",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 修改用户信息
  static Future<dynamic> editUserInfo({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPut(
      "/user/info",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 获取好友信息
  static Future<dynamic> friendsInfo({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "/friends/info",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 重置好友添加码
  static Future<dynamic> resetFriendCode({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPut(
      "/user/reset-friend-code",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 批量获取好友信息
  static Future<dynamic> friendsItems({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/friends/items",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 发起好友申请
  static Future<dynamic> applyFriends({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/friends",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 处理好友申请
  static Future<dynamic> agreeFriends({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPut(
      "/friends",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 删除好友
  static Future<dynamic> friendDelete({
    String? id,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doDelete(
      "/friends?id=$id",
      params: {},
      isShowErr: isShowErr,
    );
  }

  /// 发起紧急救援
  static Future<dynamic> rescueAction({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/rescue",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 实名验证
  static Future<dynamic> real({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/user/real",
      params: params,
      isShowErr: isShowErr,
    );
  }

  /// 上传身份证
  static Future<dynamic> realPhoto({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPost(
      "/user/real-photo",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 修改好友信息
  static Future<dynamic> updateFriendsInfo({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPut(
      "/friends/info",
      params: params,
      isShowErr: isShowErr,
    );
  }

  // 修改密码
  static Future<dynamic> password({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doPut(
      "/user/password",
      params: params,
      isShowErr: isShowErr,
    );
  }
}
