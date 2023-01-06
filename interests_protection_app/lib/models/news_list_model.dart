class NewsListModel {
  String id = "";
  String country = "";
  String cover = "";
  String createdAt = "";
  String origin = "";
  String title = "";

  NewsListModel({
    required this.id,
    required this.country,
    required this.cover,
    required this.createdAt,
    required this.origin,
    required this.title,
  });

  NewsListModel.fromJson(Map<String, dynamic> json)
      : id = json["_id"] ?? "",
        country = json["country"] ?? "",
        cover = json["cover"] ?? "",
        createdAt = json["created_at"] ?? "",
        origin = json["origin"] ?? "",
        title = json["title"] ?? "";

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "country": country,
      "cover": cover,
      "createdAt": createdAt,
      "origin": origin,
      "title": title,
    };
  }
}
