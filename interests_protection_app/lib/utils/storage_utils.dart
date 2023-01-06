import 'dart:async';
import 'dart:io';

import 'package:common_utils/common_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:interests_protection_app/controllers/app_home_controller.dart';

import 'package:interests_protection_app/models/chat_record_model.dart';
import 'package:interests_protection_app/utils/crypto_utils.dart';
import 'package:interests_protection_app/utils/queue_util.dart';
import 'package:interests_protection_app/utils/utils_tool.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

// 聊天记录表
final String kAppChatRecordTableName = "ipp_chatrecord_tb";
// 好友表
final String kAppFriendTableName = "ipp_friend_tb";
// 系统消息表
final String kAppMessageTableName = "ipp_message_tb";
// 工单表
final String kAppTicketsTableName = "ipp_tickets_tb";
// 登录状态表
final String kAppVerificationTableName = "ipp_verification_tb";
// 用户信息表
final String kAppAccountTableName = "ipp_account_tb";
// 系统标签表
final String kAppTagboardTableName = "ipp_tagboard_tb";
// 聊天会话表
final String kAppConversationTableName = "ipp_conversation_tb";

class StorageUtils {
  static Database? _appDB;
  static Database? _accountDB;
  static String _loginUserId = "";
  static int _appDBVersion = 1;
  static int _accountDBVersion = 1;

  static Future<SharedPreferences> sharedPreferences =
      SharedPreferences.getInstance();

  // 客服名称
  static readAssistantNickName() {
    sharedPreferences.then((value) async {
      String assistantNickName = value.getString("kAppAssistantNickName") ?? "";
      if (assistantNickName.length > 0) {
        kAppConfig.assistantNickName = assistantNickName;
      }
    });
  }

  static updateAssistantNickName() {
    sharedPreferences.then((value) async {
      await value.setString(
          "kAppAssistantNickName", kAppConfig.assistantNickName);
    });
  }

  // PIN码
  static getPincode(void Function(String pincode) feedback) {
    sharedPreferences.then((value) async {
      String pincode = value.getString("kAppPinCode") ?? "";
      feedback(pincode);
    });
  }

  static setPincode(String pincode) {
    sharedPreferences.then((value) async {
      await value.setString("kAppPinCode", pincode);
      await value.setInt("kAppPinCodeErrorCount", 0);
      await value.setString("kAppPinCodeErrorDate", "");
    });
  }

  static getPincodeError(void Function(int count, String errorDate) feedback) {
    sharedPreferences.then((value) async {
      feedback(
        value.getInt("kAppPinCodeErrorCount") ?? 0,
        value.getString("kAppPinCodeErrorDate") ?? "",
      );
    });
  }

  static setPincodeError(int count, void Function() feedback) {
    sharedPreferences.then((value) async {
      await value.setInt("kAppPinCodeErrorCount", count);
      if (count >= 5) {
        int _totalMinutes = 1;
        if (count > 5) {
          _totalMinutes = 5 << (count - 5);
        }

        DateTime _outDate =
            DateTime.now().add(Duration(minutes: _totalMinutes));
        await value.setString(
          "kAppPinCodeErrorDate",
          DateUtil.formatDate(_outDate, format: "yyyy-MM-dd HH:mm:ss"),
        );
      } else {
        await value.setString("kAppPinCodeErrorDate", "");
      }

      feedback();
    });
  }

  //  清空用户工单、聊天文件夹
  static void emptyAccountDirectory() async {
    getTemporaryDirectory().then((directory) async {
      // 清空工单缓存文件夹
      var _ticketsDirectory =
          Directory(directory.path + "/ticketFiles" + "/$_loginUserId");
      if (_ticketsDirectory.existsSync()) {
        try {
          debugPrint("清空工单缓存文件夹");
          _ticketsDirectory.deleteSync(recursive: true);
        } catch (e) {
          debugPrint("清空工单缓存文件夹Err:$e");
        }
      }

      var _ticketsCryptDirectory =
          Directory(directory.path + "/ticketCryptFiles" + "/$_loginUserId");
      if (_ticketsCryptDirectory.existsSync()) {
        try {
          debugPrint("清空工单加密缓存文件夹");
          _ticketsCryptDirectory.deleteSync(recursive: true);
        } catch (e) {
          debugPrint("清空工单加密缓存文件夹Err:$e");
        }
      }

      // 清空用户聊天缓存文件夹
      var userChatPath = await _getUserChatPath();
      var userChatDirectory = Directory(userChatPath);
      if (userChatDirectory.existsSync()) {
        try {
          debugPrint("清空用户聊天缓存文件夹");
          userChatDirectory.deleteSync(recursive: true);
        } catch (e) {
          debugPrint("清空用户聊天缓存文件夹Err:$e");
        }
      }
    });
  }

