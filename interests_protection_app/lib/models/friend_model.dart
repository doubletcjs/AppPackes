import 'dart:convert';

class FriendModel {
  String userId = "";
  String key = "";
  String remark = "";
  String mobile = "";
  String nickname = "";
  String avatar = "";
  String tags = ""; // list json
  int updateState = 1; // 0 更新中 1 更新完成
  int timeout = 0; // 0 更新中 1 更新完成
  String timeoutDate = "";
  int risk = 0;

  FriendModel({
    required this.avatar,
    required this.userId,
    required this.remark,
    required this.mobile,
    required this.nickname,
    required this.tags,
    required this.key,
    required this.updateState,
    required this.timeout,
    required this.timeoutDate,
    required this.risk,
  });

  FriendModel.fromJson(Map<String, dynamic> json)
      : avatar = json["avatar"] ?? "",
        userId = json["id"] != null ? (json["id"] ?? "") : json["userId"] ?? "",
        remark = json["remark"] ?? "",
        mobile = json["mobile"] ?? "",
        nickname = json["nickname"] ?? "",
        key = json["key"] ?? "",
        updateState = json["updateState"] ?? 1,
        risk = json["risk"] ?? 0,
        timeout = json["timeout"] ?? 0,
        tags = jsonEncode((json["tags"] ?? ""));

  Map<String, dynamic> toJson() {
    return {
      "avatar": avatar,
      "key": key,
      "userId": userId,
      "mobile": mobile,
      "nickname": nickname,
      "remark": remark,
      "tags": tags,
      "updateState": updateState,
      "timeout": timeout,
      "timeoutDate": timeoutDate,
      "risk": risk,
    };
  }
}

class FriendApplayModel {
  String userId = "";
  String time = "";
  String nickname = "";
  String avatar = "";
  int applayState = 0; // 0 申请中 1 已同意 2 已拒绝
  String eventId = "";

  FriendApplayModel({
    required this.avatar,
    required this.userId,
    required this.time,
    required this.nickname,
    required this.applayState,
    required this.eventId,
  });

  FriendApplayModel.fromJson(Map<String, dynamic> json)
      : avatar = json["avatar"] ?? "",
        nickname = json["nickname"] ?? "",
        time = json["time"] ?? "",
        userId = json["userId"] ?? "",
        eventId = json["eventId"] ?? "",
        applayState = json["applayState"] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      "avatar": avatar,
      "time": time,
      "userId": userId,
      "nickname": nickname,
      "applayState": applayState,
      "eventId": eventId,
    };
  }
}

class FriendTagModel {
  String id = "";
  String label = "";
  List<FriendModel> friends = [];

  FriendTagModel({
    required this.id,
    required this.label,
    required this.friends,
  });

  FriendTagModel.fromJson(Map<String, dynamic> json)
      : id = json["id"] ?? "",
        label = json["label"] ?? "";

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "label": label,
      "friends": friends,
    };
  }
}
