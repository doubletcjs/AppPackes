import 'dart:convert';

class AccountModel {
  String avatar = "";
  String country = ""; // 86
  String friendCode = "";
  String mobile = "";
  String nickname = "";
  String friends = ""; // list json
  int level = 0; // 0：普通会员；1：VIP；2：SVIP
  String sex = "";
  String userId = "";
  int rescue = 0;
  int real = 0; // 是否实名
  String emergencyPhone = "";
  String location = "";
  String xpin = "";
  int amount = 0;
  int risk = 0;

  AccountModel({
    required this.avatar,
    required this.country,
    required this.friendCode,
    required this.mobile,
    required this.nickname,
    required this.friends,
    required this.level,
    required this.sex,
    required this.userId,
    required this.rescue,
    required this.real,
    required this.emergencyPhone,
    required this.location,
    required this.xpin,
    required this.amount,
    required this.risk,
  });

  AccountModel.fromJson(Map<String, dynamic> json)
      : avatar = json["avatar"] ?? "",
        country = json["country"] ?? "",
        friendCode = json["friend_code"] ?? "",
        xpin = json["xpin"] ?? "",
        mobile = json["mobile"] ?? "",
        nickname = json["nickname"] ?? "",
        level = json["level"] ?? 0,
        sex = json["sex"] ?? "",
        userId = json["userId"] ?? "",
        rescue = json["rescue"] ?? 0,
        real = json["real"] ?? 0,
        risk = json["risk"] ?? 0,
        amount = json["amount"] ?? 0,
        emergencyPhone = json["emergency_phone"] ?? "",
        location = json["location"] ?? "",
        friends = jsonEncode((json["friends"] ?? ""));

  Map<String, dynamic> toJson() {
    return {
      "avatar": avatar,
      "country": country,
      "friendCode": friendCode,
      "mobile": mobile,
      "nickname": nickname,
      "friends": friends,
      "level": level,
      "sex": sex,
      "userId": userId,
      "rescue": rescue,
      "real": real,
      "emergencyPhone": emergencyPhone,
      "location": location,
      "xpin": xpin,
      "risk": risk,
      "amount": amount,
    };
  }
}
