class MessageModel {
  String fromId = "";
  String action = "";
  String content = "";
  String time = "";
  String eventId = "";
  // system customer chat
  String eventName = "";
  // 0 未读 1 已读
  int isReaded = 0;

  MessageModel({
    required this.fromId,
    required this.action,
    required this.content,
    required this.time,
    required this.eventId,
    required this.eventName,
    required this.isReaded,
  });

  MessageModel.fromJson(Map<String, dynamic> json)
      : fromId = json["fromId"] != null
            ? (json["fromId"] ?? "")
            : json["from"] ?? "",
        action = json["action"] ?? "",
        content = json["content"] ?? "",
        time = json["time"] ?? "",
        eventId = json["eventId"] ?? "",
        eventName = json["eventName"] ?? "",
        isReaded = json["isReaded"] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      "fromId": fromId,
      "action": action,
      "content": content,
      "time": time,
      "eventId": eventId,
      "eventName": eventName,
      "isReaded": isReaded,
    };
  }
}
