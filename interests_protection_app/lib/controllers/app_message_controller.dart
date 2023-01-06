import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';
import 'package:interests_protection_app/models/chat_record_model.dart';
import 'package:interests_protection_app/networking/file_download_client.dart';
import 'package:interests_protection_app/networking/file_upload_client.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class AppMessageController extends GetxController {
  // 解密附件文件
  static Future<bool> ticketsDecryptFile(Map<String, dynamic> params) async {
    String filePath = params["filePath"];
    String password = params["password"];
    String localFilePath = params["localFilePath"];

    Completer<bool> completer = Completer();
    debugPrint("开始解密附件");

    Uint8List _fileData =
        await CryptoUtils.decryptFile(filePath: filePath, password: password);

    if (_fileData.length > 0) {
      await File(localFilePath).writeAsBytes(_fileData);
      // 删除解密源文件
      await File(filePath).delete();
      debugPrint("附件解密结束");
      completer.complete(true);
    } else {
      debugPrint("附件解密失败");
      completer.complete(false);
    }

    return completer.future;
  }

  // 后台发送文件消息
  static Future<void> backgroudSendFileMessage(
      Map<String, dynamic> params) async {
    List<ChatRecordModel> _messageList = params["message"];
    // 本人发送文件缓存目录
    String _rootPath = params["rootPath"];

    List<Map> _fileStatusRecord = [];
    Future<Map> _encryptUploadFile(ChatRecordModel element) async {
      debugPrint("开始任务: ${element.eventId}");
      Completer<Map> _completer = Completer();
      // 文件路径
      String _filePath = _rootPath + "/${element.content}";
      Uint8List _fileData = File(_filePath).readAsBytesSync();
      EncryptFileDataModel _uploadModel = EncryptFileDataModel(
        fileType: "",
        fileName: element.filename,
        fileData: _fileData,
        fileId: "",
      );

      Map<String, dynamic> _params = Map<String, dynamic>.from(params);
      _params["fileDataModel"] = _uploadModel;
      _params["message"] = null;
      _params["rootPath"] = null;

      // 加密文件
      compute(encryptFile, _params).then((uploadParams) async {
        if (element.fromId.length > 0) {
          uploadParams["to"] = element.fromId;
        }

        // 上传文件
        FileUploadClient.uploadFile(
          element.fromId.length == 0
              ? "${kAppConfig.apiUrl}/file/customer"
              : "${kAppConfig.apiUrl}/file/message",
          [uploadParams["file"]],
          key: "file",
          params: {"salt": uploadParams["salt"], "to": uploadParams["to"]},
        ).then((value) {
          Map data = ((value ?? {})["data"]) ?? {};
          String _newEventId = data.values.length == 0 ? "" : data.values.first;
          if (_newEventId.length == 0) {
            debugPrint("上传文件失败:${element.eventId}");
            _completer.complete({
              "error": true,
              "eventId": element.eventId,
              "fromId": element.fromId,
              "newEventId": ""
            });
          } else {
            _completer.complete({
              "error": false,
              "eventId": element.eventId,
              "fromId": element.fromId,
              "newEventId": _newEventId,
            });
          }
        }).catchError((error) {
          debugPrint("error:$error");
          debugPrint("上传文件失败:${element.eventId}");
          _completer.complete({
            "error": true,
            "eventId": element.eventId,
            "fromId": element.fromId,
            "newEventId": ""
          });
        });
      }).catchError((error) {
        debugPrint("error 111:$error");
        debugPrint("加密文件失败:${element.eventId}");
        _completer.complete({
          "error": true,
          "eventId": element.eventId,
          "fromId": element.fromId,
          "newEventId": ""
        });
      });

      return _completer.future;
    }

    // 更新状态、记录入库
    void _updateRecord(
      bool error,
      String eventId,
      String fromId,
      String newEventId,
    ) {
      AppMessageController.updateMessageState(
        sendState: error == true ? 2 : 1,
        eventId: eventId,
        fromId: fromId,
        newEventId: newEventId,
      );
      debugPrint("任务结束: $eventId");
    }

    /// 将任务添加到队列
    for (var i = 0; i < _messageList.length; i++) {
      ChatRecordModel element = _messageList[i];
      await Future.delayed(Duration(milliseconds: i == 0 ? 0 : 100));
      QueueUtil.get("chat_${element.eventId}")?.addTask(() {
        return _encryptUploadFile(element).then((value) {
          _fileStatusRecord.add(value);
          _updateRecord(value["error"], value["eventId"], value["fromId"],
              value["newEventId"]);

          if (_fileStatusRecord.length == _messageList.length) {
            debugPrint("批量发送消息文件结束");
            _fileStatusRecord.clear();
            _messageList.clear();
            params.clear();
          }
        });
      });
    }
  }

  // 更新消息状态
  static void updateMessageState({
    required int sendState,
    required String eventId,
    required String fromId,
    required String newEventId,
  }) {
    AppHomeController _homeController = Get.find<AppHomeController>();
    if (_homeController.accountDB != null) {
      ChatRecordModel _model = ChatRecordModel.fromJson({})
        ..eventId = eventId
        ..fromId = fromId
        ..sendState = sendState;

      // 数据库更新状态
      Map<String, Object?> _values = {"sendState": sendState};
      if (newEventId.length > 0) {
        _values["eventId"] = newEventId;
        _model.newEventId = newEventId;
      }

      String _eventName = fromId.length == 0 ? "customer" : "chat";
      _homeController.accountDB!.update(
        kAppChatRecordTableName,
        _values,
        where: fromId.length == 0
            ? "eventName = '$_eventName' AND eventId = '$eventId'"
            : "eventName = '$_eventName' AND eventId = '$eventId' AND fromId = '$fromId'",
      );

      _homeController.chatHandler.add({
        StreamActionType.sendChat: _model,
      });
    }
  }

  // 聊天下载文件
  static Future<List> chatDecryptFile(Map<String, dynamic> params) async {
    Completer<List> _completer = Completer();

    kAppConfig = params["config"];
    kCryptoKeyConfig = params["config"];
    String requestPath = params["requestPath"];
    Map<String, dynamic> headers = kAppConfig.apiHeader;
    String eventId = params["eventId"];
    String fromId = params["fromId"];
    String downloadPath = params["downloadPath"];

    String localFilePath = downloadPath + "/${'$requestPath'}";
    if (File(localFilePath).existsSync()) {
      // 读取本地文件
      _completer.complete([eventId, fromId]);
    } else {
      // 下载文件
      String saveBinPath = downloadPath + "/${'$requestPath'}.bin";
      String publicKey = params["publicKey"];
      String salt = params["salt"];
      String downloadUrl = kAppConfig.apiUrl + "/file/message/";

      FileDownloadClient.fileDownload(
        requestPath: downloadUrl + requestPath,
        saveBinPath: saveBinPath,
        headers: headers,
      ).then((value) async {
        // 解密文件
        String _salt = await CryptoUtils.decryptSalt(base64Salt: salt);
        String _password =
            await CryptoUtils.encryptionKey(publicKey, salt: _salt);

        Uint8List _fileData =
            await CryptoUtils.decryptFile(filePath: value, password: _password);

        if (_fileData.length > 0) {
          await File(localFilePath).writeAsBytes(_fileData);
          // 删除解密源文件
          await File(value).delete();
          _completer.complete([eventId, fromId]);
        } else {
          _completer.complete([eventId, fromId]);
        }
      }).catchError((error) {
        debugPrint("FileDownloadClient.fileDownload error:$error");
        _completer.completeError([eventId, fromId]);
      });
    }

    return _completer.future;
  }

