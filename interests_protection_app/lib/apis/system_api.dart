import 'package:interests_protection_app/networking/networking_client.dart';

class SystemApi {
  /// App 最新版本
  static Future<dynamic> version({
    Map<String, dynamic>? params,
    bool isShowErr = true,
  }) async {
    return await NetworkingClient().doGet(
      "/other/version",
      params: params,
      isShowErr: isShowErr,
    );
  }
}
