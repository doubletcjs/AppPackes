class ChatRecordModel {
  String fromId = ""; // 对方用户id
  String action = ""; // text file
  String content = "";
  String time = "";
  String eventId = ""; // 我发送的，时间戳标识
  String filename = "";
  String salt = "";
  int isMine = 0; // 我发送的
  // system customer chat
  String eventName = ""; // 我发送的，好友默认 chat 客服 默认 customer
  // 0 未读 1 已读
  int isReaded = 0; // 我发送的，默认1

  int sendState = -1; // 0 发送中 1 发送成功 2 发送失败 3 下载中

  String newEventId = "";
  int decrypt = 0; // 0 旧数据 1 解密失败 2 解密成功
  String encryptSources = "";
  String publicKey = ""; // 解密key

  ChatRecordModel({
    required this.fromId,
    required this.action,
    required this.content,
    required this.time,
    required this.eventId,
    required this.eventName,
    required this.isReaded,
    required this.filename,
    required this.salt,
    required this.isMine,
    required this.sendState,
    required this.newEventId,
    required this.decrypt,
    required this.encryptSources,
    required this.publicKey,
  });

  ChatRecordModel.fromJson(Map<String, dynamic> json)
      : fromId = json["fromId"] != null
            ? (json["fromId"] ?? "")
            : json["from"] ?? "",
        action = json["action"] ?? "",
        content = json["content"] ?? "",
        time = json["time"] ?? "",
        eventId = json["eventId"] ?? "",
        eventName = json["eventName"] ?? "",
        isReaded = json["isReaded"] ?? 0,
        salt = json["salt"] ?? "",
        filename = json["filename"] ?? "",
        newEventId = json["newEventId"] ?? "",
        encryptSources = json["encryptSources"] ?? "",
        sendState = json["sendState"] ?? -1,
        decrypt = json["decrypt"] ?? 0,
        isMine = json["isMine"] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      "fromId": fromId,
      "action": action,
      "content": content,
      "time": time,
      "eventId": eventId,
      "eventName": eventName,
      "isReaded": isReaded,
      "filename": filename,
      "salt": salt,
      "isMine": isMine,
      "sendState": sendState,
      "decrypt": decrypt,
      "encryptSources": encryptSources,
    };
  }
}
