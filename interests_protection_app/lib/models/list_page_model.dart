class ListPageModel {
  int total = 0;
  int count = 0; // 总页数
  int curpage = 0;

  ListPageModel({
    required this.total,
    required this.count,
    required this.curpage,
  });

  ListPageModel.fromJson(Map<String, dynamic> json)
      : total = json["total"] ?? 0,
        count = json["count"] ?? 0,
        curpage = json["curpage"] ?? 0;

  Map<String, dynamic> toJson() {
    return {
      "total": total,
      "count": count,
      "curpage": curpage,
    };
  }
}
