import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final String _api = kReleaseMode
    ? "https://chat.hw.73zls.com/app"
    : "http://192.168.3.112:8182/app";

class EnvironmentConfig {
  final Color appErrorColor = const Color(0xFFD43030);
  final Color appPlaceholderColor = const Color(0xFFD9D9D9);
  final Color appDisableColor = const Color(0xFFEDD5D5);
  final Color appThemeColor = const Color(0xFFE64646);

  final int appAccountDatabaseVersion = 3;
  final int appAuthDatabaseVersion = 1;
  final String appLanguage = String.fromEnvironment('APP_LANGUAGE');
  final String appRelease = String.fromEnvironment('APP_RELEASE');

  final String openApiUrl = _api + "/news";
  final String apiUrl = _api;

  Map<String, dynamic> apiHeader = {
    "Api-Version": "App1.0",
    "Authorization": "",
  };

  String curvePrivateKey = "";
  String serverSalt = "";
  String assistantNickName = "";
  final String serverCurvePublicKey =
      "339c38be6704b93b3c6ea3fe2f68623796f20894264754d182e85a7a272e0d2e"; // 服务器 curve25519 公钥
  final String assistantCurvePublicKey =
      "e353bbad7ac53f5140ccec80d662f8e1dfb14b7818ccf815f423c56d08d74300"; // 客服 curve25519 公钥
  String avatar(String id) {
    return apiUrl + "/friends/avatar/$id.png";
  }
}
