class NewsDetailModel {
  String id = "";
  String country = "";
  String cover = "";
  String createdAt = "";
  String origin = "";
  String title = "";

  String author = "";
  String content = "";
  String updatedAt = "";
  bool status = false;

  NewsDetailModel({
    required this.id,
    required this.country,
    required this.cover,
    required this.createdAt,
    required this.origin,
    required this.title,
    required this.author,
    required this.content,
    required this.updatedAt,
    required this.status,
  });

  NewsDetailModel.fromJson(Map<String, dynamic> json)
      : id = json["_id"] ?? "",
        country = json["country"] ?? "",
        cover = json["cover"] ?? "",
        createdAt = json["created_at"] ?? "",
        origin = json["origin"] ?? "",
        author = json["author"] ?? "",
        content = json["content"] ?? "",
        updatedAt = json["updated_at"] ?? "",
        status = json["status"] ?? false,
        title = json["title"] ?? "";

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "country": country,
      "cover": cover,
      "createdAt": createdAt,
      "origin": origin,
      "title": title,
      "author": author,
      "content": content,
      "updatedAt": updatedAt,
      "status": status,
    };
  }
}