  // 用户工单文件夹存储位置
  static Future<String> getUserTicketsPath({bool isCrypt = false}) async {
    Completer<String> _completer = Completer();

    getTemporaryDirectory().then((directory) {
      var _ticketsDirectory = Directory(directory.path +
          (isCrypt == true ? "/ticketCryptFiles" : "/ticketFiles"));
      if (_ticketsDirectory.existsSync() == false) {
        _ticketsDirectory.createSync();
      }

      var userTicketsDirectory =
          Directory(_ticketsDirectory.path + "/$_loginUserId");
      if (userTicketsDirectory.existsSync() == false) {
        userTicketsDirectory.createSync();
      }

      _completer.complete(userTicketsDirectory.path);
    });

    return _completer.future;
  }

  // 聊天用户文件夹存储位置
  static Future<String> _getUserChatPath() async {
    Completer<String> _completer = Completer();

    getTemporaryDirectory().then((directory) {
      var _chatDirectory = Directory(directory.path + "/chat");
      if (_chatDirectory.existsSync() == false) {
        _chatDirectory.createSync();
      }

      var userChatDirectory = Directory(_chatDirectory.path + "/$_loginUserId");
      if (userChatDirectory.existsSync() == false) {
        userChatDirectory.createSync();
      }

      _completer.complete(userChatDirectory.path);
    });

    return _completer.future;
  }

  // 聊天对象专属文件夹存储位置
  static Future<String> getChatObjectPath(String object) async {
    Completer<String> _completer = Completer();

    var userChatPath = await _getUserChatPath();
    var objectChatDirectory = Directory(userChatPath + "/$object");
    if (objectChatDirectory.existsSync() == false) {
      objectChatDirectory.createSync();
    }

    var uploadDirectory = Directory(objectChatDirectory.path + "/upload");
    if (uploadDirectory.existsSync() == false) {
      uploadDirectory.createSync();
    }

    var downloadDirectory = Directory(objectChatDirectory.path + "/download");
    if (downloadDirectory.existsSync() == false) {
      downloadDirectory.createSync();
    }

    _completer.complete(objectChatDirectory.path);

    return _completer.future;
  }

  // 构建版本检测
  static buildVersionCheck(void Function()? finish) {
    sharedPreferences.then((value) async {
      if (value.getString("kAppAccountDatabaseVersion") !=
          "${kAppConfig.appAccountDatabaseVersion}") {
        _accountDBVersion = kAppConfig.appAccountDatabaseVersion;
        await value.setString("kAppAccountDatabaseVersion",
            "${kAppConfig.appAccountDatabaseVersion}");
      } else {
        _accountDBVersion =
            int.parse((value.getString("kAppAccountDatabaseVersion") ?? "0"));
      }

      if (value.getString("kAppAuthDatabaseVersion") !=
          "${kAppConfig.appAuthDatabaseVersion}") {
        _appDBVersion = kAppConfig.appAuthDatabaseVersion;
        await value.setString(
            "kAppAuthDatabaseVersion", "${kAppConfig.appAuthDatabaseVersion}");
      } else {
        _appDBVersion =
            int.parse((value.getString("kAppAuthDatabaseVersion") ?? "0"));
      }

      if (finish != null) {
        finish();
      }
    });
  }

  /// 登录状态
  static Future<void> appAuthStatus(
      {required void Function(Map auth) finish}) async {
    if (_appDB == null) {
      await _initAppDataBase();
    }

    await _appDB!.query(kAppVerificationTableName).then((value) {
      if (value.length > 0) {
        finish(value.first);
      } else {
        finish({});
      }
    }).catchError((error) {
      finish({});
    });
  }

