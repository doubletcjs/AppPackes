class TicketsDetailModel {
  String category = "";
  String id = "";
  String tag = "";
  String content = "";
  bool receive = false;
  List<TicketsAccessoryModel> accessory = [];
  List<TicketsReplyModel> reply = [];

  TicketsDetailModel({
    required this.category,
    required this.tag,
    required this.content,
    required this.receive,
    required this.accessory,
    required this.reply,
    required this.id,
  });

  TicketsDetailModel.fromJson(Map<String, dynamic> json)
      : content = json["content"] ?? "",
        category = json["category"] ?? "",
        id = json["id"] ?? "",
        receive = json["receive"] ?? "",
        accessory = ((json["accessory"] ?? []) as List).map((element) {
          return TicketsAccessoryModel.fromJson(element);
        }).toList(),
        reply = ((json["reply"] ?? []) as List).map((element) {
          return TicketsReplyModel.fromJson(element);
        }).toList(),
        tag = json["tag"] ?? "";

  Map<String, dynamic> toJson() {
    return {
      "category": category,
      "tag": tag,
      "content": content,
      'receive': receive,
      'accessory': accessory,
      'reply': reply,
      'id': id,
    };
  }
}

class TicketsReplyModel {
  String uid = "";
  String content = "";
  String createdAt = "";

  TicketsReplyModel({
    required this.uid,
    required this.content,
    required this.createdAt,
  });

  TicketsReplyModel.fromJson(Map<String, dynamic> json)
      : uid = json["uid"] ?? "",
        content = json["content"] ?? "",
        createdAt = json["created_at"] ?? "";

  Map<String, dynamic> toJson() {
    return {
      "uid": uid,
      "content": content,
      "createdAt": createdAt,
    };
  }
}

class TicketsAccessoryModel {
  String file = "";
  String salt = "";
  String length = "";
  String name = "";
  int status = 0; // 0 未下载 1 处理中 2 处理完成

  TicketsAccessoryModel({
    required this.file,
    required this.salt,
    required this.length,
    required this.name,
    required this.status,
  });

  TicketsAccessoryModel.fromJson(Map<String, dynamic> json)
      : file = json["file"] ?? "",
        salt = json["salt"] ?? "",
        length = json["length"] ?? "",
        name = json["name"] ?? "",
        status = json["status"] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      "file": file,
      "salt": salt,
      "length": length,
      "name": name,
      "status": status,
    };
  }
}
