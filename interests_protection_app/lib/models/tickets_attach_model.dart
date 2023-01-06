import 'dart:typed_data';

class TicketsAttachModel {
  String path = "";
  String fileName = "";
  String fileSize = "";
  Uint8List encryptData = Uint8List(0);
  String extension = "";
  String fileId = "";
  String salt = "";
  bool isImage = false;

  TicketsAttachModel({
    required this.path,
    required this.fileName,
    required this.fileSize,
    required this.encryptData,
    required this.extension,
    required this.fileId,
    required this.salt,
    required this.isImage,
  });

  TicketsAttachModel.fromJson(Map<String, dynamic> json)
      : path = json["path"] ?? "",
        fileName = json["fileName"] ?? "",
        extension = json["extension"] ?? "",
        fileSize = json["fileSize"] ?? "",
        fileId = json["fileId"] ?? "",
        salt = json["salt"] ?? "",
        isImage = json["isImage"] ?? false,
        encryptData = json["encryptData"] ?? Uint8List(0);

  Map<String, dynamic> toJson() {
    return {
      "path": path,
      "fileName": fileName,
      "fileSize": fileSize,
      "encryptData": encryptData,
      "extension": extension,
      "fileId": fileId,
      "salt": salt,
      "isImage": isImage,
    };
  }
}