  static Future<void> setAuthStatus({
    required String token,
    required String curve25519,
    required String salt,
    required String userId,
  }) async {
    if (_appDB == null) {
      await _initAppDataBase();
    }

    List<Map<String, Object?>> _list = await _appDB!.query(
      kAppVerificationTableName,
      where: "id == 1",
      limit: 1,
    );
    if (_list.length > 0) {
      await _appDB!.update(
        kAppVerificationTableName,
        {
          "token": token,
          "curve25519": curve25519,
          "salt": salt,
          "userId": userId,
        },
        where: "id == 1",
      );
    } else {
      await _appDB!.insert(
        kAppVerificationTableName,
        {
          "token": token,
          "curve25519": curve25519,
          "salt": salt,
          "userId": userId,
        },
      );
    }
  }

  // 登录状态清空
  static Future<void> cleanAuthStatus() async {
    try {
      await _appDB!.execute("DELETE FROM '$kAppVerificationTableName'");
      await _appDB!.execute(
          "DELETE FROM sqlite_sequence WHERE name = '$kAppVerificationTableName'");
    } catch (e) {}

    sharedPreferences.then((value) async {
      await value.setString("kAppPinCode", "");
    });
  }

  /// 初始化app数据库
  static Future<void> _initAppDataBase() async {
    if (_appDB == null) {
      _appDB = await _connection(
        localPathName: CryptoUtils.md5("ipp_base_db"),
        version: _appDBVersion,
        onCreate: (db, version) async {
          // 1 token 2 curve25519 3 服务器 salt
          await createTable(
            db,
            "ipp_verification_tb",
            "token TEXT, curve25519 TEXT, salt TEXT, userId TEXT",
          );
        },
        onUpgrade: (db, oldVersion, newVersion) {},
      );
    }
  }

