import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_message_controller.dart';
import 'package:interests_protection_app/models/tickets_detail_model.dart';
import 'package:interests_protection_app/networking/file_download_client.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/storage_utils.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';

class TicketsDataController extends GetxController {
  List<TicketsAccessoryModel> accessoryStatusList = [];
  String _fileCacheDirectoryPath = "";

  // 解密文件
  void _decryptFile(TicketsAccessoryModel accessoryModel) async {
    var _localFilePath = _fileCacheDirectoryPath + "/${accessoryModel.file}";
    String _binFilePath = _localFilePath + ".bin";

    // 解密文件
    String _salt = accessoryModel.salt;
    // 服务器公钥加salt，头尾填充，生成共享密钥
    String sharedKey = kAppConfig.serverCurvePublicKey;
    // 关键数
    String keyValue = _salt.split("").firstWhere((element) {
      return int.tryParse(element) != null;
    }, orElse: () {
      return "";
    });

    String _password = "";
    if (keyValue.length > 0) {
      int baseKeyLength = int.tryParse(keyValue)!;

      // 基础密钥
      String baseKey = _salt.substring(0, baseKeyLength);
      String baseKeyHex = bytesToHex(utf8.encode(baseKey));
      if (baseKeyLength % 2 == 0) {
        // 偶数 从头部填充
        _password =
            sharedKey.substring(0, sharedKey.length - baseKeyHex.length) +
                baseKeyHex;
      } else {
        // 奇数 从尾部填充
        _password = baseKeyHex +
            sharedKey.substring(baseKeyHex.length, sharedKey.length);
      }
    } else {
      _password = sharedKey;
    }

    Map<String, dynamic> _decryptParams = {
      "filePath": _binFilePath,
      "password": _password,
      "localFilePath": _localFilePath,
    };

    compute(AppMessageController.ticketsDecryptFile, _decryptParams)
        .then((value) {
      debugPrint("处理完成");
      TicketsAccessoryModel? _existModel = accessoryStatusList
          .firstWhereOrNull((element) => element.file == accessoryModel.file);
      if (_existModel != null) {
        // 处理中
        _existModel.status = value == true ? 2 : 0;
        this.update(["${accessoryModel.file}"]);
        Future.delayed(Duration(milliseconds: 200), () {
          if (value) {
            accessoryStatusList.remove(_existModel);
          }
        });
      }
    });
  }

  // 下载文件
  void fileDownload(TicketsAccessoryModel accessoryModel) {
    TicketsAccessoryModel? _existModel = accessoryStatusList
        .firstWhereOrNull((element) => element.file == accessoryModel.file);
    if (_existModel != null) {
      // 处理中
    } else {
      accessoryModel.status = 1;
      this.accessoryStatusList.add(accessoryModel);
      this.update(["${accessoryModel.file}"]);
    }

    void _checkFileStatus() {
      var _localFilePath = _fileCacheDirectoryPath + "/${accessoryModel.file}";
      String saveBinPath = _localFilePath + ".bin";
      String requestPath =
          kAppConfig.apiUrl + "/tickets/file/" + accessoryModel.file;

      if (File(saveBinPath).existsSync()) {
        QueueUtil.get("kTicketsDecrypt_${accessoryModel.file}")?.addTask(() {
          return _decryptFile(accessoryModel);
        });
      } else {
        FileDownloadClient.fileDownload(
          requestPath: requestPath,
          saveBinPath: saveBinPath,
          headers: kAppConfig.apiHeader,
        ).then((value) {
          QueueUtil.get("kTicketsDecrypt_${accessoryModel.file}")?.addTask(() {
            return _decryptFile(accessoryModel);
          });
        }).catchError((error) {
          TicketsAccessoryModel? _existModel =
              accessoryStatusList.firstWhereOrNull(
                  (element) => element.file == accessoryModel.file);
          if (_existModel != null) {
            // 处理中
            _existModel.status = 0;
            this.update(["${accessoryModel.file}"]);
          }
        });
      }
    }

    QueueUtil.get("kTicketsDownload_${accessoryModel.file}")?.addTask(() {
      return _checkFileStatus();
    });
  }

  void checkStatus(TicketsAccessoryModel accessoryModel, String recordId) {
    StorageUtils.getUserTicketsPath().then((value) {
      _fileCacheDirectoryPath = value + "/$recordId";

      TicketsAccessoryModel? _existModel = accessoryStatusList
          .firstWhereOrNull((element) => element.file == accessoryModel.file);
      if (_existModel != null) {
        // 处理中
        accessoryModel.status = 1;
        this.update(["${accessoryModel.file}"]);
      } else {
        var _localFilePath =
            _fileCacheDirectoryPath + "/${accessoryModel.file}";
        if (File(_localFilePath).existsSync()) {
          // 已下载并解密
          accessoryModel.status = 2;
          this.update(["${accessoryModel.file}"]);
        }
      }
    });
  }
}
