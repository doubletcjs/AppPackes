class CommunityModel {
  String id = "";
  String content = "";
  String mid = ""; // 用户id
  String createdAt = "";
  num distance = 0; // 多少公里以内
  int like = 0;
  bool isLike = false;
  List<String> images = [];
  List<String> replys = [];
  CommunityUserModel user = CommunityUserModel.fromJson({});

  CommunityModel({
    required this.id,
    required this.content,
    required this.mid,
    required this.createdAt,
    required this.distance,
    required this.like,
    required this.isLike,
    required this.images,
    required this.replys,
    required this.user,
  });

  CommunityModel.fromJson(Map<String, dynamic> json)
      : id = json["_id"] ?? "",
        content = json["content"] ?? "",
        mid = json["mid"] ?? "",
        createdAt = json["created_at"] ?? "",
        distance = json["distance"] ?? 0,
        images = List<String>.from(json["images"] ?? []),
        replys = List<String>.from(json["replys"] ?? []),
        isLike = json["is_like"] ?? false,
        user = CommunityUserModel.fromJson(json["user"] ?? {}),
        like = json["like"] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "content": content,
      "mid": mid,
      "createdAt": createdAt,
      "distance": distance,
      "like": like,
      "isLike": isLike,
    };
  }
}

class CommunityUserModel {
  String avatar = "";
  String nickname = "";

  CommunityUserModel({
    required this.avatar,
    required this.nickname,
  });

  CommunityUserModel.fromJson(Map<String, dynamic> json)
      : avatar = json["avatar_url"] ?? "",
        nickname = json["nickname"] ?? "";

  Map<String, dynamic> toJson() {
    return {
      "avatar": avatar,
      "nickname": nickname,
    };
  }
}