  // 当前登录用户数据库
  static Future<Database?> account({
    required String userId,
    bool isolate = false,
  }) async {
    Completer<Database?> _completer = Completer();

    if (_accountDB != null) {
      _accountDB?.close();
      _accountDB = null;
    }

    debugPrint("数据库版本:$_accountDBVersion");
    _connection(
      localPathName: CryptoUtils.md5("ipp_${userId}_db"),
      version: _accountDBVersion,
      passwdKey: userId,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion != newVersion && newVersion == 3 && isolate == false) {
          await createTable(
            db,
            kAppConversationTableName,
            "fromId TEXT, lastTime TEXT, lastContent TEXT, lastContentId TEXT, unread INTEGER",
          );
        }
      },
      onCreate: (db, version) async {
        if (isolate == false) {
          // 创建好友表
          await createTable(
            db,
            kAppFriendTableName,
            "risk INTEGER, timeoutDate TEXT, updateState INTEGER DEFAULT 1, userId TEXT, key TEXT, remark TEXT, mobile TEXT, nickname TEXT, avatar TEXT, tags BLOB, timeout INTEGER",
          );

          // 创建 系统消息表
          await createTable(
            db,
            kAppMessageTableName,
            "isReaded INTEGER, eventName TEXT, eventId TEXT, fromId TEXT, action TEXT, content TEXT, time TEXT",
          );

          // 创建 聊天记录表 from 对方用户id
          await createTable(
            db,
            kAppChatRecordTableName,
            "encryptSources TEXT, decrypt INTEGER, sendState INTEGER, isReaded INTEGER, fromId TEXT, isMine INTEGER, filename TEXT, salt TEXT, eventName TEXT, eventId TEXT, action TEXT, content TEXT, time TEXT",
          );

          // 创建用户信息表
          await createTable(
            db,
            kAppAccountTableName,
            "risk INTEGER, amount INTEGER, location TEXT, avatar TEXT, country TEXT, emergencyPhone TEXT, friendCode TEXT, mobile TEXT, nickname TEXT, friends BLOB, sex TEXT, userId TEXT, level INTEGER, rescue INTEGER, real INTEGER",
          );

          // 创建系统标签表
          await createTable(
            db,
            kAppTagboardTableName,
            "label TEXT",
          );

          // 创建聊天会话表
          await createTable(
            db,
            kAppConversationTableName,
            "fromId TEXT, lastTime TEXT, lastContent TEXT, lastContentId TEXT, unread INTEGER",
          );
        }
      },
    ).then((value) async {
      if (value != null) {
        _accountDB = value;
        if (isolate == false) {
          await executeAddColumn(
              _accountDB!, kAppAccountTableName, "location", "TEXT");

          await executeAddColumn(
              _accountDB!, kAppChatRecordTableName, "encryptSources", "TEXT");

          await executeAddColumn(_accountDB!, kAppFriendTableName,
              "updateState", "INTEGER DEFAULT 1");

          // 阅后即焚标记
          await executeAddColumn(
              _accountDB!, kAppFriendTableName, "timeout", "INTEGER DEFAULT 0");

          await executeAddColumn(
              _accountDB!, kAppFriendTableName, "timeoutDate", "TEXT");

          await executeAddColumn(
              _accountDB!, kAppAccountTableName, "xpin", "TEXT");

          await executeAddColumn(
              _accountDB!, kAppAccountTableName, "amount", "INTEGER DEFAULT 0");
          await executeAddColumn(
              _accountDB!, kAppAccountTableName, "risk", "INTEGER DEFAULT 0");

          await executeAddColumn(
              _accountDB!, kAppFriendTableName, "risk", "INTEGER DEFAULT 0");

          // 创建用户聊天缓存文件夹
          _loginUserId = userId;
          _getUserChatPath();

          _completer.complete(_accountDB);

          // 删除重复用户记录
          void _cleanRepeatAccount() {
            _accountDB!.query(
              kAppAccountTableName,
              where: "userId = '$userId'",
              columns: ["id"],
            ).then((value) {
              if (value.length > 1) {
                String _where = "";
                value.forEach((element) {
                  if (_where.length == 0) {
                    _where = "id = '${element['id']}'";
                  } else {
                    _where += "OR id = '${element['id']}'";
                  }
                });
                _accountDB!
                    .delete(
                  kAppAccountTableName,
                  where: _where,
                )
                    .then((value) {
                  _accountDB!.execute("VACUUM");
                });
              }
            });
          }

          QueueUtil.get("kAppCleanRepeatAccount")?.addTask(() {
            return _cleanRepeatAccount();
          });
        }
      } else {
        _completer.complete(null);
      }
    });

    return _completer.future;
  }

  // 清空当前登录用户聊天记录
  static Future<void> emptyCurrnetChatRecord() async {
    if (_accountDB != null) {
      try {
        await _accountDB!.execute("DELETE FROM '$kAppChatRecordTableName'");
        await _accountDB!.execute(
            "DELETE FROM sqlite_sequence WHERE name = '$kAppChatRecordTableName'");

        debugPrint("清空聊天记录");

        await _accountDB!.execute("DELETE FROM '$kAppConversationTableName'");
        await _accountDB!.execute(
            "DELETE FROM sqlite_sequence WHERE name = '$kAppConversationTableName'");

        debugPrint("清空聊天会话记录");

        _accountDB!.execute("VACUUM");
      } catch (e) {}
    }

    emptyAccountDirectory();

    try {
      Get.find<AppHomeController>().messageHandler.add(
        {StreamActionType.system: SystemStreamActionType.emptyMessage},
      );
    } catch (e) {}
  }

  // 清空指定好友用户聊天记录
  static Future<String> cleanFriendChatRecord(String userId,
      {bool skipNotifi = false}) async {
    Completer<String> _completer = Completer();
    if (_accountDB != null) {
      _accountDB!
          .delete(
        kAppChatRecordTableName,
        where: "eventName = 'chat' AND fromId = '$userId'",
      )
          .then((value) {
        _accountDB!.execute("VACUUM");

        getChatObjectPath(userId).then((value) {
          var uploadDirectory = Directory(value + "/upload");
          if (uploadDirectory.existsSync() == true) {
            uploadDirectory.deleteSync(recursive: true);
            uploadDirectory.createSync();
          }

          var downloadDirectory = Directory(value + "/download");
          if (downloadDirectory.existsSync() == true) {
            downloadDirectory.deleteSync(recursive: true);
            downloadDirectory.createSync();
          }
        });

        if (skipNotifi == false) {
          Get.find<AppHomeController>()
              .messageHandler
              .add({StreamActionType.cleanMessage: userId});
        }

        _completer.complete(userId);
      }).catchError((error) {
        _completer.complete("");
      });
    } else {
      _completer.complete("");
    }

    return _completer.future;
  }

  // 删除消息
  static Future<String> deleteMessage(
    bool customer,
    String fromId,
    String eventId,
  ) async {
    Completer<String> _completer = Completer();

    if (_accountDB != null) {
      String _where = customer
          ? "eventName = 'customer' AND eventId = '$eventId'"
          : "eventName = 'chat' AND fromId = '$fromId' AND eventId = '$eventId'";

      var _list = await _accountDB!.query(
        kAppChatRecordTableName,
        where: _where,
        columns: ["isMine", "content", "action"],
      );

      if (_list.length > 0) {
        String _chatRootPath =
            await getChatObjectPath(customer ? "customer" : fromId);
        ChatRecordModel _model = ChatRecordModel.fromJson(_list.first);

        _accountDB!
            .delete(
          kAppChatRecordTableName,
          where: _where,
        )
            .then((value) {
          if (value > 0) {
            if (_model.action == "file") {
              String _filePath = "";
              if (_model.isMine == 0) {
                // 已下载缓存文件
                _filePath = _chatRootPath + "/download/${_model.content}";
              } else {
                // 本人发送缓存文件
                _filePath = _chatRootPath + "/upload/${_model.content}";
              }

              if (_filePath.length > 0) {
                if (File(_filePath).existsSync()) {
                  File(_filePath).deleteSync();
                }
              }
            }

            _completer.complete(eventId);
          } else {
            _completer.complete("");
          }
        }).catchError((error) {
          _completer.complete("");
        });
      } else {
        _completer.complete("");
      }
    } else {
      _completer.complete("");
    }

    return _completer.future;
  }

  // 更新表
  static Future<void> executeAddColumn(
    Database db,
    String table,
    String column,
    String type,
  ) async {
    String _sql =
        "SELECT * from sqlite_master where name = '$table' and sql like '%$column%'";
    List _list = await db.rawQuery(_sql);
    if (_list.length == 0) {
      debugPrint("alter table '$table' add column $column $type");
      await db.rawQuery("alter table '$table' add column $column $type");
    }
  }

  // 创建表
  static Future<void> createTable(
    Database db,
    String tableName,
    String execute, {
    String primaryKey = "id",
    String primaryKeyType = "INTEGER",
  }) async {
    /*
    await db.execute("CREATE TABLE category_in (id INTEGER PRIMARY KEY, icon TEXT, name TEXT, color TEXT, sort INTEGER)");
    await db.execute("CREATE TABLE category_out (id INTEGER PRIMARY KEY, icon TEXT, name TEXT, color TEXT, sort INTEGER)");
    */

    List<Map> result = await db.rawQuery(
        "SELECT count(*) FROM sqlite_master WHERE type='table' AND name = '$tableName'");
    if (result.length > 0 && result[0]["count(*)"] > 0) {
      // 表已存在
      debugPrint("表$tableName已存在");
    } else {
      if (execute.isEmpty) {
        debugPrint("表字段信息不能为空！用于创建表（IF NOT EXISTS）");
      } else {
        db
            .execute(
                "CREATE TABLE IF NOT EXISTS $tableName ($primaryKey $primaryKeyType PRIMARY KEY AUTOINCREMENT, $execute)")
            .then((value) {
          debugPrint("创建表:$tableName");
        });
      }
    }
  }

  // 打开数据库
  static Future<Database?> _connection({
    required String localPathName,
    required int version,
    required FutureOr<void> Function(Database db, int version)? onCreate,
    FutureOr<void> Function(Database db, int oldVersion, int newVersion)?
        onUpgrade,
    String? passwdKey,
  }) async {
    Completer<Database?> completer = Completer();

    if (localPathName.trim().length == 0) {
      utilsToast(msg: "数据库文件名不能为空!");
      completer.complete(null);
    } else {
      var databasesPath = await getDatabasesPath();
      String path = databasesPath + "/$localPathName";

      String _password = CryptoUtils.md5(passwdKey ?? localPathName);
      debugPrint("数据库文件:$path 密码:$_password");

      await openDatabase(
        path,
        password: _password, // 根据用户id，生成密钥
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      ).then((database) {
        if (database.isOpen) {
          completer.complete(database);
        } else {
          completer.complete(null);
        }
      }).catchError((error) {
        completer.complete(null);
      });
    }
    return completer.future;
  }

  //  退出登录
  static logout({bool remove = false, bool isolate = false}) {
    if (_accountDB != null && isolate == false) {
      try {
        _accountDB?.close();
      } catch (e) {}

      if (remove) {
        File(_accountDB!.path).deleteSync();
      }
      _accountDB = null;
    }

    _loginUserId = "";
  }
}