// 加密多文件 publicKey 好友、客服curve25519 公钥
  static Future<Map<String, dynamic>> encryptFileList(
      Map<String, dynamic> params) {
    Completer<Map<String, dynamic>> _completer = Completer();

    List<EncryptFileDataModel> fileList = params["fileList"];
    String cryptFilePath = params["cryptFilePath"];
    kCryptoKeyConfig = params["config"];
    kAppConfig = params["config"];
    String publicKey = kAppConfig.serverCurvePublicKey;

    if (fileList.length == 0 || publicKey.length == 0) {
      _completer.complete({});
      return _completer.future;
    }

    String salt = generateRandomString(10);
    // 用户curve25519 私钥解密服务器salt，再生成共享密钥
    CryptoUtils.serverEncryptionKey().then((encryptionKey) {
      // 使用共享密钥加密随机数salt
      CryptoUtils.encryptText(
        publicKey: publicKey,
        text: salt,
        encryptionKey: encryptionKey,
      ).then((encryptSalt) {
        // 服务器公钥加salt，头尾填充，生成共享密钥
        String sharedKey = publicKey;
        // 关键数
        String keyValue = salt.split("").firstWhere((element) {
          return int.tryParse(element) != null;
        }, orElse: () {
          return "";
        });

        String newKey = "";
        if (keyValue.length > 0) {
          int baseKeyLength = int.tryParse(keyValue)!;

          // 基础密钥
          String baseKey = salt.substring(0, baseKeyLength);
          String baseKeyHex = bytesToHex(utf8.encode(baseKey));
          if (baseKeyLength % 2 == 0) {
            // 偶数 从头部填充
            newKey =
                sharedKey.substring(0, sharedKey.length - baseKeyHex.length) +
                    baseKeyHex;
          } else {
            // 奇数 从尾部填充
            newKey = baseKeyHex +
                sharedKey.substring(baseKeyHex.length, sharedKey.length);
          }
        } else {
          newKey = sharedKey;
        }

        List<EncryptFileDataModel> encryptFileList = [];
        List<EncryptFileDataModel> failureEncryptFileList = [];
        for (var i = 0; i < fileList.length; i++) {
          EncryptFileDataModel fileDataModel = fileList[i];
          QueueUtil.get("encryptFile_${fileDataModel.fileId}_$i")?.addTask(() {
            return CryptoUtils.encryptFile(
              fileData: fileDataModel.fileData,
              password: newKey,
              fileName: fileDataModel.fileName ?? "",
              cryptFilePath: cryptFilePath,
            ).then((encryptFileData) {
              if (encryptFileData.length == 0) {
                failureEncryptFileList.add(EncryptFileDataModel(
                  fileType: fileDataModel.fileType,
                  fileData: encryptFileData,
                  fileName: fileDataModel.fileName,
                  fileId: fileDataModel.fileId,
                ));
              } else {
                encryptFileList.add(EncryptFileDataModel(
                  fileType: fileDataModel.fileType,
                  fileData: encryptFileData,
                  fileName: fileDataModel.fileName,
                  fileId: fileDataModel.fileId,
                ));
              }

              if (i == fileList.length - 1) {
                Map<String, dynamic> params = {
                  "files": encryptFileList,
                  "salt": encryptSalt,
                  "failure": failureEncryptFileList,
                };
                _completer.complete(params);
              }
            }).catchError((error) {
              _completer.complete({});
            });
          });
        }
      }).catchError((error) {
        _completer.complete({});
      });
    }).catchError((error) {
      _completer.complete({});
    });

    return _completer.future;
  }

  // 加密单文件 publicKey 好友、客服curve25519 公钥
  static Future<Map<String, dynamic>> encryptFile(Map<String, dynamic> params) {
    Completer<Map<String, dynamic>> _completer = Completer();

    String publicKey = params["publicKey"];
    EncryptFileDataModel fileDataModel = params["fileDataModel"];
    String cryptFilePath = params["cryptFilePath"];
    kCryptoKeyConfig = params["config"];
    kAppConfig = params["config"];

    if (fileDataModel.fileData.length == 0 || publicKey.length == 0) {
      _completer.complete({});
      return _completer.future;
    }

    String salt = generateRandomString(10);
    // 用户curve25519 私钥解密服务器salt，再生成共享密钥
    CryptoUtils.serverEncryptionKey().then((encryptionKey) {
      // 使用共享密钥加密随机数salt
      CryptoUtils.encryptText(
        publicKey: kAppConfig.serverCurvePublicKey,
        text: salt,
        encryptionKey: encryptionKey,
      ).then((encryptSalt) {
        // 用户curve25519 私钥 好友、客服curve25519 公钥，生成共享密钥
        CryptoUtils.encryptionKey(
          publicKey,
          salt: salt,
        ).then((password) {
          CryptoUtils.encryptFile(
            fileData: fileDataModel.fileData,
            password: password,
            fileName: fileDataModel.fileName ?? "",
            cryptFilePath: cryptFilePath,
          ).then((encryptFileData) {
            Map<String, dynamic> params = {
              "file": EncryptFileDataModel(
                fileType: fileDataModel.fileType,
                fileData: encryptFileData,
                fileName: fileDataModel.fileName,
                fileId: fileDataModel.fileId,
              ),
              "salt": encryptSalt,
            };

            _completer.complete(params);
          }).catchError((error) {
            _completer.complete({});
          });
        }).catchError((error) {
          _completer.complete({});
        });
      }).catchError((error) {
        _completer.complete({});
      });
    }).catchError((error) {
      _completer.complete({});
    });

    return _completer.future;
  }

  // 加密文本信息 publicKey 好友、客服curve25519 公钥
  static Future<Map<String, dynamic>> encryptMessage({
    required String publicKey,
    required String content,
  }) {
    Completer<Map<String, dynamic>> _completer = Completer();

    String salt = generateRandomString(10);
    // 用户curve25519 私钥解密服务器salt，再生成共享密钥
    CryptoUtils.serverEncryptionKey().then((encryptionKey) {
      // 使用共享密钥加密随机数salt
      CryptoUtils.encryptText(
        publicKey: kAppConfig.serverCurvePublicKey,
        text: salt,
        encryptionKey: encryptionKey,
      ).then((encryptSalt) {
        CryptoUtils.encryptText(
          publicKey: publicKey,
          text: content,
          salt: salt,
        ).then((encryptContent) {
          Map<String, dynamic> params = {
            "content": encryptContent,
            "salt": encryptSalt,
          };

          _completer.complete(params);
        }).catchError((error) {
          _completer.complete({});
        });
      }).catchError((error) {
        _completer.complete({});
      });
    }).catchError((error) {
      _completer.complete({});
    });

    return _completer.future;
  }

  @override
  void onClose() {
    super.onClose();
  }
}
