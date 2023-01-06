import 'package:interests_protection_app/models/friend_model.dart';

class ConversationModel {
  String fromId = "";
  int unread = 0; // 未读消息数
  String lastTime = "";
  String lastContent = "";
  String lastContentId = "";

  FriendModel? friendModel;

  ConversationModel({
    required this.fromId,
    required this.unread,
    required this.lastTime,
    required this.lastContent,
    required this.lastContentId,
    this.friendModel,
  });

  ConversationModel.fromJson(Map<String, dynamic> json)
      : fromId = json["fromId"] ?? "",
        lastTime = json["lastTime"] ?? "",
        lastContent = json["lastContent"] ?? "",
        lastContentId = json["lastContentId"] ?? "",
        unread = json["unread"] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      "fromId": fromId,
      "lastTime": lastTime,
      "lastContent": lastContent,
      "lastContentId": lastContentId,
      "unread": unread,
    };
  }
}
