class TicketsListModel {
  String id = "";
  String category = "";
  String tag = "";
  String content = "";
  bool unread = false;

  TicketsListModel({
    required this.id,
    required this.category,
    required this.tag,
    required this.content,
    required this.unread,
  });

  TicketsListModel.fromJson(Map<String, dynamic> json)
      : id = json["_id"] ?? "",
        content = json["content"] ?? "",
        category = json["category"] ?? "",
        unread = json["unread"] ?? false,
        tag = json["tag"] ?? "";

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "category": category,
      "tag": tag,
      "content": content,
      "unread": unread,
    };
  }
}
